class SensorData {
  final double temperature;
  final double humidity;
  final int lightLevel;
  final double soilMoisture;
  final List<double> soilMoistures;
  final String mode; // auto or manual
  final String? activeProfile; // null if manual
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.soilMoistures,
    required this.lightLevel,
    required this.mode,
    this.activeProfile,
    required this.timestamp,
  });

  // copy with modified values (immutable)
  SensorData copyWith({
    double? temperature,
    double? humidity,
    int? lightLevel,
    double? soilMoisture,
    List<double>? soilMoistures,
    String? mode,
    String? activeProfile,
    DateTime? timestamp,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      lightLevel: lightLevel ?? this.lightLevel,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      soilMoistures: soilMoistures ?? this.soilMoistures,
      mode: mode ?? this.mode,
      activeProfile: activeProfile ?? this.activeProfile,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory SensorData.empty() {
    return SensorData(
      temperature: 0.0,
      humidity: 0.0,
      soilMoisture: 0.0,
      soilMoistures: const [],
      lightLevel: 0,
      mode: 'CONNECTING',
      activeProfile: null,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'SensorData(temp: $temperature, humidity: $humidity, soilMoisture: $soilMoisture, lightLevel: $lightLevel, mode: $mode, activeProfile: $activeProfile, timestamp: $timestamp)';
  }
}
