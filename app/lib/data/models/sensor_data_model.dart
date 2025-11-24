import '../../domain/entities/sensor_data.dart';

class SensorDataModel extends SensorData {
  const SensorDataModel({
    required super.temperature,
    required super.humidity,
    required super.soilMoisture,
    required super.soilMoistures,
    required super.lightLevel,
    required super.mode,
    super.activeProfile,
    required super.timestamp,
  });

  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    final List<double> soilMoisturesList = [];

    if (json['soil_moistures'] is List) {
      soilMoisturesList.addAll(
        (json['soil_moistures'] as List).map((e) => (e as num).toDouble()),
      );
    }

    return SensorDataModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      lightLevel: (json['light_level'] as num?)?.toInt() ?? 0,
      soilMoisture: (json['soil_moisture'] as num?)?.toDouble() ?? 0.0,
      soilMoistures: soilMoisturesList,
      mode: json['mode'] as String? ?? 'UNKNOWN',
      activeProfile: json['active_profile'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  // Convert to JSON to send to Firebase
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'light_level': lightLevel,
      'soil_moisture': soilMoisture,
      'soil_moistures': soilMoistures,
      'mode': mode,
      'active_profile': activeProfile,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // convert to domain entity
  SensorData toEntity() {
    return SensorData(
      temperature: temperature,
      humidity: humidity,
      lightLevel: lightLevel,
      soilMoisture: soilMoisture,
      soilMoistures: soilMoistures,
      mode: mode,
      activeProfile: activeProfile,
      timestamp: timestamp,
    );
  }
}
