import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/mqtt_service.dart';

final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService();

  ref.onDispose(() {
    service.disconnect();
  });

  return service;
});

final mqttConnectionStateProvider = StreamProvider<MqttConnectionStatus>((ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.connectionStream;
});

final mqttAutoConnectProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(mqttServiceProvider);
  return await service.connect();
});
