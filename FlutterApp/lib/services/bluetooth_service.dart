import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

class BluetoothService {
  static final StreamController<String> _controller =
      StreamController<String>.broadcast();

  static final FlutterBlue _flutterBlue = FlutterBlue.instance;

  /// Stream of raw JSON frames received from the device.
  static Stream<String> get onDataReceived => _controller.stream;

  /// Stream of scan results when scanning for BLE devices.
  static Stream<List<ScanResult>> get scanResults => _flutterBlue.scanResults;

  /// Simulate receiving a frame for testing.
  static void simulateReceive(String data) {
    _controller.add(data);
  }

  static Future<void> startScan() async {
    await _flutterBlue.startScan(timeout: const Duration(seconds: 4));
  }

  static Future<void> stopScan() async {
    await _flutterBlue.stopScan();
  }

  static Future<void> connect() async {
    // TODO: implement real BLE connection using flutter_blue
  }

  static Future<void> disconnect() async {
    // TODO: implement disconnect
  }
}
