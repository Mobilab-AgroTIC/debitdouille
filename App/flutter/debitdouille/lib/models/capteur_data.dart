class CapteurData {
  final double P; // bars
  final double V; // km/h
  final List<double> DG; // 4 valeurs max
  final List<double> DD; // 4 valeurs max

  CapteurData({
    required this.P,
    required this.V,
    required this.DG,
    required this.DD,
  });

  factory CapteurData.zero() => CapteurData(P: 0, V: 0, DG: [0,0,0,0], DD: [0,0,0,0]);

  factory CapteurData.fromJson(Map<String, dynamic> j) {
    double _d(dynamic x) => (x is num) ? x.toDouble() : double.tryParse("$x") ?? 0.0;
    return CapteurData(
      P: _d(j["P"]),
      V: _d(j["V"]),
      DG: List<double>.generate(4, (i) => _d(j["DG${i+1}"])),
      DD: List<double>.generate(4, (i) => _d(j["DD${i+1}"])),
    );
  }

  Map<String, dynamic> toJson() => {
    "P": P, "V": V,
    for (int i=0;i<4;i++) "DG${i+1}": DG[i],
    for (int i=0;i<4;i++) "DD${i+1}": DD[i],
  };
}
