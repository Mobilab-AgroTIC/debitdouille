import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flow_meter_source.dart';

class FlowMeterConfigService {
  static const String _configKey = 'flow_meter_config';

  /// Charge la configuration sauvegardée (ou retourne config par défaut)
  Future<FlowMeterConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_configKey);

    if (jsonString == null) {
      return const FlowMeterConfig(); // Config par défaut (tout en auto)
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return FlowMeterConfig.fromJson(json);
    } catch (e) {
      print('⛔ Erreur chargement config débitmètres: $e');
      return const FlowMeterConfig();
    }
  }

  /// Sauvegarde la configuration
  Future<void> saveConfig(FlowMeterConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(config.toJson());
    await prefs.setString(_configKey, jsonString);
    print('✅ Configuration débitmètres sauvegardée');
  }

  /// Réinitialise la configuration (tout en auto)
  Future<void> resetConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
    print('🔄 Configuration débitmètres réinitialisée');
  }
}
