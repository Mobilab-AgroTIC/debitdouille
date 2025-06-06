extension DoubleExtensions on double {
  String toTwoDecimalString() => toStringAsFixed(2);
}

extension JsonExtensions on Map<String, dynamic> {
  T? getAs<T>(String key) => this[key] as T?;
}
