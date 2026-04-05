import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../utils/constants.dart';

const sensorKeys = ["P", "DG1", "DD1", "DG2", "DD2", "DG3", "DD3", "DG4", "DD4"];

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> with TickerProviderStateMixin {
  late TabController _tab;
  final Map<String, TextEditingController> _aCtrls = {};
  final Map<String, TextEditingController> _bCtrls = {};
  double valeurCalib = 0.0;
  double valeurBrute = 0.0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: sensorKeys.length, vsync: this);
    for (final k in sensorKeys) {
      _aCtrls[k] = TextEditingController();
      _bCtrls[k] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _getCoeffs());
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in _aCtrls.values) { c.dispose(); }
    for (final c in _bCtrls.values) { c.dispose(); }
    super.dispose();
  }

  void _recalc(double calib, String k) {
    final A = double.tryParse(_aCtrls[k]!.text) ?? 1.0;
    final B = double.tryParse(_bCtrls[k]!.text) ?? 0.0;
    setState(() {
      valeurCalib = calib;
      valeurBrute = (calib - B) / (A == 0 ? 1e-9 : A);
    });
  }

Future<void> _getCoeffs() async {
  final dp = context.read<DataProvider>();

  // On attend une trame contenant "coeff"
  final completer = Completer<String>();
  final sub = dp.ble.jsonStream.listen((s) {
    try {
      final j = jsonDecode(s);
      if (j is Map && j["coeff"] != null) {
        completer.complete(s);
      }
    } catch (_) {}
  });

  // Envoie la commande
  await dp.requestCoefficients();

  // Attend max 1 seconde
  String? jsonString;
  try {
    jsonString = await completer.future.timeout(const Duration(seconds: 1));
  } catch (_) {
    debugPrint("⛔ Pas de trame coeff reçue");
  }
  await sub.cancel();

  if (jsonString == null) return;

  try {
    final j = jsonDecode(jsonString);
    final Map coeff = j["coeff"];
    for (final k in sensorKeys) {
      if (coeff[k] is Map) {
        final A = (coeff[k]["A"] as num?)?.toDouble() ?? 1.0;
        final B = (coeff[k]["B"] as num?)?.toDouble() ?? 0.0;
        _aCtrls[k]!.text = A.toStringAsFixed(3);
        _bCtrls[k]!.text = B.toStringAsFixed(3);
      }
    }
    if (mounted) setState(() {});
  } catch (e) {
    debugPrint("⛔ Erreur parsing coeff: $e");
  }
}


  Future<void> _sendCoeffs() async {
    final Map<String, Map<String, double>> payload = {};
    for (final k in sensorKeys) {
      payload[k] = {
        "A": double.tryParse(_aCtrls[k]!.text) ?? 1.0,
        "B": double.tryParse(_bCtrls[k]!.text) ?? 0.0,
      };
    }
    await context.read<DataProvider>().sendUpdatedCoefficients(payload);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Coefficients envoyés")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    double currentCalib() {
      final k = sensorKeys[_tab.index];
      switch (k) {
        case "P": return dp.data.P;
        case "DG1": return dp.data.DG[0];
        case "DD1": return dp.data.DD[0];
        case "DG2": return dp.data.DG[1];
        case "DD2": return dp.data.DD[1];
        case "DG3": return dp.data.DG[2];
        case "DD3": return dp.data.DD[2];
        case "DG4": return dp.data.DG[3];
        case "DD4": return dp.data.DD[3];
        default: return 0.0;
      }
    }

    final currentKey = sensorKeys[_tab.index];
    _recalc(currentCalib(), currentKey);
    final A = double.tryParse(_aCtrls[currentKey]!.text) ?? 1.0;
    final B = double.tryParse(_bCtrls[currentKey]!.text) ?? 0.0;

    return DefaultTabController(
      length: sensorKeys.length,
      child: Column(
        children: [
          Material(
            color: Colors.black,
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              tabs: [for (final k in sensorKeys) Tab(text: k)],
              onTap: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  ElevatedButton(
                    onPressed: _getCoeffs,
                    child: const Text("Récupérer les coefficients"),
                  ),
                  const SizedBox(height: 20),
                  _coeffEditors(currentKey),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _sendCoeffs,
                    child: const Text("Envoyer la configuration"),
                  ),
                  const SizedBox(height: 20),
                  Text("Valeur brute: ${valeurBrute.toStringAsFixed(3)}",
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text("Valeur calibrée = ( Valeur brute * A ) + B",
                      style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 8),
                  Text("A = ${A.toStringAsFixed(3)}", style: const TextStyle(color: Colors.white60)),
                  Text("B = ${B.toStringAsFixed(3)}", style: const TextStyle(color: Colors.white60)),
                  const SizedBox(height: 8),
                  Text("Valeur calibrée: ${valeurCalib.toStringAsFixed(3)}",
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coeffEditors(String key) {
    return Row(
      children: [
        _numField("A", _aCtrls[key]!),
        const SizedBox(width: 12),
        _numField("B", _bCtrls[key]!),
      ],
    );
  }

  Widget _numField(String label, TextEditingController c) {
    return Expanded(
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      ),
    );
  }
}
