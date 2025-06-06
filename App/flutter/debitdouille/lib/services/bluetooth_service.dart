import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _notificationSubscription;

  /// Scanne pendant [timeout] et renvoie la liste des périphériques uniques trouvés.
  Future<List<BluetoothDevice>> scanDevices({Duration timeout = const Duration(seconds: 5)}) async {
    final List<BluetoothDevice> devices = [];

    // Démarrer le scan
    FlutterBluePlus.startScan(timeout: timeout);

    // Écoute des résultats de scan
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        final dev = result.device;
        if (!devices.any((d) => d.id == dev.id)) {
          devices.add(dev);
        }
      }
    });

    // Attendre la fin du scan
    await Future.delayed(timeout);
    await FlutterBluePlus.stopScan();
    await subscription.cancel();

    return devices;
  }

  /// Se connecte à [device], découvre les services puis renvoie lorsque c’est prêt.
  Future<void> connectToDevice(BluetoothDevice device) async {
    _connectedDevice = device;
    // Essayer de se connecter
    await _connectedDevice!.connect();
    // Découvrir les services après connexion
    await _connectedDevice!.discoverServices();
    // TODO : si besoin, abonner _notificationSubscription à une caractéristique spécifique
  }

  /// Écoute les notifications JSON depuis la caractéristique spécifiée.
  Stream<String> listenDataStream({
    required Guid serviceUuid,
    required Guid characteristicUuid,
  }) {
    if (_connectedDevice == null) return const Stream.empty();

    // On crée un StreamController pour émettre les Strings JSON
    final controller = StreamController<String>();

    // Première étape : découvrir les services (si pas déjà fait)
    _connectedDevice!
        .discoverServices()
        .then((services) {
          final service = services.firstWhere(
            (s) => s.uuid == serviceUuid,
            orElse: () => throw Exception('Service non trouvé'),
          );
          final characteristic = service.characteristics.firstWhere(
            (c) => c.uuid == characteristicUuid,
            orElse: () => throw Exception('Caractéristique non trouvée'),
          );

          // Activer les notifications
          return characteristic.setNotifyValue(true).then((_) => characteristic);
        })
        .then((characteristic) {
          // Écouter les valeurs de la caractéristique
          _notificationSubscription = characteristic.value.listen((bytes) {
            final jsonString = String.fromCharCodes(bytes);
            controller.add(jsonString);
          });
        })
        .catchError((error) {
          controller.addError(error);
        });

    // Lorsque le stream est annulé, on nettoie la souscription BLE
    controller.onCancel = () async {
      await _notificationSubscription?.cancel();
      _notificationSubscription = null;
    };

    return controller.stream;
  }

  /// Sérialise [coefJson] en JSON et l’envoie via la caractéristique spécifiée.
  Future<void> sendCoefficients({
    required Guid serviceUuid,
    required Guid characteristicUuid,
    required Map<String, dynamic> coefJson,
  }) async {
    if (_connectedDevice == null) return;

    final services = await _connectedDevice!.discoverServices();
    final service = services.firstWhere((s) => s.uuid == serviceUuid);
    final characteristic = service.characteristics.firstWhere((c) => c.uuid == characteristicUuid);

    // Convertir en bytes (ici on utilise utf8.encode pour produire un JSON valide)
    final jsonString = coefJson.isNotEmpty ? coefJson.toString() : '{}';
    final bytes = utf8.encode(jsonString);

    await characteristic.write(bytes, withoutResponse: false);
  }

  /// Déconnecte proprement le périphérique BLE.
  Future<void> disconnect() async {
    if (_notificationSubscription != null) {
      await _notificationSubscription!.cancel();
      _notificationSubscription = null;
    }
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }
}
