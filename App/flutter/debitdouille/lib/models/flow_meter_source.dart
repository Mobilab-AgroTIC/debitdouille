/// Source de données pour un débitmètre
enum FlowMeterSource {
  auto,   // Automatique : affiche pulse si disponible, sinon 4-20mA
  pulse,  // Forcer l'affichage des valeurs pulse
  mA420,  // Forcer l'affichage des valeurs 4-20mA
}

/// Configuration des sources pour les 4 débitmètres
class FlowMeterConfig {
  final FlowMeterSource dg1;
  final FlowMeterSource dd1;
  final FlowMeterSource dg2;
  final FlowMeterSource dd2;
  final FlowMeterSource dg3;
  final FlowMeterSource dd3;
  final FlowMeterSource dg4;
  final FlowMeterSource dd4;

  const FlowMeterConfig({
    this.dg1 = FlowMeterSource.auto,
    this.dd1 = FlowMeterSource.auto,
    this.dg2 = FlowMeterSource.auto,
    this.dd2 = FlowMeterSource.auto,
    this.dg3 = FlowMeterSource.auto,
    this.dd3 = FlowMeterSource.auto,
    this.dg4 = FlowMeterSource.auto,
    this.dd4 = FlowMeterSource.auto,
  });

  FlowMeterSource getSource(String key) {
    switch (key) {
      case 'DG1': return dg1;
      case 'DD1': return dd1;
      case 'DG2': return dg2;
      case 'DD2': return dd2;
      case 'DG3': return dg3;
      case 'DD3': return dd3;
      case 'DG4': return dg4;
      case 'DD4': return dd4;
      default: return FlowMeterSource.auto;
    }
  }

  FlowMeterConfig copyWith({
    FlowMeterSource? dg1,
    FlowMeterSource? dd1,
    FlowMeterSource? dg2,
    FlowMeterSource? dd2,
    FlowMeterSource? dg3,
    FlowMeterSource? dd3,
    FlowMeterSource? dg4,
    FlowMeterSource? dd4,
  }) {
    return FlowMeterConfig(
      dg1: dg1 ?? this.dg1,
      dd1: dd1 ?? this.dd1,
      dg2: dg2 ?? this.dg2,
      dd2: dd2 ?? this.dd2,
      dg3: dg3 ?? this.dg3,
      dd3: dd3 ?? this.dd3,
      dg4: dg4 ?? this.dg4,
      dd4: dd4 ?? this.dd4,
    );
  }

  Map<String, String> toJson() => {
    'DG1': dg1.name,
    'DD1': dd1.name,
    'DG2': dg2.name,
    'DD2': dd2.name,
    'DG3': dg3.name,
    'DD3': dd3.name,
    'DG4': dg4.name,
    'DD4': dd4.name,
  };

  factory FlowMeterConfig.fromJson(Map<String, dynamic> json) {
    FlowMeterSource parseSource(String? val) {
      switch (val) {
        case 'pulse': return FlowMeterSource.pulse;
        case 'mA420': return FlowMeterSource.mA420;
        default: return FlowMeterSource.auto;
      }
    }

    return FlowMeterConfig(
      dg1: parseSource(json['DG1']),
      dd1: parseSource(json['DD1']),
      dg2: parseSource(json['DG2']),
      dd2: parseSource(json['DD2']),
      dg3: parseSource(json['DG3']),
      dd3: parseSource(json['DD4']),
      dg4: parseSource(json['DG4']),
      dd4: parseSource(json['DD4']),
    );
  }
}
