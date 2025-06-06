import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;
import '../models/coefficients.dart';
import '../providers/sensor_provider.dart';
import '../providers/settings_provider.dart';
import '../services/bluetooth_service.dart';

class CalibrationScreen extends StatefulWidget {
  @override
  _CalibrationScreenState createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  // On utilise ici directement BluetoothService sans ambiguïté
  final BluetoothService _btService = BluetoothService();
  String selectedSensor = '';
  final TextEditingController _aController = TextEditingController();
  final TextEditingController _bController = TextEditingController();

  // Remplacez ces GUIDs par ceux de votre périphérique BLE
  static final fb.Guid _serviceUuid =
      fb.Guid('00001234-0000-1000-8000-00805f9b34fb');
  static final fb.Guid _characteristicUuid =
      fb.Guid('00005678-0000-1000-8000-00805f9b34fb');

  @override
  void initState() {
    super.initState();
    // Demander les coefficients dès l’ouverture (envoie le JSON {"request":"coef"})
    _btService.sendCoefficients(
      serviceUuid: _serviceUuid,
      characteristicUuid: _characteristicUuid,
      coefJson: {'request': 'coef'},
    );
    // TODO : écouter la réponse BLE et mettre à jour SensorProvider.updateCoefficients()
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).currentSettings;
    final sensorProv = Provider.of<SensorProvider>(context);
    Coefficients? coef = sensorProv.currentCoefficients;

    List<String> sensors = ['Pression'];
    for (int i = 1; i <= settings.numberOfFlowMeters; i++) {
      sensors.add('Débitmètre D$i');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Calibration'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: (selectedSensor.isEmpty && sensors.isNotEmpty)
                  ? sensors.first
                  : selectedSensor,
              items: sensors
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedSensor = value!;
                  // Préremplir _aController et _bController si coef existe :
                  if (coef != null) {
                    switch (selectedSensor) {
                      case 'Pression':
                        _aController.text = coef.aPressure.toString();
                        _bController.text = coef.bPressure.toString();
                        break;
                      case 'Débitmètre D1':
                        _aController.text = coef.aD1.toString();
                        _bController.text = coef.bD1.toString();
                        break;
                      case 'Débitmètre D2':
                        _aController.text = coef.aD2.toString();
                        _bController.text = coef.bD2.toString();
                        break;
                      case 'Débitmètre D3':
                        _aController.text = coef.aD3.toString();
                        _bController.text = coef.bD3.toString();
                        break;
                      // Ajoutez d'autres cas si numberOfFlowMeters > 3
                      default:
                        _aController.clear();
                        _bController.clear();
                    }
                  }
                });
              },
            ),
            TextFormField(
              controller: _aController,
              decoration: InputDecoration(labelText: 'a'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextFormField(
              controller: _bController,
              decoration: InputDecoration(labelText: 'b'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                double a = double.tryParse(_aController.text) ?? 0.0;
                double b = double.tryParse(_bController.text) ?? 0.0;

                // Construire le JSON selon selectedSensor
                Map<String, dynamic> jsonToSend = {};
                switch (selectedSensor) {
                  case 'Pression':
                    jsonToSend = {
                      'coef': {
                        'capteur': 'pression',
                        'a': a,
                        'b': b,
                      }
                    };
                    break;
                  case 'Débitmètre D1':
                    jsonToSend = {
                      'coef': {
                        'capteur': 'D1',
                        'a': a,
                        'b': b,
                      }
                    };
                    break;
                  case 'Débitmètre D2':
                    jsonToSend = {
                      'coef': {
                        'capteur': 'D2',
                        'a': a,
                        'b': b,
                      }
                    };
                    break;
                  case 'Débitmètre D3':
                    jsonToSend = {
                      'coef': {
                        'capteur': 'D3',
                        'a': a,
                        'b': b,
                      }
                    };
                    break;
                  // Ajoutez d'autres cas si nécessaire
                  default:
                    return;
                }

                _btService.sendCoefficients(
                  serviceUuid: _serviceUuid,
                  characteristicUuid: _characteristicUuid,
                  coefJson: jsonToSend,
                );
              },
              child: Text('Envoyer'),
            ),
            if (settings.showSimulateButton)
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {
                    Provider.of<SensorProvider>(context, listen: false)
                        .simulateRandomData();
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.play_arrow, color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
