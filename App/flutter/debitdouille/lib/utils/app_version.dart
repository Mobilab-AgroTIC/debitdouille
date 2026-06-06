import 'package:package_info_plus/package_info_plus.dart';

/// Informations de version de l'application DébitDouille.
///
/// La version est lue automatiquement depuis le `pubspec.yaml` (champ
/// `version: x.y.z+buildNumber`) via package_info_plus — il n'y a donc plus
/// rien à mettre à jour à la main ici : le bump du pubspec suffit, et l'écran
/// "À propos" affiche toujours la version réellement installée.
///
/// Appeler [AppVersion.init] une fois au démarrage (avant runApp).
class AppVersion {
  static String _version = '...';
  static String _buildNumber = '';

  /// Date de compilation, injectée au build via :
  ///   flutter build ... --dart-define=BUILD_DATE=2026-06-06T14:30
  /// Vide si non injectée (ex. lancement via `flutter run`).
  static const String _buildDate =
      String.fromEnvironment('BUILD_DATE', defaultValue: '');

  /// Charge les infos de version du package. À appeler au démarrage.
  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    _version = info.version;          // ex. "2.0.2" (= version du pubspec)
    _buildNumber = info.buildNumber;  // ex. "3"     (= versionCode du pubspec)
  }

  /// Version sémantique, ex. "2.0.2".
  static String get version => _version;

  /// Numéro de build (versionCode), ex. "3".
  static String get buildNumber => _buildNumber;

  /// Date de build formatée (jj/mm/aaaa hh:mm) ou '' si non injectée.
  static String get buildDate {
    if (_buildDate.isEmpty) return '';
    final d = DateTime.tryParse(_buildDate);
    if (d == null) return _buildDate;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  /// Version complète "2.0.2+3".
  static String get fullVersion =>
      _buildNumber.isEmpty ? _version : '$_version+$_buildNumber';

  /// Libellé complet pour l'affichage, ex.
  /// "2.0.2 (build 3) — 06/06/2026 14:30" (date omise si absente).
  static String get displayVersion {
    final base =
        _buildNumber.isEmpty ? _version : '$_version (build $_buildNumber)';
    final date = buildDate;
    return date.isEmpty ? base : '$base — $date';
  }
}
