import '../models/capteur_data.dart';

/// Filtre de moyenne glissante appliqué aux trames capteur.
///
/// Lisse les valeurs numériques (pression, vitesse et les 8 débits, toutes
/// sources confondues) sur les [window] dernières trames afin de stabiliser
/// l'affichage. Les champs non numériques / de debug (ID, P_raw_mV) ne sont
/// pas lissés : on conserve la valeur de la dernière trame.
///
/// On lisse les valeurs *brutes* (mA et pulse séparément), avant la résolution
/// de la source dans [CapteurData.getValue], pour qu'un changement de source
/// (pulse / 4-20mA / auto) ne fausse pas la moyenne.
class MovingAverageFilter {
  MovingAverageFilter({this.window = 5});

  /// Nombre de trames prises en compte dans la moyenne.
  final int window;

  // Un buffer circulaire par grandeur lissée.
  final _RingBuffer _p = _RingBuffer();
  final _RingBuffer _v = _RingBuffer();
  final List<_RingBuffer> _dgMa = List.generate(4, (_) => _RingBuffer());
  final List<_RingBuffer> _ddMa = List.generate(4, (_) => _RingBuffer());
  final List<_RingBuffer> _dgPulse = List.generate(4, (_) => _RingBuffer());
  final List<_RingBuffer> _ddPulse = List.generate(4, (_) => _RingBuffer());

  /// Vide tous les buffers (à appeler à la déconnexion / reset).
  void reset() {
    _p.clear();
    _v.clear();
    for (final b in _dgMa) {
      b.clear();
    }
    for (final b in _ddMa) {
      b.clear();
    }
    for (final b in _dgPulse) {
      b.clear();
    }
    for (final b in _ddPulse) {
      b.clear();
    }
  }

  /// Ajoute la trame brute [raw] et retourne une trame avec les valeurs lissées.
  CapteurData process(CapteurData raw) {
    return CapteurData(
      ID: raw.ID,
      P: _p.push(raw.P, window),
      V: _v.push(raw.V, window),
      DG_mA: List<double>.generate(4, (i) => _dgMa[i].push(raw.DG_mA[i], window)),
      DD_mA: List<double>.generate(4, (i) => _ddMa[i].push(raw.DD_mA[i], window)),
      DG_pulse:
          List<double>.generate(4, (i) => _dgPulse[i].push(raw.DG_pulse[i], window)),
      DD_pulse:
          List<double>.generate(4, (i) => _ddPulse[i].push(raw.DD_pulse[i], window)),
      P_raw_mV: raw.P_raw_mV,
    );
  }
}

/// Petit buffer circulaire qui retourne la moyenne courante après insertion.
class _RingBuffer {
  final List<double> _values = [];

  void clear() => _values.clear();

  /// Insère [value], borne la taille à [window] et renvoie la moyenne.
  double push(double value, int window) {
    _values.add(value);
    while (_values.length > window) {
      _values.removeAt(0);
    }
    if (_values.isEmpty) return value;
    final sum = _values.fold<double>(0, (a, b) => a + b);
    return sum / _values.length;
  }
}
