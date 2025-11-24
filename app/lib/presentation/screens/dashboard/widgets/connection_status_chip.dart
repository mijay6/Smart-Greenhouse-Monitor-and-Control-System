import 'package:flutter/material.dart';
import '../../../../data/datasources/remote/mqtt_service.dart';

class ConnectionStatusChip extends StatelessWidget {
  final MqttConnectionStatus status;

  const ConnectionStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (status) {
      case MqttConnectionStatus.connected:
        icon = Icons.cloud_done;
        color = Colors.greenAccent;
        label = 'Connected';
        break;
      case MqttConnectionStatus.connecting:
        icon = Icons.cloud_sync;
        color = Colors.orangeAccent;
        label = 'Connecting...';
        break;
      case MqttConnectionStatus.reconnecting:
        icon = Icons.refresh;
        color = Colors.yellowAccent;
        label = 'Reconnecting...';
        break;
      case MqttConnectionStatus.failed:
        icon = Icons.cloud_off;
        color = Colors.redAccent;
        label = 'Failed';
        break;
      case MqttConnectionStatus.disconnected:
        icon = Icons.cloud_off;
        color = Colors.grey;
        label = 'Disconnected';
        break;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.black26,
    );
  }
}
