class SettingsModel {
  final int numberOfFlowMeters; // 2, 4 ou 6
  final bool showSimulateButton;

  SettingsModel({
    required this.numberOfFlowMeters,
    required this.showSimulateButton,
  });

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      numberOfFlowMeters: map['numberOfFlowMeters'] as int,
      showSimulateButton: map['showSimulateButton'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numberOfFlowMeters': numberOfFlowMeters,
      'showSimulateButton': showSimulateButton,
    };
  }
}
