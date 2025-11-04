import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<BluetoothDevice> devices = [];
  bool scanning = false;
  String? error;

  Future<void> _scan() async {
    setState(() { scanning = true; error = null; devices.clear(); });
    try {
      final d = await context.read<DataProvider>().scan();
      devices = d.where((x) => x.platformName.isNotEmpty).toList();
      } catch (e) {
        print("Erreur BLE : $e");
        setState(() { error = "Scan échoué : $e"; });
      }
 finally {
      if (mounted) setState(() { scanning = false; });
    }
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

  @override
  Widget build(BuildContext context) {
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
              Text("${devices.length} trouvé(s)", style: const TextStyle(color: Colors.white70)),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Colors.redAccent)),
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
