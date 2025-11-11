import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/sensor_data.dart';

class SensorState {
  final List<SensorData> sensors;
  final bool isConnected;

  SensorState({required this.sensors, this.isConnected = false});

  SensorState copyWith({List<SensorData>? sensors, bool? isConnected}) {
    return SensorState(
      sensors: sensors ?? this.sensors,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class SensorNotifier {
  final Ref ref;
  SensorNotifier(this.ref);

  void addSensor(SensorData data) {
    final currentState = ref.read(sensorProvider);
    final updated = List<SensorData>.from(currentState.sensors)
      ..removeWhere((s) => s.deviceId == data.deviceId)
      ..add(data)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    ref.read(sensorProvider.notifier).state = currentState.copyWith(sensors: updated);
  }

  void setConnected(bool connected) {
    final currentState = ref.read(sensorProvider);
    ref.read(sensorProvider.notifier).state = currentState.copyWith(isConnected: connected);
  }

  void clear() {
    ref.read(sensorProvider.notifier).state = SensorState(sensors: []);
  }
}

final sensorProvider = StateProvider<SensorState>((ref) {
  return SensorState(sensors: []);
});

final sensorNotifierProvider = Provider<SensorNotifier>((ref) {
  return SensorNotifier(ref);
});
