import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../models/flow_meter_source.dart';
import '../utils/constants.dart';

const sensorKeys = ["P", "DG1", "DD1", "DG2", "DD2", "DG3", "DD3", "DG4", "DD4"];

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> with TickerProviderStateMixin {
  late TabController _tab;
  // Pour la pression : A et B
  final Map<String, TextEditingController> _aCtrls = {};
  final Map<String, TextEditingController> _bCtrls = {};
  // Pour les débitmètres : PPL et flow
  final Map<String, TextEditingController> _pplCtrls = {};
  final Map<String, TextEditingController> _flowCtrls = {};
  double valeurCalib = 0.0;
  double valeurBrute = 0.0;

  // Configuration capteur de pression
  bool _pressureSensorIs3Wire = true; // true = 3 fils (Gravity analogique), false = 2 fils (4-20mA)
  final TextEditingController _pressureMaxBarCtrl = TextEditingController();
  final TextEditingController _pressureVoltageMinCtrl = TextEditingController();
  final TextEditingController _pressureVoltageMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: sensorKeys.length, vsync: this);
    for (final k in sensorKeys) {
      if (k == "P") {
        // Pression : A et B
        _aCtrls[k] = TextEditingController();
        _bCtrls[k] = TextEditingController();
      } else {
        // Débitmètres : PPL et flow
        _pplCtrls[k] = TextEditingController();
        _flowCtrls[k] = TextEditingController();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _getCoeffs());
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in _aCtrls.values) { c.dispose(); }
    for (final c in _bCtrls.values) { c.dispose(); }
    for (final c in _pplCtrls.values) { c.dispose(); }
    for (final c in _flowCtrls.values) { c.dispose(); }
    _pressureMaxBarCtrl.dispose();
    _pressureVoltageMinCtrl.dispose();
    _pressureVoltageMaxCtrl.dispose();
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

    // Paramètres globaux du capteur de pression
    if (j["pressureSensorType"] != null) {
      _pressureSensorIs3Wire = (j["pressureSensorType"] as int) == 0; // 0 = 3 fils, 1 = 2 fils
    }
    if (j["pressureMaxBar"] != null) {
      _pressureMaxBarCtrl.text = (j["pressureMaxBar"] as num).toStringAsFixed(1);
    }
    if (j["pressureVoltageMin"] != null) {
      _pressureVoltageMinCtrl.text = (j["pressureVoltageMin"] as num).toStringAsFixed(2);
    }
    if (j["pressureVoltageMax"] != null) {
      _pressureVoltageMaxCtrl.text = (j["pressureVoltageMax"] as num).toStringAsFixed(2);
    }

    for (final k in sensorKeys) {
      if (coeff[k] is Map) {
        if (k == "P") {
          // Pression : A et B
          final A = (coeff[k]["A"] as num?)?.toDouble() ?? 1.0;
          final B = (coeff[k]["B"] as num?)?.toDouble() ?? 0.0;
          _aCtrls[k]!.text = A.toStringAsFixed(3);
          _bCtrls[k]!.text = B.toStringAsFixed(3);
        } else {
          // Débitmètres : PPL et flow
          final ppl = (coeff[k]["PPL"] as num?)?.toDouble() ?? 1000.0;
          final flow = (coeff[k]["flow"] as num?)?.toDouble() ?? 20.0;
          _pplCtrls[k]!.text = ppl.toStringAsFixed(0);
          _flowCtrls[k]!.text = flow.toStringAsFixed(1);
        }
      }
    }
    if (mounted) setState(() {});
  } catch (e) {
    debugPrint("⛔ Erreur parsing coeff: $e");
  }
}


  Future<void> _sendCoeffs() async {
    final Map<String, dynamic> payload = {};

    // Paramètres globaux du capteur de pression
    payload["pressureSensorType"] = {
      "value": _pressureSensorIs3Wire ? 0 : 1
    };
    payload["pressureMaxBar"] = double.tryParse(_pressureMaxBarCtrl.text) ?? 16.0;
    payload["pressureVoltageMin"] = double.tryParse(_pressureVoltageMinCtrl.text) ?? 0.5;
    payload["pressureVoltageMax"] = double.tryParse(_pressureVoltageMaxCtrl.text) ?? 4.5;

    for (final k in sensorKeys) {
      if (k == "P") {
        // Pression : A et B
        payload[k] = {
          "A": double.tryParse(_aCtrls[k]!.text) ?? 1.0,
          "B": double.tryParse(_bCtrls[k]!.text) ?? 0.0,
        };
      } else {
        // Débitmètres : PPL et flow
        final ppl = double.tryParse(_pplCtrls[k]!.text) ?? 1000.0;
        final flow = double.tryParse(_flowCtrls[k]!.text) ?? 20.0;
        debugPrint("🔍 $k: PPL='${_pplCtrls[k]!.text}' ($ppl), flow='${_flowCtrls[k]!.text}' ($flow)");
        payload[k] = {
          "PPL": ppl,
          "flow": flow,
        };
      }
    }
    debugPrint("📤 Payload envoyé: ${jsonEncode(payload)}");
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
      if (k == "P") {
        return dp.data.P;
      } else {
        // Pour les débitmètres, utiliser getValue avec la config
        final source = dp.flowMeterConfig.getSource(k);
        return dp.data.getValue(k, source);
      }
    }

    final currentKey = sensorKeys[_tab.index];

    // Calculer les valeurs uniquement pour la pression
    if (currentKey == "P") {
      _recalc(currentCalib(), currentKey);
    }

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
                    child: const Text("Envoyer les coefficients"),
                  ),
                  const SizedBox(height: 20),
                  // Affichage des infos uniquement pour la pression
                  if (currentKey == "P") ...[
                    Text("Valeur brute = ${valeurBrute.toStringAsFixed(3)}",
                        style: const TextStyle(color: Colors.white60)),
                    const SizedBox(height: 8),
                    const Text("Valeur calibrée = ( Valeur brute * A ) + B",
                        style: TextStyle(color: Colors.white60)),
                    const SizedBox(height: 8),
                    Text("A = ${_aCtrls[currentKey]!.text}", style: const TextStyle(color: Colors.white60)),
                    Text("B = ${_bCtrls[currentKey]!.text}", style: const TextStyle(color: Colors.white60)),
                    const SizedBox(height: 8),
                    Text("Valeur calibrée = ${valeurCalib.toStringAsFixed(3)}",
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text("Tension ADC = ${dp.data.P_raw_mV} mV",
                        style: const TextStyle(color: Colors.white60)),
                  ] else ...[
                    // Affichage pour les débitmètres
                    Text("Valeur affichée: ${currentCalib().toStringAsFixed(2)} L/min",
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    // Affichage debug des 2 sources
                    Text("Valeur pulse: ${dp.data.getPulseValue(currentKey).toStringAsFixed(2)} L/min",
                        style: const TextStyle(color: Colors.white60)),
                    Text("Valeur 4-20mA: ${dp.data.get4_20mAValue(currentKey).toStringAsFixed(2)} L/min",
                        style: const TextStyle(color: Colors.white60)),
                    const SizedBox(height: 8),
                    const Text("PPL = Impulsions par litre",
                        style: TextStyle(color: Colors.white60)),
                    const Text("Max Flow = Débit maximum en L/min",
                        style: TextStyle(color: Colors.white60)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coeffEditors(String key) {
    if (key == "P") {
      // Pression : A et B + configuration capteur
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Type de capteur - Radio buttons côte à côte
          const Text("Type de capteur", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _pressureSensorIs3Wire = true),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _pressureSensorIs3Wire,
                        onChanged: (val) => setState(() => _pressureSensorIs3Wire = val ?? true),
                        activeColor: Colors.greenAccent,
                      ),
                      const Expanded(
                        child: Text("3 fils (0.5-4.5V)",
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _pressureSensorIs3Wire = false),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: _pressureSensorIs3Wire,
                        onChanged: (val) => setState(() => _pressureSensorIs3Wire = val ?? true),
                        activeColor: Colors.greenAccent,
                      ),
                      const Expanded(
                        child: Text("2 fils (4-20mA)",
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ligne : Pression max + Tensions min/max (si 3 fils)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pressureMaxBarCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Pmax (bar)",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                ),
              ),
              if (_pressureSensorIs3Wire) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _pressureVoltageMinCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Vmin (V)",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _pressureVoltageMaxCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Vmax (V)",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Coefficients A et B
          const Text("Coefficients de régression linéaire", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              _numField("A", _aCtrls[key]!),
              const SizedBox(width: 12),
              _numField("B", _bCtrls[key]!),
            ],
          ),
        ],
      );
    } else {
      // Débitmètres : Source + PPL et Max Flow
      final dp = context.watch<DataProvider>();
      final currentSource = dp.flowMeterConfig.getSource(key);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sélection de source
          const Text("Source de données", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => dp.updateFlowMeterSource(key, FlowMeterSource.auto),
                  child: Row(
                    children: [
                      Radio<FlowMeterSource>(
                        value: FlowMeterSource.auto,
                        groupValue: currentSource,
                        onChanged: (val) => dp.updateFlowMeterSource(key, val ?? FlowMeterSource.auto),
                        activeColor: Colors.greenAccent,
                      ),
                      const Expanded(
                        child: Text("Auto", style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => dp.updateFlowMeterSource(key, FlowMeterSource.pulse),
                  child: Row(
                    children: [
                      Radio<FlowMeterSource>(
                        value: FlowMeterSource.pulse,
                        groupValue: currentSource,
                        onChanged: (val) => dp.updateFlowMeterSource(key, val ?? FlowMeterSource.auto),
                        activeColor: Colors.greenAccent,
                      ),
                      const Expanded(
                        child: Text("Pulse", style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => dp.updateFlowMeterSource(key, FlowMeterSource.mA420),
                  child: Row(
                    children: [
                      Radio<FlowMeterSource>(
                        value: FlowMeterSource.mA420,
                        groupValue: currentSource,
                        onChanged: (val) => dp.updateFlowMeterSource(key, val ?? FlowMeterSource.auto),
                        activeColor: Colors.greenAccent,
                      ),
                      const Expanded(
                        child: Text("4-20mA", style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Coefficients PPL et Max Flow
          Row(
            children: [
              _numField("PPL (pulse/L)", _pplCtrls[key]!),
              const SizedBox(width: 12),
              _numField("Max Flow (L/min)", _flowCtrls[key]!),
            ],
          ),
        ],
      );
    }
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
