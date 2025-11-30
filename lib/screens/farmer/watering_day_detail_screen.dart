import 'package:flutter/material.dart';

class WateringDayDetailScreen extends StatelessWidget {
  final String dayKey;
  final String crop;
  final String temperatureLabel;
  final int rainPercent;
  final String mistralPlan;

  const WateringDayDetailScreen({
    super.key,
    required this.dayKey,
    required this.crop,
    required this.temperatureLabel,
    required this.rainPercent,
    required this.mistralPlan,
  });

  String _getDayLabel() {
    switch (dayKey) {
      case 'monday':
        return 'Lundi';
      case 'tuesday':
        return 'Mardi';
      case 'wednesday':
        return 'Mercredi';
      case 'thursday':
        return 'Jeudi';
      case 'friday':
        return 'Vendredi';
      case 'saturday':
        return 'Samedi';
      case 'sunday':
        return 'Dimanche';
      default:
        return dayKey;
    }
  }

  double _estimateLitersPerSquareMeter() {
    final lower = crop.toLowerCase();
    if (lower.contains('tomate')) return 8;
    if (lower.contains('fraise')) return 6;
    if (lower.contains('maïs') || lower.contains('mais')) return 7;
    if (lower.contains('blé')) return 5;
    if (lower.contains('olive')) return 10;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    final liters = _estimateLitersPerSquareMeter();

    return Scaffold(
      appBar: AppBar(
        title: Text(_getDayLabel()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_florist, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    crop,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildIconChip(
                      icon: Icons.thermostat,
                      color: Colors.redAccent,
                      value: temperatureLabel,
                    ),
                    _buildIconChip(
                      icon: Icons.water_drop,
                      color: Colors.blueAccent,
                      value: '$rainPercent%',
                    ),
                    _buildIconChip(
                      icon: Icons.local_drink,
                      color: Colors.green,
                      value: '${liters.toStringAsFixed(1)}L',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconChip({
    required IconData icon,
    required Color color,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
