import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/remote/mqtt_service.dart';
import '../../providers/sensor_data_provider.dart';
import '../../providers/mqtt_provider.dart';
import 'widgets/sensor_card.dart';
import 'widgets/connection_status_chip.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(mqttConnectionStateProvider);
    final sensorDataAsync = ref.watch(sensorDataStreamProvider);

    ref.listen(mqttAutoConnectProvider, (previous, next) {
      next.whenData((connected) {
        if (!connected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to MQTT broker'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    });
    //TODO: add botton to reconect to de grenhouse manually,(Not only swipe down to refresh / or maybe deleate this)
    //TODO: if the greenhouse not respond (mqtt fails) we needt to show a push notification that say try to reconet (all this when _performHealthCheck in mqtt-service fails and functionthe handleconnection failure is activatede)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Greenhouse Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: connectionState.when(
              data: (state) => ConnectionStatusChip(status: state),
              loading: () => const ConnectionStatusChip(
                status: MqttConnectionStatus.connecting,
              ),
              error: (_, __) => const ConnectionStatusChip(
                status: MqttConnectionStatus.failed,
              ),
            ),
          ),
        ],
      ),
      body: sensorDataAsync.when(
        data: (sensorData) {
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(mqttServiceProvider).manualReconnect();
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                SensorCard(
                  title: 'Temperature',
                  value: sensorData.temperature.toStringAsFixed(1),
                  unit: '°C',
                  icon: Icons.thermostat,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 12),
                SensorCard(
                  title: 'Air Humidity',
                  value: sensorData.humidity.toStringAsFixed(1),
                  unit: '%',
                  icon: Icons.water_drop,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 12),
                SensorCard(
                  title: 'Light Intensity',
                  value: sensorData.lightLevel.toString(),
                  unit: 'lux',
                  icon: Icons.wb_sunny,
                  color: Colors.yellowAccent,
                ),
                const SizedBox(height: 12),
                SensorCard(
                  title: 'Soil Moisture',
                  value: sensorData.soilMoisture.toStringAsFixed(1),
                  unit: '%',
                  icon: Icons.grass,
                  color: Colors.brown,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Mode: ${sensorData.mode}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (sensorData.activeProfile != null)
                          Text(
                            'Profile: ${sensorData.activeProfile}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.greenAccent),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to greenhouse...'),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(mqttServiceProvider).manualReconnect();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
