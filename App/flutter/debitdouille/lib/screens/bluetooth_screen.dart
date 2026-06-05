import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

/// Type d'erreur de scan nécessitant une action de l'utilisateur.
enum _ScanIssue { none, bluetoothOff, locationOff }

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<BluetoothDevice> devices = [];
  bool scanning = false;
  String? error;
  // Type d'erreur courant : détermine le bouton d'action proposé
  // (activer le Bluetooth / ouvrir les réglages de localisation).
  _ScanIssue issue = _ScanIssue.none;

  @override
  void initState() {
    super.initState();
    // 🔍 Lancer le scan automatiquement au démarrage de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scan();
    });
  }

  Future<void> _scan() async {
    setState(() { scanning = true; error = null; issue = _ScanIssue.none; devices.clear(); });
    try {
      final d = await context.read<DataProvider>().scan();
      devices = d.where((x) => x.platformName.isNotEmpty).toList();
    } catch (e) {
      debugPrint("Erreur BLE : $e");
      final detected = _classifyError(e);
      setState(() {
        issue = detected;
        switch (detected) {
          case _ScanIssue.bluetoothOff:
            error = "Le Bluetooth doit être activé sur le téléphone pour "
                "scanner les appareils.";
            break;
          case _ScanIssue.locationOff:
            error = "La localisation (GPS) doit être activée sur le téléphone "
                "pour scanner en Bluetooth. C'est une obligation Android : "
                "le débitdouille n'utilise pas votre position.";
            break;
          case _ScanIssue.none:
            error = "Scan échoué : $e";
            break;
        }
      });
    } finally {
      if (mounted) setState(() { scanning = false; });
    }
  }

  /// Classe l'erreur FlutterBluePlus pour adapter le message et l'action.
  /// - Bluetooth éteint : "Bluetooth must be turned on"
  /// - Localisation désactivée : "Location services are required ..."
  _ScanIssue _classifyError(Object e) {
    final msg = (e is PlatformException ? (e.message ?? '') : e.toString())
        .toLowerCase();
    if (msg.contains('bluetooth') && msg.contains('turned on')) {
      return _ScanIssue.bluetoothOff;
    }
    if (msg.contains('location')) {
      return _ScanIssue.locationOff;
    }
    return _ScanIssue.none;
  }

  /// Propose à l'utilisateur d'activer le Bluetooth (popup système Android),
  /// puis relance le scan si c'est accepté.
  Future<void> _enableBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (_) {
      // L'utilisateur a refusé ou la plateforme ne le permet pas : on ouvre
      // les réglages de l'app en repli.
      await openAppSettings();
    }
    if (mounted) await _scan();
  }

  Future<void> _openLocationSettings() async {
    // Ouvre directement l'écran des réglages de localisation du téléphone.
    await Permission.location.request();
    await openAppSettings();
  }

  Future<void> _connect(BluetoothDevice d) async {
    try {
      await context.read<DataProvider>().connect(d);
      // Retour auto sur Accueil
      context.read<SettingsProvider>().go(AppPage.home);
    } catch (e) {
      setState(() { error = "Connexion échouée (UUID ?)"; });
    }
  }

  Future<void> _disconnect() async {
    await context.read<DataProvider>().disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final dataProv = context.watch<DataProvider>();
    final isConnected = dataProv.connectedDevice != null;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: scanning ? null : _scan,
                child: Text(scanning ? "Scan..." : "Scanner"),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isConnected ? _disconnect : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: const Text("Déconnecter"),
              ),
              const SizedBox(width: 12),
              Text("${devices.length} trouvé(s)", style: const TextStyle(color: Colors.white70)),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Colors.redAccent)),
            if (issue == _ScanIssue.bluetoothOff) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _enableBluetooth,
                  icon: const Icon(Icons.bluetooth),
                  label: const Text("Activer le Bluetooth"),
                ),
              ),
            ],
            if (issue == _ScanIssue.locationOff) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _openLocationSettings,
                  icon: const Icon(Icons.location_on),
                  label: const Text("Ouvrir les réglages de localisation"),
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (_, i) {
                final d = devices[i];
                return ListTile(
                  title: Text(d.platformName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(d.remoteId.str, style: const TextStyle(color: Colors.white54)),
                  trailing: ElevatedButton(
                    onPressed: () => _connect(d),
                    child: const Text("Connecter"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
