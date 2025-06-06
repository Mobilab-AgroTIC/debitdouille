import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';           
import '../providers/sensor_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/sensor_value_widget.dart';
import '../widgets/status_indicator.dart';
import '../widgets/data_frame_overlay.dart';
import '../widgets/simulate_button.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sensorProv = Provider.of<SensorProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).currentSettings;
    final data = sensorProv.currentData;

    // Calculer statut du rond rouge/vert/gris
    // Par défaut gris
    ConnectionStatus statusIndicator = ConnectionStatus.none;
    if (sensorProv.lastReceivedTime != null) {
      final diff = DateTime.now().difference(sensorProv.lastReceivedTime!);
      if (diff.inSeconds < 1) {
        statusIndicator = ConnectionStatus.connected; // vert
      } else if (diff.inSeconds >= 3) {
        statusIndicator = ConnectionStatus.error; // rouge
      } else {
        statusIndicator = ConnectionStatus.none; // gris
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Débitdouille'),
        backgroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            onSelected: (route) {
              Navigator.pushNamed(context, route);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: '/connection', child: Text('Connexion')),
              PopupMenuItem(value: '/calibration', child: Text('Calibrer')),
              PopupMenuItem(value: '/settings', child: Text('Réglages')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (data != null)
                  SensorValueWidget(
                    label: 'Pression',
                    value: data.pressure,
                    unit: 'bar',
                  ),
                SizedBox(height: 16),
                _buildFlowGrid(data, settings.numberOfFlowMeters),
                SizedBox(height: 16),
                if (data != null)
                  SensorValueWidget(
                    label: 'Vitesse',
                    value: data.speed,
                    unit: 'km/h',
                  ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: StatusIndicator(status: statusIndicator),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: DataFrameOverlay(
              lastJsonFrame: data != null ? data.toString() : 'Aucune trame reçue',
            ),
          ),
          if (settings.showSimulateButton)
            Positioned(
              bottom: 16,
              right: 16,
              child: SimulateButton(
                onPressed: () => sensorProv.simulateRandomData(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlowGrid(SensorData? data, int count) {
    if (data == null) {
      return Text('En attente de données...', style: TextStyle(color: Colors.white));
    }
    List<Widget> widgets = [];
    for (int i = 0; i < (count / 2).ceil(); i++) {
      int leftIndex = i;
      int rightIndex = i + (count ~/ 2);
      if (rightIndex >= data.flowPairs.length) {
        rightIndex = leftIndex;
      }
      widgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SensorValueWidget(
              label: 'D G${leftIndex + 1}',
              value: data.flowPairs[leftIndex].left,
              unit: 'L/min',
            ),
            SizedBox(width: 32),
            SensorValueWidget(
              label: 'D D${leftIndex + 1}',
              value: data.flowPairs[leftIndex].right,
              unit: 'L/min',
            ),
          ],
        ),
      );
      widgets.add(SizedBox(height: 16));
      if (widgets.length >= (count * 2)) break;
    }
    return Column(children: widgets);
  }
}
