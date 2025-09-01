import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/capteur_data.dart';
import '../services/ble_service.dart';
import '../services/simulation_service.dart';
import '../utils/constants.dart';

class DataProvider with ChangeNotifier {
  final BleService ble;
  final SimulationService sim;

  CapteurData data = CapteurData.zero();
  String? lastJson;                   // trame brute la plus récente
  DateTime? lastTick;                 // dernière réception
  bool get isAlive =>
      lastTick != null && DateTime.now().difference(lastTick!) <= tickDuration;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothDevice? _connectedDevice;

  StreamSubscription<String>? _bleSub;

  // 🔔 Timer pour forcer un rafraîchissement de l'UI à l'expiration du délai vert
  Timer? _aliveTimer;

  DataProvider({required this.ble, required this.sim});

  Future<List<BluetoothDevice>> scan() => ble.scanDevices();

  Future<void> connect(BluetoothDevice d) async {
    await ble.connectTo(d);
    _connectedDevice = d;

    await _bleSub?.cancel();
    _bleSub = ble.jsonStream.listen(_onJson, onError: (e, st) {
      // En cas d’erreur de stream, on notifie pour que l’UI réagisse (potentielle perte)
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> disconnect() async {
    await ble.disconnect();
    _connectedDevice = null;

    await _bleSub?.cancel();
    _bleSub = null;

    // On force l’UI à recalculer isAlive => rouge immédiat
    _aliveTimer?.cancel();
    _aliveTimer = null;
    lastTick = null;
    notifyListeners();
  }

  void _onJson(String s) {
    print("📩 Trame reçue BLE : $s");
    lastJson = s;

    try {
      final Map<String, dynamic> j = jsonDecode(s);
      print("✅ JSON décodé avec succès : $j");
      data = CapteurData.fromJson(j);
      lastTick = DateTime.now();

      // Passe immédiatement au vert
      notifyListeners();

      // Programme le retour au rouge après tickDuration
      _scheduleAliveRefresh();

    } catch (e) {
      print("⛔ Erreur JSON : $e");
      // Même en cas de JSON invalide, on considère que "quelque chose" est arrivé
      // pour ne pas rester bloqué au rouge si le lien est bien vivant.
      lastTick = DateTime.now();

      notifyListeners();
      _scheduleAliveRefresh();
    }
  }

  void _scheduleAliveRefresh() {
    // Annule l'ancien timer et reprogramme un nouveau
    _aliveTimer?.cancel();
    _aliveTimer = Timer(
      // + petit delta pour être sûr de dépasser strictement la condition (<=)
      tickDuration + const Duration(milliseconds: 30),
      () {
        // Re-notifie pour recalculer isAlive et repasser au rouge si nécessaire
        notifyListeners();
      },
    );
  }

  // Simulation ponctuelle (bouton)
  void pushSimulatedFrame(int pairs) {
    final s = sim.generateJson(pairs: pairs);
    _onJson(s);
  }

  // Calibration – proxies
  Future<void> requestCoefficients() => ble.requestCoefficients();
  Future<void> sendUpdatedCoefficients(Map<String, Map<String, double>> coeff) =>
      ble.sendUpdatedCoefficients(coeff);

  @override
  void dispose() {
    _aliveTimer?.cancel();
    _bleSub?.cancel();
    super.dispose();
  }
}
