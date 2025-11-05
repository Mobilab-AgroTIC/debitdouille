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
  final _connectionStateController = StreamController<bool>.broadcast();
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;

  Stream<String> get jsonStream => _jsonStreamController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  BluetoothDevice? get connectedDevice => _device;
  String? _savedDeviceName;
  String? get connectedName => _device?.platformName.isNotEmpty == true ? _device?.platformName : _savedDeviceName;
  String? get connectedId => _device?.remoteId.str;
  bool get isReconnecting => _isReconnecting;

  static const _lastDeviceKey = "last_ble_device";
  static const _lastDeviceNameKey = "last_ble_device_name";

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

  /// 💾 Sauvegarde de l'ID et du nom du périphérique
  Future<void> saveDeviceId(String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDeviceKey, id);
    await prefs.setString(_lastDeviceNameKey, name);
  }

  /// 🔄 Récupération de l'ID du périphérique
  Future<BluetoothDevice?> getSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_lastDeviceKey);
    final name = prefs.getString(_lastDeviceNameKey);
    if (id != null) {
      _savedDeviceName = name; // Charger le nom sauvegardé
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
    // Ne réinitialiser le compteur que si on n'est pas en train de se reconnecter
    if (!_isReconnecting) {
      _reconnectAttempts = 0;
    }
    // Ne sauvegarder que si on a un nom valide, sinon garder le nom existant en cache
    if (device.platformName.isNotEmpty) {
      await saveDeviceId(device.remoteId.str, device.platformName);
      _savedDeviceName = device.platformName; // Mettre à jour le cache
    }

    // Écouter les changements d'état de connexion pour détecter les déconnexions
    await _connectionStateSub?.cancel();
    _connectionStateSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        print("! Déconnexion BLE détectée");
        _connectionStateController.add(false);
        if (!_isReconnecting) {
          _onDeviceDisconnected();
        }
      } else if (state == BluetoothConnectionState.connected) {
        _connectionStateController.add(true);
      }
    });

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

    _connectionStateController.add(true);
  }

  /// 🔄 Gestion de la déconnexion inattendue avec reconnexion automatique
  Future<void> _onDeviceDisconnected() async {
    if (_device == null || _isReconnecting) return;

    _isReconnecting = true;
    _reconnectAttempts = 0; // Réinitialiser le compteur au début de la séquence
    print("🔄 Tentative de reconnexion automatique...");

    while (_reconnectAttempts < _maxReconnectAttempts) {
      final delaySeconds = (_reconnectAttempts + 1) * 2; // Backoff exponentiel: 2s, 4s, 6s, 8s, 10s
      print("🔄 Tentative ${_reconnectAttempts + 1}/$_maxReconnectAttempts (attente ${delaySeconds}s)");
      await Future.delayed(Duration(seconds: delaySeconds));

      _reconnectAttempts++;

      try {
        final savedDevice = await getSavedDevice();
        if (savedDevice == null) {
          print("❌ Aucun périphérique sauvegardé");
          break;
        }

        await connectTo(savedDevice);
        print("✅ Reconnexion automatique réussie !");
        _isReconnecting = false;
        _reconnectAttempts = 0;
        return;
      } catch (e) {
        print("❌ Tentative $_reconnectAttempts échouée: $e");
      }
    }

    print("❌ Reconnexion automatique échouée après $_maxReconnectAttempts tentatives");
    _isReconnecting = false;
    _reconnectAttempts = 0;
    await disconnect();
  }

  /// 🔌 Déconnexion
  Future<void> disconnect() async {
    _isReconnecting = false;
    await _connectionStateSub?.cancel();
    _connectionStateSub = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _savedDeviceName = null; // Effacer le nom en cache
    _notify = null;
    _write = null;
    _connectionStateController.add(false);
  }

  Future<void> requestCoefficients() async {
    final cmd = utf8.encode(jsonEncode({"get_coeff": true}));
    await _write?.write(cmd, withoutResponse: false);
  }

  Future<void> sendUpdatedCoefficients(Map<String, Map<String, dynamic>> coeff) async {
    final payload = {"update_coeff": coeff};
    final bytes = utf8.encode(jsonEncode(payload));
    await _write?.write(bytes, withoutResponse: false);
  }
}
