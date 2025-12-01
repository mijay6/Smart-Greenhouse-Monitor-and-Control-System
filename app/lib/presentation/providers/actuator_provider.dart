import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/actuator_state.dart';
import '../../data/models/actuator_state_model.dart';
import '../../data/datasources/remote/mqtt_service.dart';
import 'mqtt_provider.dart';
import '../../core/utils/logger.dart';

class ActuatorStateNotifier extends StateNotifier<ActuatorState> {
  final MqttService _mqttService;
  final Map<String, Timer> _confirmationTimers = {};
  final Map<String, bool> _pendingStates = {};
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<String> get errorStream => _errorController.stream;

  ActuatorStateNotifier(this._mqttService) : super(ActuatorState.initial()) {
    _mqttService.ackStream.listen(_handleAcknowledgment);
  }

  void _handleAcknowledgment(Map<String, dynamic> ack) {
    try {
      final String? actuator = ack['actuator'] as String?;
      final bool? success = ack['success'] as bool?;

      if (actuator == null) {
        logger.w('Invalid acknowledgment format: $ack');
        return;
      }

      // Check if this actuator is pending confirmation
      if (!_pendingStates.containsKey(actuator)) {
        logger.d('Received ACK for non-pending actuator: $actuator');
        return;
      }

      if (success == true) {
        final expectedState = _pendingStates[actuator];
        logger.i('ESP32 confirmed: $actuator = $expectedState');
        confirmActuatorState(actuator, expectedState!);
      } else {
        logger.e('ESP32 rejected command for: $actuator');
        _revertActuator(actuator);
      }
    } catch (e) {
      logger.e('Error processing acknowledgment: $e');
    }
  }

  void togglePump() {
    final newState = !state.pumpOn;
    logger.i("Toggling pump: $newState");

    // Optimistic UI update
    state = state.copyWith(pumpOn: newState, pumpSyncing: true);
    _pendingStates['pump'] = newState;

    _mqttService.publishCommand(
      ActuatorStateModel.singleActuatorCommand('pump', newState),
    );

    _startConfirmationTimer('pump', newState);
  }

  void toggleFanIntake() {
    final newState = !state.fanIntakeOn;
    logger.i("Toggling fan intake: $newState");

    state = state.copyWith(fanIntakeOn: newState, fanIntakeSyncing: true);
    _pendingStates['fan_intake'] = newState;

    _mqttService.publishCommand(
      ActuatorStateModel.singleActuatorCommand('fan_intake', newState),
    );

    _startConfirmationTimer('fan_intake', newState);
  }

  void toggleFanExhaust() {
    final newState = !state.fanExhaustOn;
    logger.i("Toggling fan exhaust: $newState");

    state = state.copyWith(fanExhaustOn: newState, fanExhaustSyncing: true);
    _pendingStates['fan_exhaust'] = newState;

    _mqttService.publishCommand(
      ActuatorStateModel.singleActuatorCommand('fan_exhaust', newState),
    );

    _startConfirmationTimer('fan_exhaust', newState);
  }

  void toggleWindow() {
    final newState = !state.windowOpen;
    logger.i("Toggling window: $newState");

    state = state.copyWith(windowOpen: newState, windowSyncing: true);
    _pendingStates['window'] = newState;

    _mqttService.publishCommand(
      ActuatorStateModel.singleActuatorCommand('window', newState),
    );

    _startConfirmationTimer('window', newState);
  }

  void toggleLed() {
    final newState = !state.ledOn;
    logger.i("Toggling LED: $newState");

    state = state.copyWith(ledOn: newState, ledSyncing: true);
    _pendingStates['led'] = newState;

    if (newState) {
      _mqttService.publishCommand(
        ActuatorStateModel.ledColorCommand(state.ledColor),
      );
    } else {
      _mqttService.publishCommand(
        ActuatorStateModel.ledColorCommand(LedColor.off()),
      );
    }

    _startConfirmationTimer('led', newState);
  }

