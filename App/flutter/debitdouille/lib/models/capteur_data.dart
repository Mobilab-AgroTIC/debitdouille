class CapteurData {
  final int ID; // Numéro séquentiel de la trame
  final double P; // bars
  final double V; // km/h
  final List<double> DG; // 4 valeurs max
  final List<double> DD; // 4 valeurs max

  CapteurData({
    required this.ID,
    required this.P,
    required this.V,
    required this.DG,
    required this.DD,
  });

  factory CapteurData.zero() => CapteurData(ID: 0, P: 0, V: 0, DG: [0,0,0,0], DD: [0,0,0,0]);

  factory CapteurData.fromJson(Map<String, dynamic> j) {
    double _d(dynamic x) => (x is num) ? x.toDouble() : double.tryParse("$x") ?? 0.0;
    int _i(dynamic x) => (x is int) ? x : int.tryParse("$x") ?? 0;
    return CapteurData(
      ID: _i(j["ID"]),
      P: _d(j["P"]),
      V: _d(j["V"]),
      DG: List<double>.generate(4, (i) => _d(j["DG${i+1}"])),
      DD: List<double>.generate(4, (i) => _d(j["DD${i+1}"])),
    );
  }

  Map<String, dynamic> toJson() => {
    "ID": ID,
    "P": P, "V": V,
    for (int i=0;i<4;i++) "DG${i+1}": DG[i],
    for (int i=0;i<4;i++) "DD${i+1}": DD[i],
  };
}
