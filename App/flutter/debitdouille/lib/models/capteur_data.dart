import 'flow_meter_source.dart';

class CapteurData {
  final int ID; // Numéro séquentiel de la trame
  final double P; // bars
  final double V; // km/h

  // Valeurs 4-20mA (DG1, DD1, DG2, DD2, DG3, DD3, DG4, DD4)
  final List<double> DG_mA;
  final List<double> DD_mA;

  // Valeurs pulse (DG1p, DD1p, DG2p, DD2p, DG3p, DD3p, DG4p, DD4p)
  final List<double> DG_pulse;
  final List<double> DD_pulse;

  final int
  P_raw_mV; // Tension brute lue par l'ADC en millivolts (pour debug/calibration)

  CapteurData({
    required this.ID,
    required this.P,
    required this.V,
    required this.DG_mA,
    required this.DD_mA,
    required this.DG_pulse,
    required this.DD_pulse,
    this.P_raw_mV = 0,
  });

  factory CapteurData.zero() => CapteurData(
    ID: 0,
    P: 0,
    V: 0,
    DG_mA: [0, 0, 0, 0],
    DD_mA: [0, 0, 0, 0],
    DG_pulse: [0, 0, 0, 0],
    DD_pulse: [0, 0, 0, 0],
  );

  factory CapteurData.fromJson(Map<String, dynamic> j) {
    double d(dynamic x) =>
        (x is num) ? x.toDouble() : double.tryParse("$x") ?? 0.0;
    int i(dynamic x) => (x is int) ? x : int.tryParse("$x") ?? 0;
    return CapteurData(
      ID: i(j["ID"]),
      P: d(j["P"]),
      V: d(j["V"]),
      // Valeurs 4-20mA
      DG_mA: List<double>.generate(4, (i) => d(j["DG${i + 1}"])),
      DD_mA: List<double>.generate(4, (i) => d(j["DD${i + 1}"])),
      // Valeurs pulse
      DG_pulse: List<double>.generate(4, (i) => d(j["DG${i + 1}p"])),
      DD_pulse: List<double>.generate(4, (i) => d(j["DD${i + 1}p"])),
      P_raw_mV: i(j["P_raw_mV"]),
    );
  }

  /// Récupère la valeur d'un débitmètre selon le mode configuré
  /// key format: "DG1", "DD1", "DG2", etc.
  double getValue(String key, FlowMeterSource source) {
    final isLeft = key.startsWith('DG');
    final index = int.parse(key.substring(2)) - 1;

    final mA = isLeft ? DG_mA[index] : DD_mA[index];
    final pulse = isLeft ? DG_pulse[index] : DD_pulse[index];

    switch (source) {
      case FlowMeterSource.auto:
        // En mode auto : priorité au 4-20mA si > 0, sinon pulse
        if (mA > 0) return mA;
        return pulse;
      case FlowMeterSource.pulse:
        return pulse;
      case FlowMeterSource.mA420:
        return mA;
    }
  }

  /// Pour affichage debug : valeur pulse uniquement
  double getPulseValue(String key) {
    final isLeft = key.startsWith('DG');
    final index = int.parse(key.substring(2)) - 1;
    return isLeft ? DG_pulse[index] : DD_pulse[index];
  }

  /// Pour affichage debug : valeur 4-20mA uniquement
  double get4_20mAValue(String key) {
    final isLeft = key.startsWith('DG');
    final index = int.parse(key.substring(2)) - 1;
    return isLeft ? DG_mA[index] : DD_mA[index];
  }

  Map<String, dynamic> toJson() => {
    "ID": ID,
    "P": P,
    "V": V,
    for (int i = 0; i < 4; i++) "DG${i + 1}": DG_mA[i],
    for (int i = 0; i < 4; i++) "DD${i + 1}": DD_mA[i],
    for (int i = 0; i < 4; i++) "DG${i + 1}p": DG_pulse[i],
    for (int i = 0; i < 4; i++) "DD${i + 1}p": DD_pulse[i],
  };
}
