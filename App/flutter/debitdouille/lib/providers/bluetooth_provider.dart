import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;
import 'package:permission_handler/permission_handler.dart';
import '../services/bluetooth_service.dart';

enum ConnectionStatus { none, scanning, connected, error }

class BluetoothProvider with ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();
  fb.BluetoothDevice? connectedDevice;
  ConnectionStatus status = ConnectionStatus.none;
  StreamSubscription<String>? _dataSubscription;

  /// Demande les permissions nécessaires pour scanner et se connecter en BLE.
  Future<bool> _requestBlePermissions() async {
    // Pour Android 12+ : BLUETOOTH_SCAN et BLUETOOTH_CONNECT
    final scanStatus = await Permission.bluetoothScan.request();
    final connectStatus = await Permission.bluetoothConnect.request();
    if (scanStatus.isDenied || connectStatus.isDenied) return false;

    // Pour Android <12 ou en complément, demander la localisation
    final locationStatus = await Permission.locationWhenInUse.request();
    return locationStatus.isGranted;
  }

  /// Lance un scan BLE, puis se connecte au premier appareil trouvé.
  Future<void> scanAndConnect() async {
    status = ConnectionStatus.scanning;
    notifyListeners();

    // 1. Vérifier et demander les permissions BLE/Localisation
    final hasPerms = await _requestBlePermissions();
    if (!hasPerms) {
      status = ConnectionStatus.none;
      notifyListeners();
      return;
    }

    // 2. Scanner les périphériques
    try {
      final List<fb.BluetoothDevice> devices = await _bluetoothService.scanDevices();
      if (devices.isNotEmpty) {
        await connectToDevice(devices.first);
      } else {
        status = ConnectionStatus.none;
        notifyListeners();
      }
    } catch (_) {
      status = ConnectionStatus.error;
      notifyListeners();
    }
  }

  /// Se connecte à [device], met à jour l’état et démarre l’écoute des notifications.
  Future<void> connectToDevice(fb.BluetoothDevice device) async {
    try {
      await _bluetoothService.connectToDevice(device);
      connectedDevice = device;
      status = ConnectionStatus.connected;
      notifyListeners();
      startListening();
    } catch (_) {
      status = ConnectionStatus.error;
      notifyListeners();
    }
  }

  /// Démarre l’écoute des trames JSON depuis la caractéristique BLE.
  void startListening() {
    if (connectedDevice == null) return;

    // Remplacez ces GUIDs par ceux de votre périphérique BLE
    final serviceUuid = fb.Guid('00001234-0000-1000-8000-00805f9b34fb');
    final characteristicUuid = fb.Guid('00005678-0000-1000-8000-00805f9b34fb');

    _dataSubscription = _bluetoothService
        .listenDataStream(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
        )
        .listen((jsonString) {
      // Transmettre la trame JSON à un SensorProvider par exemple :
      // Provider.of<SensorProvider>(context, listen: false).updateFromJson(jsonString);
    }, onError: (_) {
      status = ConnectionStatus.error;
      notifyListeners();
    });
  }

  /// Stoppe l’écoute des notifications BLE.
  void stopListening() {
    _dataSubscription?.cancel();
    _dataSubscription = null;
  }

  /// Déconnecte proprement le périphérique BLE.
  Future<void> disconnect() async {
    await _bluetoothService.disconnect();
    connectedDevice = null;
    status = ConnectionStatus.none;
    notifyListeners();
    stopListening();
  }
}
