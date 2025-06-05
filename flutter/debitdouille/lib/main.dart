import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Débitdouille',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          bodySmall: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Courier'),
        ),
        colorScheme: const ColorScheme.dark().copyWith(secondary: Colors.greenAccent),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double pression = 0.0;
  double vitesse = 0.0;
  final Map<String, double> debitsGauche = {};
  final Map<String, double> debitsDroit = {};
  String trameBrute = '';

  bool _frameReceived = false;
  bool _frameTimeout = false;
  Timer? _timeoutTimer;

  void _simulateFrameReception() {
    final rand = Random();
    final simulatedTrame = {
      "P": rand.nextDouble() * 3 + 1,
      "DG1": rand.nextDouble() * 3,
      "DD1": rand.nextDouble() * 3,
      if (rand.nextBool()) "DG2": rand.nextDouble() * 3,
      if (rand.nextBool()) "DD2": rand.nextDouble() * 3,
      if (rand.nextBool()) "DG3": rand.nextDouble() * 3,
      if (rand.nextBool()) "DD3": rand.nextDouble() * 3,
      "V": rand.nextDouble() * 6 + 3,
    };
    _parseFrame(jsonEncode(simulatedTrame));
  }

  void _parseFrame(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      setState(() {
        pression = (data['P'] as num).toDouble();
        vitesse = (data['V'] as num).toDouble();
        debitsGauche.clear();
        debitsDroit.clear();

        data.forEach((key, value) {
          if (key.startsWith('DG')) debitsGauche[key] = (value as num).toDouble();
          if (key.startsWith('DD')) debitsDroit[key] = (value as num).toDouble();
        });

        final filteredData = {
          'P': pression.toStringAsFixed(2),
          ...debitsGauche.map((k, v) => MapEntry(k, v.toStringAsFixed(2))),
          ...debitsDroit.map((k, v) => MapEntry(k, v.toStringAsFixed(2))),
          'V': vitesse.toStringAsFixed(1),
        };
        trameBrute = jsonEncode(filteredData);

        _frameReceived = true;
        _frameTimeout = false;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() => _frameReceived = false);
      });

      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          _frameTimeout = true;
        });
      });
    } catch (e) {
      debugPrint("Erreur JSON : $e");
    }
  }

  Widget buildValueBlock(String label, String value, String unit) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: Theme.of(context).textTheme.bodyLarge),
              TextSpan(text: ' $unit', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color frameColor = _frameReceived
        ? Colors.greenAccent
        : (_frameTimeout ? Colors.red : Colors.grey);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
          Positioned(
  top: 0,
  left: 0,
  right: 0,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cercle
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: frameColor, shape: BoxShape.circle),
        ),

        // Pression centrée
        Expanded(
          child: Center(
            child: buildValueBlock("Pression", pression.toStringAsFixed(2), "bar"),
          ),
        ),

        // Bouton menu à droite
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.white),
          color: Colors.grey[900],
          onSelected: (value) {
            if (value == 'connect') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PageConnexionBluetooth()),
              );
            } else if (value == 'calibrate') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PageCalibrationCapteurs()),
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'connect',
              child: ListTile(
                leading: Icon(Icons.bluetooth, color: Colors.white),
                title: Text("Connecter un Débitdouille", style: TextStyle(color: Colors.white)),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'calibrate',
              child: ListTile(
                leading: Icon(Icons.tune, color: Colors.white),
                title: Text("Calibrer les capteurs", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
),


            // Corps principal : débits + vitesse
            Positioned.fill(
              top: 70,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Column(
                              children: debitsGauche.entries
                                  .map((e) => Expanded(
                                        child: buildValueBlock(e.key, e.value.toStringAsFixed(2), "L/min"),
                                      ))
                                  .toList(),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: debitsDroit.entries
                                  .map((e) => Expanded(
                                        child: buildValueBlock(e.key, e.value.toStringAsFixed(2), "L/min"),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    buildValueBlock("Vitesse", vitesse.toStringAsFixed(1), "km/h"),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Trame brute en bas
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.5),
                child: Text(
                  "Trame Reçue :\n$trameBrute",
                  style: Theme.of(context).textTheme.bodySmall,
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _simulateFrameReception,
        tooltip: 'Simuler trame',
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.refresh, color: Colors.black, size: 32),
      ),
    );
  }
}

// Page Bluetooth
class PageConnexionBluetooth extends StatelessWidget {
  const PageConnexionBluetooth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion à un Débitdouille")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text("Connecter un Débitdouille déjà utilisé."),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text("Rechercher des périphériques"),
              onPressed: () {
                debugPrint("Simulation de scan Bluetooth.");
              },
            ),
          ]
        ),
      ),
    );
  }
}


// Page Calibration
class PageCalibrationCapteurs extends StatefulWidget {
  const PageCalibrationCapteurs({super.key});

  @override
  State<PageCalibrationCapteurs> createState() => _PageCalibrationCapteursState();
}

class _PageCalibrationCapteursState extends State<PageCalibrationCapteurs> {
  double coef1 = 1.0;
  double coef2 = 1.0;
  double coef3 = 1.0;

  void _envoyer() {
    final data = {
      'calibration': [coef1, coef2, coef3]
    };
    final jsonStr = jsonEncode(data);
    debugPrint("Envoi Bluetooth : $jsonStr");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Coefficients envoyés")),
    );
  }

  Widget slider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Text("$label : ${value.toStringAsFixed(2)}"),
        Slider(
          value: value,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calibration des capteurs")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.tune, size: 100, color: Colors.greenAccent),
            slider("Coefficient 1", coef1, (v) => setState(() => coef1 = v)),
            slider("Coefficient 2", coef2, (v) => setState(() => coef2 = v)),
            slider("Coefficient 3", coef3, (v) => setState(() => coef3 = v)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text("Envoyer"),
              onPressed: _envoyer,
            ),
          ],
        ),
      ),
    );
  }
}
