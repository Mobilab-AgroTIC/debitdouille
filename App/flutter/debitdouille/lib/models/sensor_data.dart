import 'package:flutter/foundation.dart';

class FlowPair {
  final double left;
  final double right;

  FlowPair({required this.left, required this.right});
}

class SensorData {
  final double pressure;
  final List<FlowPair> flowPairs;
  final double speed;

  SensorData({
    required this.pressure,
    required this.flowPairs,
    required this.speed,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    // TODO : parser JSON reçu via BLE
    double p = (json['pressure'] as num).toDouble();
    List<dynamic> pairs = json['flowPairs'] as List<dynamic>;
    List<FlowPair> flowList = pairs.map((item) {
      return FlowPair(
        left: (item['left'] as num).toDouble(),
        right: (item['right'] as num).toDouble(),
      );
    }).toList();
    double s = (json['speed'] as num).toDouble();
    return SensorData(pressure: p, flowPairs: flowList, speed: s);
  }

  @override
  String toString() {
    return 'SensorData(pressure: $pressure, flowPairs: $flowPairs, speed: $speed)';
  }
}
