class FirmwareInfo {
  final String version;
  final String buildDate;
  final String buildTime;
  final String espModel;

  FirmwareInfo({
    required this.version,
    required this.buildDate,
    required this.buildTime,
    required this.espModel,
  });

  factory FirmwareInfo.empty() => FirmwareInfo(
    version: "Non disponible",
    buildDate: "N/A",
    buildTime: "N/A",
    espModel: "N/A",
  );

  factory FirmwareInfo.fromJson(Map<String, dynamic> json) {
    return FirmwareInfo(
      version: json['fw_version'] ?? 'N/A',
      buildDate: json['build_date'] ?? 'N/A',
      buildTime: json['build_time'] ?? 'N/A',
      espModel: json['esp_model'] ?? 'N/A',
    );
  }

  String get fullBuildDateTime => "$buildDate à $buildTime";
}