  void setLedColor(LedColor color) {
    logger.i('Setting LED color: $color');

    state = state.copyWith(ledColor: color, ledOn: true, ledSyncing: true);
    _pendingStates['led_color'] = true;

    _mqttService.publishCommand(ActuatorStateModel.ledColorCommand(color));

    _startConfirmationTimer('led_color', true);
  }

  void _startConfirmationTimer(String actuator, bool expectedState) {
    // Cancel previous timer if exists
    _confirmationTimers[actuator]?.cancel();

    _confirmationTimers[actuator] = Timer(const Duration(seconds: 3), () {
      if (_pendingStates.containsKey(actuator)) {
        logger.w('Timeout waiting for $actuator confirmation. Reverting...');
        _revertActuator(actuator);
      }
    });
  }

  void confirmActuatorState(String actuator, bool state) {
    logger.d('Received confirmation for $actuator: $state');

    _confirmationTimers[actuator]?.cancel();
    _pendingStates.remove(actuator);

    _clearSyncing(actuator);
  }

  void _revertActuator(String actuator) {
    String actuatorName = actuator.replaceAll('_', ' ').toUpperCase();

    switch (actuator) {
      case 'pump':
        state = state.copyWith(pumpOn: !state.pumpOn, pumpSyncing: false);
        actuatorName = 'Pump';
        break;
      case 'fan_intake':
        state = state.copyWith(
          fanIntakeOn: !state.fanIntakeOn,
          fanIntakeSyncing: false,
        );
        actuatorName = 'Fan Intake';
        break;
      case 'fan_exhaust':
        state = state.copyWith(
          fanExhaustOn: !state.fanExhaustOn,
          fanExhaustSyncing: false,
        );
        actuatorName = 'Fan Exhaust';
        break;
      case 'window':
        state = state.copyWith(
          windowOpen: !state.windowOpen,
          windowSyncing: false,
        );
        actuatorName = 'Window';
        break;
      case 'led':
        state = state.copyWith(ledOn: !state.ledOn, ledSyncing: false);
        actuatorName = 'LED';
        break;
      case 'led_color':
        state = state.copyWith(ledSyncing: false);
        actuatorName = 'LED Color';
        break;
    }
    _pendingStates.remove(actuator);
    logger.e('Reverted $actuator due to timeout or error');

    // Emit error message
    _errorController.add(
      'Failed to control $actuatorName. Please check connection.',
    );
  }

  void _clearSyncing(String actuator) {
    switch (actuator) {
      case 'pump':
        state = state.copyWith(pumpSyncing: false);
        break;
      case 'fan_intake':
        state = state.copyWith(fanIntakeSyncing: false);
        break;
      case 'fan_exhaust':
        state = state.copyWith(fanExhaustSyncing: false);
        break;
      case 'window':
        state = state.copyWith(windowSyncing: false);
        break;
      case 'led':
      case 'led_color':
        state = state.copyWith(ledSyncing: false);
        break;
    }
  }

  void syncActuatorState(ActuatorState newState) {
    logger.i('Sending full actuator state');

    final model = ActuatorStateModel(
      pumpOn: newState.pumpOn,
      fanIntakeOn: newState.fanIntakeOn,
      fanExhaustOn: newState.fanExhaustOn,
      windowOpen: newState.windowOpen,
      ledOn: newState.ledOn,
      ledColor: newState.ledColor,
    );

    _mqttService.publishCommand(model.toJson());
  }

  void emergencyStop() {
    logger.w('Emergency stop - Turning off all actuators');

    // Cancel all pending timers
    _confirmationTimers.forEach((key, timer) => timer.cancel());
    _confirmationTimers.clear();
    _pendingStates.clear();

    state = ActuatorState.initial();
    syncActuatorState(state);
  }

  @override
  void dispose() {
    _confirmationTimers.forEach((key, timer) => timer.cancel());
    _confirmationTimers.clear();
    _errorController.close();
    super.dispose();
  }
}

final actuatorStateProvider =
    StateNotifierProvider<ActuatorStateNotifier, ActuatorState>((ref) {
      final service = ref.watch(mqttServiceProvider);
      return ActuatorStateNotifier(service);
    });
