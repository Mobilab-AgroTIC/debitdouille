import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import '../services/bluetooth_service.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final List<ScanResult> _devices = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    BluetoothService.scanResults.listen((results) {
      setState(() {
        _devices
          ..clear()
          ..addAll(results);
      });
    });
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    await BluetoothService.startScan();
    await Future.delayed(const Duration(seconds: 4));
    await BluetoothService.stopScan();
    setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _scanning ? null : _scan,
              child: Text(_scanning ? 'Scan en cours...' : 'Scanner'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final d = _devices[index];
                return ListTile(
                  title: Text(d.device.name.isNotEmpty
                      ? d.device.name
                      : d.device.id.id),
                  subtitle: Text(d.rssi.toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
