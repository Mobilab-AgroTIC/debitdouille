import 'package:flutter/material.dart';
import '../models/settings_model.dart';
import '../services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  SettingsModel _currentSettings = SettingsModel(
    numberOfFlowMeters: 2,
    showSimulateButton: false,
  );

  SettingsModel get currentSettings => _currentSettings;

  Future<void> loadInitial() async {
    _currentSettings = await _storage.loadSettings();
    notifyListeners();
  }

  Future<void> updateNumberOfFlowMeters(int n) async {
    _currentSettings = SettingsModel(
      numberOfFlowMeters: n,
      showSimulateButton: _currentSettings.showSimulateButton,
    );
    await _storage.saveSettings(_currentSettings);
    notifyListeners();
  }

  Future<void> updateShowSimulateButton(bool value) async {
    _currentSettings = SettingsModel(
      numberOfFlowMeters: _currentSettings.numberOfFlowMeters,
      showSimulateButton: value,
    );
    await _storage.saveSettings(_currentSettings);
    notifyListeners();
  }
}
