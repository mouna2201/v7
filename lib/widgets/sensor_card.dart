import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class SensorCard extends StatelessWidget {
  final SensorData sensorData;

  const SensorCard({super.key, required this.sensorData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.agriculture, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Capteur: ${sensorData.deviceId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  _formatTime(
                      sensorData.timestamp ?? sensorData.timestampMesure),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (sensorData.temperature != null)
              _buildDataRow('🌡️ Température', '${sensorData.temperature}°C'),
            if (sensorData.humidity != null)
              _buildDataRow('💧 Humidité Air', '${sensorData.humidity}%'),
            if (sensorData.soilMoisture != null) {
              final String soilStr =
                  sensorData.soilMoisture!.toStringAsFixed(1).replaceAll('.', ',');
              _buildDataRow('🌱 Humidité Sol', '$soilStr%');
            }
            if (sensorData.battery != null)
              _buildDataRow('🔋 Batterie', '${sensorData.battery}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
