import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';

class ConnectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final btProv = Provider.of<BluetoothProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion Débitdouille'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                // Ouvrir écran natif d’appairage (à implémenter si besoin)
              },
              child: Text('Nouvel appairage'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => btProv.scanAndConnect(),
              child: Text('Rechercher périphériques'),
            ),
            SizedBox(height: 16),
            Text(
              'Statut : ${btProv.status}',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  // TODO : lister les derniers appareils appairés si disponibles
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
