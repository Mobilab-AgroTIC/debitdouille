/// Informations de version de l'application DébitDouille
///
/// - Version sémantique : major.minor.patch pour les releases officielles
/// - Build number : timestamp de compilation pour identifier chaque build
class AppVersion {
  // Version sémantique de l'application
  static const String major = '2';
  static const String minor = '0';
  static const String patch = '2';

  // Numéro de build (format: YYYYMMDDHHmm)
  // À mettre à jour manuellement avant chaque compilation importante
  // ou automatiquement via un script de build
  static const String buildNumber = '202606051000'; // 05/06/2026 10:00

  // Version complète
  static String get version => '$major.$minor.$patch';
  static String get fullVersion => '$version+$buildNumber';

  // Description pour l'affichage
  static String get displayVersion => 'v$version (build $buildNumber)';

  // Date de build formatée
  static String get buildDate {
    if (buildNumber.length >= 8) {
      final year = buildNumber.substring(0, 4);
      final month = buildNumber.substring(4, 6);
      final day = buildNumber.substring(6, 8);
      return '$day/$month/$year';
    }
    return 'N/A';
  }

  // Heure de build formatée
  static String get buildTime {
    if (buildNumber.length >= 12) {
      final hour = buildNumber.substring(8, 10);
      final minute = buildNumber.substring(10, 12);
      return '$hour:$minute';
    }
    return 'N/A';
  }
}
