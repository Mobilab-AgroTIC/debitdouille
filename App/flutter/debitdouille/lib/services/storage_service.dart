import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import 'dart:convert';

class StorageService {
  static const String _settingsKey = 'settings_debitdouille';

  Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_settingsKey, json.encode(settings.toMap()));
  }

  Future<SettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);
    if (jsonString == null) {
      // Valeurs par défaut
      return SettingsModel(numberOfFlowMeters: 2, showSimulateButton: false);
    }
    final Map<String, dynamic> map = json.decode(jsonString);
    return SettingsModel.fromMap(map);
  }
}
