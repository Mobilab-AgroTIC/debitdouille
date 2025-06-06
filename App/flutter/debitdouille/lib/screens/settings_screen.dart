import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settingsProv = Provider.of<SettingsProvider>(context);
    final settings = settingsProv.currentSettings;

    return Scaffold(
      appBar: AppBar(
        title: Text('Réglages'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<int>(
              value: settings.numberOfFlowMeters,
              items: [2, 4, 6].map((n) {
                return DropdownMenuItem<int>(
                  value: n,
                  child: Text('$n débitmètres'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  settingsProv.updateNumberOfFlowMeters(value);
                }
              },
            ),
            SwitchListTile(
              title: Text('Afficher le bouton simuler une trame'),
              value: settings.showSimulateButton,
              onChanged: (value) {
                settingsProv.updateShowSimulateButton(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
