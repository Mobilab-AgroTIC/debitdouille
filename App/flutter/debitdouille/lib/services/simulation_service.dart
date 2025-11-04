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
    };
    for (int i=1;i<=4;i++) {
      final valG = i <= pairs ? p() : 0.0;
      final valD = i <= pairs ? p() : 0.0;
      m["DG$i"] = valG.toStringAsFixed(2);
      m["DD$i"] = valD.toStringAsFixed(2);
    }
    return jsonEncode(m);
  }
}
