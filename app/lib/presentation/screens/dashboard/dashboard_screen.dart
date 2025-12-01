import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/remote/mqtt_service.dart';
import '../../providers/sensor_data_provider.dart';
import '../../providers/mqtt_provider.dart';
import '../../providers/actuator_provider.dart';
import 'widgets/sensor_card.dart';
import 'widgets/connection_status_chip.dart';
import 'widgets/actuator_button.dart';
import 'widgets/led_color_picker_button.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(mqttConnectionStateProvider);
    final sensorDataAsync = ref.watch(sensorDataStreamProvider);
    final actuatorState = ref.watch(actuatorStateProvider);

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

    // Listen for actuator control errors
    ref.listen(
      actuatorStateProvider.notifier.select((notifier) => notifier.errorStream),
      (previous, next) {
        // async listen to the stream
        next.listen((errorMessage) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: const Color.fromRGBO(244, 67, 54, 1),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        });
      },
    );
    //TODO: add botton to reconect to de grenhouse manually,(Not only swipe down to refresh / or maybe deleate this)
    //TODO: if the greenhouse not respond (mqtt fails) we needt to show a push notification that say try to reconet (all this when _performHealthCheck in mqtt-service fails and the function handleconnection failure is activated)
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
                // Telemetry section
                Text(
                  'Sensor Readings',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
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
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                // Manual actuators section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manual Control',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Emergency Stop'),
                            content: const Text(
                              'This will turn OFF all actuators immediately. Continue?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  ref
                                      .read(actuatorStateProvider.notifier)
                                      .emergencyStop();
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Emergency stop activated'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('STOP ALL'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.power_settings_new),
                      color: Colors.red,
                      iconSize: 32,
                      tooltip: 'Emergency Stop',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ActuatorButton(
                      label: 'Pump',
                      isOn: actuatorState.pumpOn,
                      isLoading: actuatorState.pumpSyncing,
                      onIcon: Icons.water_drop,
                      offIcon: Icons.water_drop_outlined,
                      onColor: Colors.blue,
                      onPressed: () {
                        ref.read(actuatorStateProvider.notifier).togglePump();
                      },
                    ),
                    ActuatorButton(
                      label: 'Fan Intake',
                      isOn: actuatorState.fanIntakeOn,
                      isLoading: actuatorState.fanIntakeSyncing,
                      onIcon: Icons.arrow_downward,
                      offIcon: Icons.arrow_downward_outlined,
                      onColor: Colors.cyan,
                      onPressed: () {
                        ref
                            .read(actuatorStateProvider.notifier)
                            .toggleFanIntake();
                      },
                    ),
                    ActuatorButton(
                      label: 'Fan Exhaust',
                      isOn: actuatorState.fanExhaustOn,
                      isLoading: actuatorState.fanExhaustSyncing,
                      onIcon: Icons.arrow_upward,
                      offIcon: Icons.arrow_upward_outlined,
                      onColor: Colors.teal,
                      onPressed: () {
                        ref
                            .read(actuatorStateProvider.notifier)
                            .toggleFanExhaust();
                      },
                    ),
                    ActuatorButton(
                      label: 'Window',
                      isOn: actuatorState.windowOpen,
                      isLoading: actuatorState.windowSyncing,
                      onIcon: Icons.meeting_room,
                      offIcon: Icons.meeting_room_outlined,
                      onColor: Colors.amber,
                      onPressed: () {
                        ref.read(actuatorStateProvider.notifier).toggleWindow();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ActuatorButton(
                            label: 'LED Light',
                            isOn: actuatorState.ledOn,
                            isLoading: actuatorState.ledSyncing,
                            onIcon: Icons.lightbulb,
                            offIcon: Icons.lightbulb_outline,
                            onColor: Colors.purple,
                            onPressed: () {
                              ref
                                  .read(actuatorStateProvider.notifier)
                                  .toggleLed();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        LedColorPickerButton(
                          currentColor: actuatorState.ledColor,
                          isSyncing: actuatorState.ledSyncing,
                          onColorChanged: (color) {
                            ref
                                .read(actuatorStateProvider.notifier)
                                .setLedColor(color);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: sensorData.mode == 'AUTO'
                      ? Colors.green[900]
                      : Colors.orange[900],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              sensorData.mode == 'AUTO'
                                  ? Icons.auto_mode
                                  : Icons.touch_app,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Mode: ${sensorData.mode}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        if (sensorData.activeProfile != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Active Profile: ${sensorData.activeProfile}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                        if (sensorData.mode == 'MANUAL') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Manual mode is active. Automatic adjustments are disabled.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white60,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
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
