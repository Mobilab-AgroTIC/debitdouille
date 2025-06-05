import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/bluetooth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, double> data = {
    'P': 0,
    'DG1': 0,
    'DD1': 0,
    'DG2': 0,
    'DD2': 0,
    'DG3': 0,
    'DD3': 0,
    'V': 0,
  };
  bool ledOn = false;
  Timer? timeoutTimer;

  @override
  void initState() {
    super.initState();
    BluetoothService.onDataReceived.listen(_onData);
  }

  void _onData(String jsonStr) {
    try {
      final Map<String, dynamic> map = json.decode(jsonStr);
      map.forEach((k, v) {
        data[k] = (v as num).toDouble();
      });
      setState(() {
        ledOn = true;
      });
      timeoutTimer?.cancel();
      timeoutTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          ledOn = false;
        });
      });
    } catch (_) {
      // ignore malformed json
    }
  }

  void _simulate() {
    final rnd = Random();
    final sample = jsonEncode({
      'P': rnd.nextDouble() * 3 + 1,
      'DG1': rnd.nextDouble() * 3,
      'DD1': rnd.nextDouble() * 3,
      'DG2': rnd.nextDouble() * 3,
      'DD2': rnd.nextDouble() * 3,
      'DG3': rnd.nextDouble() * 3,
      'DD3': rnd.nextDouble() * 3,
      'V': rnd.nextDouble() * 10,
    });
    _onData(sample);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headline4!.copyWith(color: Colors.white);

    final List<Widget> left = [];
    final List<Widget> right = [];
    for (var i = 1; i <= 3; i++) {
      final g = data['DG$i']!;
      final d = data['DD$i']!;
      if (g > 0 || d > 0) {
        left.add(Text('DG$i: ${g.toStringAsFixed(2)}', style: textStyle));
        right.add(Text('DD$i: ${d.toStringAsFixed(2)}', style: textStyle));
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Débitdouille'),
        backgroundColor: Colors.black,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          )
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: const Text('Connexion'),
              onTap: () => Navigator.of(context).pushNamed('/connect'),
            ),
            ListTile(
              title: const Text('Calibrer les capteurs'),
              onTap: () => Navigator.of(context).pushNamed('/calibrate'),
            ),
            ListTile(
              title: const Text('Réglages'),
              onTap: () => Navigator.of(context).pushNamed('/settings'),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.circle,
                    color: ledOn ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text('P: ${data['P']!.toStringAsFixed(2)}', style: textStyle),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: left,
                )),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: right,
                )),
              ],
            ),
            const Spacer(),
            Align(
                alignment: Alignment.center,
                child: Text('V: ${data['V']!.toStringAsFixed(1)}',
                    style: textStyle)),
            const SizedBox(height: 8),
            Text(jsonEncode(data),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _simulate,
        child: const Icon(Icons.bug_report),
      ),
    );
  }
}

