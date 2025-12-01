import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sensor_data.dart';
import 'mqtt_provider.dart';

final sensorDataStreamProvider = StreamProvider<SensorData>((ref) {
  final service = ref.watch(mqttServiceProvider);

  return service.dataStream.map((model) => model.toEntity());
});

final lastestSensorDataProvider = Provider<SensorData>((ref) {
  final asyncValue = ref.watch(sensorDataStreamProvider);

  return asyncValue.when(
    data: (data) => data,
    loading: () => SensorData.empty(),
    error: (_, __) => SensorData.empty(),
  );
});

final commandSenderProvider = Provider<void Function(Map<String, dynamic>)>((
  ref,
) {
  final service = ref.watch(mqttServiceProvider);
  return (command) => service.publishCommand(command);
});
