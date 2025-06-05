import 'dart:async';

class BluetoothService {
  static final StreamController<String> _controller =
      StreamController<String>.broadcast();

  /// Stream of raw JSON frames received from the device.
  static Stream<String> get onDataReceived => _controller.stream;

  /// Simulate receiving a frame for testing.
  static void simulateReceive(String data) {
    _controller.add(data);
  }

  static Future<void> connect() async {
    // TODO: implement real BLE connection using flutter_blue
  }

  static Future<void> disconnect() async {
    // TODO: implement disconnect
  }
}
