import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppPage { home, bluetooth, calibration, settings }

class SettingsProvider with ChangeNotifier {
  int pairs = 1;               // 1..4
  bool showDebug = false;      // afficher trame JSON en bas
  bool showSimButton = false;  // afficher bouton simulation
  AppPage page = AppPage.home;

  // ✅ Nouvelle préférence : facteur d'échelle des polices
  double fontScale = 1.0;      // ex. 0.8..2.0

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    pairs = p.getInt("pairs") ?? 1;
    showDebug = p.getBool("debug") ?? false;
    showSimButton = p.getBool("simButton") ?? false;
    fontScale = p.getDouble("fontScale") ?? 1.0;
    notifyListeners();
  }

  Future<void> setPairs(int v) async {
    pairs = v.clamp(1, 4);
    final p = await SharedPreferences.getInstance();
    await p.setInt("pairs", pairs);
    notifyListeners();
  }

  Future<void> setShowDebug(bool v) async {
    showDebug = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool("debug", v);
    notifyListeners();
  }

  Future<void> setShowSimButton(bool v) async {
    showSimButton = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool("simButton", v);
    notifyListeners();
  }

  // ✅ Setter pour la taille des polices (avec borne de sécurité)
  Future<void> setFontScale(double v) async {
    // Bornes souples pour éviter des tailles illisibles
    fontScale = v.clamp(0.6, 2.0);
    final p = await SharedPreferences.getInstance();
    await p.setDouble("fontScale", fontScale);
    notifyListeners();
  }

  void go(AppPage p) {
    page = p;
    notifyListeners();
  }
}
