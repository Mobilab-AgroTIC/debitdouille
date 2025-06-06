import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../models/coefficients.dart';
import '../services/data_parser_service.dart';
import 'bluetooth_provider.dart';

class SensorProvider with ChangeNotifier {
  final DataParserService _parser = DataParserService();
  SensorData? currentData;
  Coefficients? currentCoefficients;
  BluetoothProvider? _bluetoothProvider;
  Timer? _timeoutTimer;
  DateTime? lastReceivedTime;

  void setBluetoothProvider(BluetoothProvider bluetoothProv) {
    _bluetoothProvider = bluetoothProv;
    // TODO : écouter le flux BLE et appeler updateFromJson
  }

  void updateFromJson(String trameJson) {
    // Parse la trame
    currentData = _parser.parseSensorTrame(trameJson);
    lastReceivedTime = DateTime.now();
    _resetTimeout();
    notifyListeners();
  }

  void updateCoefficients(Coefficients coef) {
    currentCoefficients = coef;
    notifyListeners();
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(Duration(seconds: 3), () {
      // Pas de trame depuis ≥ 3s
      notifyListeners();
    });
  }

  void simulateRandomData() {
    // TODO : générer une trame JSON aléatoire et appeler updateFromJson
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
