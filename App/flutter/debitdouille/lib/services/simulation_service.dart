import 'dart:math';
import 'dart:convert';

class SimulationService {
  final _rng = Random();

  String generateJson({int pairs = 1}) {
    double p() => (_rng.nextDouble() * 8) + 0.2;
    double v() => (_rng.nextDouble() * 25);
    Map<String, dynamic> m = {
      "P": p().toStringAsFixed(2),
      "V": v().toStringAsFixed(2),
      "ID": _rng.nextInt(10000),
    };
    for (int i=1;i<=4;i++) {
      final valG_mA = i <= pairs ? p() : 0.0;
      final valD_mA = i <= pairs ? p() : 0.0;
      final valG_pulse = i <= pairs ? p() : 0.0;
      final valD_pulse = i <= pairs ? p() : 0.0;
      // Valeurs 4-20mA
      m["DG$i"] = valG_mA.toStringAsFixed(2);
      m["DD$i"] = valD_mA.toStringAsFixed(2);
      // Valeurs pulse
      m["DG${i}p"] = valG_pulse.toStringAsFixed(2);
      m["DD${i}p"] = valD_pulse.toStringAsFixed(2);
    }
    return jsonEncode(m);
  }
}
