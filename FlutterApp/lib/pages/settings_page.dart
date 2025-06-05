import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int meters = 2;
  bool showSimButton = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      meters = prefs.getInt('meters') ?? 2;
      showSimButton = prefs.getBool('showSim') ?? false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('meters', meters);
    await prefs.setBool('showSim', showSimButton);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<int>(
              value: meters,
              dropdownColor: Colors.black,
              items: const [
                DropdownMenuItem(value: 2, child: Text('2 débitmètres')),
                DropdownMenuItem(value: 4, child: Text('4 débitmètres')),
                DropdownMenuItem(value: 6, child: Text('6 débitmètres')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => meters = v);
                  _save();
                }
              },
            ),
            SwitchListTile(
              title: const Text('Afficher le bouton de simulation'),
              value: showSimButton,
              onChanged: (v) {
                setState(() => showSimButton = v);
                _save();
              },
            ),
          ],
        ),
      ),
    );
  }
}
