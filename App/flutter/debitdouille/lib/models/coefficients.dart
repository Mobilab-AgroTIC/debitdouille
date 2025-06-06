class Coefficients {
  final double aPressure;
  final double bPressure;
  final double aD1;
  final double bD1;
  final double aD2;
  final double bD2;
  final double aD3;
  final double bD3;

  Coefficients({
    required this.aPressure,
    required this.bPressure,
    required this.aD1,
    required this.bD1,
    required this.aD2,
    required this.bD2,
    required this.aD3,
    required this.bD3,
  });

  factory Coefficients.fromJson(Map<String, dynamic> json) {
    // TODO : parser JSON « coef » retourné par l’objet
    return Coefficients(
      aPressure: (json['aPressure'] as num).toDouble(),
      bPressure: (json['bPressure'] as num).toDouble(),
      aD1: (json['aD1'] as num).toDouble(),
      bD1: (json['bD1'] as num).toDouble(),
      aD2: (json['aD2'] as num).toDouble(),
      bD2: (json['bD2'] as num).toDouble(),
      aD3: (json['aD3'] as num).toDouble(),
      bD3: (json['bD3'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    // TODO : sérialiser en JSON pour envoyer à l’objet
    return {
      'aPressure': aPressure,
      'bPressure': bPressure,
      'aD1': aD1,
      'bD1': bD1,
      'aD2': aD2,
      'bD2': bD2,
      'aD3': aD3,
      'bD3': bD3,
    };
  }
}
