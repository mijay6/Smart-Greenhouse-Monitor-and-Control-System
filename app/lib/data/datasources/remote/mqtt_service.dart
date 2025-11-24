import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../../../core/utils/logger.dart';
import '../../../core/constants/app_Constants.dart';
import '../../models/sensor_data_model.dart';

enum MqttConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

// Singleton class to manage MQTT connection
class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() =>
      _instance; // when MqttService() is called from external, return the already created instance
  MqttService._internal();

  MqttServerClient? _client;
  MqttConnectionStatus _connectionState = MqttConnectionStatus.disconnected;

  final StreamController<SensorDataModel> _dataStreamController =
      StreamController<SensorDataModel>.broadcast();

  final StreamController<MqttConnectionStatus> _connectionStreamController =
      StreamController<MqttConnectionStatus>.broadcast();

  // Reconnection Control
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;
  DateTime? _lastMessageReceived;

  // For when connection is lost, buffer commands here
  final List<Map<String, dynamic>> _pendingCommands = [];

  // Public getters
  Stream<SensorDataModel> get dataStream => _dataStreamController.stream;

  Stream<MqttConnectionStatus> get connectionStream =>
      _connectionStreamController.stream;

  MqttConnectionStatus get connectionState => _connectionState;

  bool get isConnected =>
      _connectionState == MqttConnectionStatus.connected &&
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  int get pendingCommandsCount => _pendingCommands.length;

  Future<bool> connect() async {
    if (_connectionState == MqttConnectionStatus.connecting ||
        _connectionState == MqttConnectionStatus.connected) {
      logger.w('Already connected or connecting, skipping...');
      return isConnected;
    }

    _updateConnectionState(MqttConnectionStatus.connecting);
    logger.i('Attempting to connect to MQTT broker...');

    try {
      final clientId =
          'smart_greenhouse_${DateTime.now().millisecondsSinceEpoch}';

      _client = MqttServerClient(AppConstants.mqttBroker, clientId)
        ..port = AppConstants.mqttPort
        ..secure = true
        ..logging(on: false) // we use our own logger
        ..keepAlivePeriod = 60
        ..autoReconnect = true
        ..onConnected = _onConnected
        ..onDisconnected = _onDisconnected
        ..onAutoReconnect = _onAutoReconnect
        ..onAutoReconnected = _onAutoReconnected
        ..onSubscribed = _onSubscribed
        ..onUnsubscribed = _onUnsubscribed;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .authenticateAs(AppConstants.mqttUsername, AppConstants.mqttPassword)
          .withWillTopic(AppConstants.statusTopic)
          .withWillMessage('offline')
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      logger.i(
        'Connecting to ${AppConstants.mqttBroker}:${AppConstants.mqttPort}',
      );
      await _client!.connect();

      logger.i('MQTT connection established.');
      return true;
    } catch (e) {
      logger.e('MQTT connection error: $e');
      _handleConnectionFailure();
      return false;
    }
  }

  void disconnect() {
    logger.i('Disconnecting MQTT...');
    _reconnectTimer?.cancel();
    _healthCheckTimer?.cancel();
    _client?.disconnect();
    _updateConnectionState(MqttConnectionStatus.disconnected);
  }

  void publishCommand(Map<String, dynamic> command) {
    if (isConnected) {
      try {
        final builder = MqttClientPayloadBuilder();
        final commandString = json.encode(command);
        builder.addString(commandString);

        _client!.publishMessage(
          AppConstants.commandTopic,
          MqttQos.atLeastOnce,
          builder.payload!,
        );

        logger.i('Published command: $commandString');
      } catch (e) {
        logger.e('Error publishing command: $e');
        _queueCommand(command);
      }
    } else {
      logger.w('MQTT not connected, queuing command: $command');
      _queueCommand(command);
    }
  }

  void publishStatus(String status) {
    if (isConnected) {
      try {
        final builder = MqttClientPayloadBuilder();
        builder.addString(status);

        _client!.publishMessage(
          AppConstants.statusTopic,
          MqttQos.atLeastOnce,
          builder.payload!,
        );

        logger.i('Published status: $status');
      } catch (e) {
        logger.e('Error publishing status: $e');
      }
    } else {
      logger.w('MQTT not connected, cannot publish status: $status');
    }
  }

  // For a retry button
  Future<void> manualReconnect() {
    logger.i('Manual reconnection triggered.');
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    disconnect();
    return Future.delayed(const Duration(seconds: 2), connect);
  }

  // To clean resources when close the app
  void dispose() {
    logger.i('Disposing MQTT service');
    disconnect();
    _dataStreamController.close();
    _connectionStreamController.close();
  }

  // Private metods

  void _updateConnectionState(MqttConnectionStatus newState) {
    _connectionState = newState;
    _connectionStreamController.add(newState);
    logger.d('Connection state: $newState');
  }

  void _onConnectionRestored() {
    _client!.subscribe(AppConstants.telemetryTopic, MqttQos.atLeastOnce);
    _processPendingCommands();
    _startHealthMonitoring();
  }

  void _onConnected() {
    logger.i('Connected to MQTT broker');
    _updateConnectionState(MqttConnectionStatus.connected);

    _reconnectAttempts = 0;
    _lastMessageReceived = DateTime.now();
    publishStatus('online');

    _client!.updates!.listen(
      _onMessageReceived,
      onError: (error) => logger.e('Stream error: $error'),
      onDone: () => logger.w('Stream closed'),
    );

    _onConnectionRestored();
  }

  void _onDisconnected() {
    logger.w('Disconnected from MQTT broker');
    _updateConnectionState(MqttConnectionStatus.disconnected);
    _healthCheckTimer?.cancel();
  }

  void _onAutoReconnect() {
    logger.i('Auto-reconnecting to MQTT broker...');
    _updateConnectionState(MqttConnectionStatus.reconnecting);
  }

  void _onAutoReconnected() {
    logger.i('Auto-reconnected to MQTT broker');
    _updateConnectionState(MqttConnectionStatus.connected);

    _onConnectionRestored();
  }

  void _onSubscribed(String topic) {
    logger.i('Subscribed to topic: $topic');
  }

  void _onUnsubscribed(String? topic) {
    logger.w('Unsubscribed from topic: $topic');
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    try {
      final MqttPublishMessage message =
          messages[0].payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(
        message.payload.message,
      );

      final String topic = messages[0].topic;

      _lastMessageReceived = DateTime.now();
      logger.d('Message received: $payload from topic: ${messages[0].topic}>');

      if (topic == AppConstants.telemetryTopic) {
        final jsonData = json.decode(payload) as Map<String, dynamic>;
        final sensorData = SensorDataModel.fromJson(jsonData);
        _dataStreamController.add(sensorData);
      } else if (topic == AppConstants.statusTopic) {
        logger.i('Status update received: $payload');
      } else {
        logger.w(
          'Unknown topic: $topic with payload: $payload',
        ); // for future use
      }
    } catch (e) {
      logger.e('Error processing received message: $e');
    }
  }

  void _handleConnectionFailure() {
    _updateConnectionState(MqttConnectionStatus.failed);

    if (_reconnectAttempts < AppConstants.maxReconnectAttempts) {
      final delayIndex = min(
        _reconnectAttempts,
        AppConstants.reconnectionDelays.length - 1,
      );

      final delaySeconds = AppConstants.reconnectionDelays[delayIndex];
      final delay = Duration(seconds: delaySeconds);

      logger.w(
        'Retry ${_reconnectAttempts + 1}/${AppConstants.maxReconnectAttempts}}'
        'in ${delaySeconds}s',
      );

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () {
        _reconnectAttempts++;
        _updateConnectionState(MqttConnectionStatus.reconnecting);
        connect();
      });
    } else {
      logger.e('Max retry attemtp reached. Manual reconnection needed.');
      _updateConnectionState(MqttConnectionStatus.failed);
    }
  }

  void _queueCommand(Map<String, dynamic> command) {
    _pendingCommands.add(command);
    logger.w('Command queued. Total comands: ${_pendingCommands.length}');

    if (_pendingCommands.length > AppConstants.maxPendingCommands) {
      final removed = _pendingCommands.removeAt(0);
      logger.w('Oldest command removed :${json.encode(removed)}');
    }
  }

  void _processPendingCommands() {
    if (_pendingCommands.isEmpty) return;

    logger.i('Processing ${_pendingCommands.length} pending commands...');

    final commandsToProcess = List<Map<String, dynamic>>.from(_pendingCommands);
    _pendingCommands.clear();

    for (final command in commandsToProcess) {
      publishCommand(command);
    }
  }

  // TODO: in the ESP a ping-pong response to confirm connectivity via the status topic.
  void _startHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      AppConstants.healthCheckInterval,
      (_) => _performHealthCheck(),
    );
  }

  void _performHealthCheck() {
    if (!isConnected) return;

    final now = DateTime.now();
    if (_lastMessageReceived != null) {
      final timeSinceLastMessage = now.difference(_lastMessageReceived!);
      if (timeSinceLastMessage > AppConstants.messageTimeoutDuration * 3) {
        logger.e('Device unresponsive for too long, reconnecting...');
        _handleConnectionFailure();
        return;
      }
      if (timeSinceLastMessage > AppConstants.messageTimeoutDuration) {
        logger.w(
          'No messages for ${timeSinceLastMessage.inMinutes} minutes. Sending Ping...',
        );
        _sendHeartbeat();
      }
    }
  }

  // send ping to broker
  void _sendHeartbeat() {
    publishCommand({
      'command': 'ping',
      'timestamp:': DateTime.now().millisecondsSinceEpoch,
    });
    logger.d('Heartbeat send');
  }
}
