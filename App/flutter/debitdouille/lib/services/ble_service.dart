import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class BleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _notify;
  BluetoothCharacteristic? _write;
  final _jsonStreamController = StreamController<String>.broadcast();

  Stream<String> get jsonStream => _jsonStreamController.stream;
  String? get connectedName => _device?.platformName;
  String? get connectedId => _device?.remoteId.str;

  static const _lastDeviceKey = "last_ble_device";

  /// ⏱️ Scanner rapide
  Future<List<BluetoothDevice>> scanDevices({Duration timeout = const Duration(seconds: 2)}) async {
    final List<BluetoothDevice> found = [];

    await FlutterBluePlus.startScan(timeout: timeout);
    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.platformName.isNotEmpty) {
          if (!found.any((d) => d.remoteId == r.device.remoteId)) {
            found.add(r.device);
          }
        }
      }
    });

    await Future.delayed(timeout);
    await FlutterBluePlus.stopScan();
    await sub.cancel();
    return found;
  }

  /// 💾 Sauvegarde de l'ID du périphérique
  Future<void> saveDeviceId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDeviceKey, id);
  }

  /// 🔄 Récupération de l'ID du périphérique
  Future<BluetoothDevice?> getSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_lastDeviceKey);
    if (id != null) {
      return BluetoothDevice.fromId(id);
    }
    return null;
  }

  /// ⚡ Connexion rapide (sans rescan)
  Future<void> reconnectSavedDevice() async {
    final device = await getSavedDevice();
    if (device != null) {
      try {
        await connectTo(device);
        print("✅ Reconnexion rapide réussie à ${device.remoteId}");
      } catch (e) {
        print("❌ Reconnexion rapide échouée : $e");
      }
    }
  }

  /// 📡 Connexion à un périphérique
  Future<void> connectTo(BluetoothDevice device) async {
    await device.connect(autoConnect: false).catchError((_) {});
    _device = device;
    await saveDeviceId(device.remoteId.str);

    final services = await device.discoverServices();

    for (final s in services) {
      for (final c in s.characteristics) {
        final id = c.uuid.toString().toLowerCase();
        if (id == BleUUID.notifyChar) _notify = c;
        if (id == BleUUID.writeChar) _write = c;
      }
    }

    if (_notify == null || _write == null) {
      for (final s in services) {
        for (final c in s.characteristics) {
          if (_notify == null && c.properties.notify) _notify = c;
          if (_write == null && c.properties.write) _write = c;
        }
      }
    }

    if (_notify == null) throw Exception("Aucune caractéristique notify trouvée");

    await _notify!.setNotifyValue(true);
    _notify!.onValueReceived.listen((data) {
      try {
        final s = utf8.decode(data);
        _jsonStreamController.add(s);
      } catch (_) {}
    });
  }

  /// 🔌 Déconnexion
  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _notify = null;
    _write = null;
  }

  Future<void> requestCoefficients() async {
    final cmd = utf8.encode(jsonEncode({"get_coeff": true}));
    await _write?.write(cmd, withoutResponse: false);
  }

  Future<void> sendUpdatedCoefficients(Map<String, Map<String, double>> coeff) async {
    final payload = {"update_coeff": coeff};
    final bytes = utf8.encode(jsonEncode(payload));
    await _write?.write(bytes, withoutResponse: false);
  }
}
