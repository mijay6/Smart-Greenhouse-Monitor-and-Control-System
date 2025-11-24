class AppConstants {
  // Greenhouse ID
  static const String greenhouseId = '1';

  // MQTT Config
  static const String mqttBroker =
      'abf09ccff5484da78e04fb5444f1faf9.s1.eu.hivemq.cloud';
  static const int mqttPort = 8883;
  static const String mqttUsername = 'Mijay';
  static const String mqttPassword = 'sHf728/ns@a8';

  // MQTT Topics
  static const String telemetryTopic = 'greenhouse/$greenhouseId/telemetry';
  static const String commandTopic = 'greenhouse/$greenhouseId/commands';
  static const String statusTopic = 'greenhouse/$greenhouseId/status';

  // Reconnection settings
  static const int maxReconnectAttempts = 10;
  static const List<int> reconnectionDelays = [
    1,
    2,
    5,
    10,
    15,
    30,
    60,
    120,
    300,
    600,
  ];

  // Health monitoring
  static const Duration healthCheckInterval = Duration(seconds: 30);
  static const Duration messageTimeoutDuration = Duration(minutes: 5);

  // Limit to prevent memory overflow if the broker is down
  static const int maxPendingCommands = 50;
}
