extension IntHelper on int {
  static const int max = 9007199254740991;
}

extension NullableIntHelper on int? {
  int? add(int? value) {
    if (this == null || value == null) return null;
    return this! + value;
  }

  int? subtract(int? value) {
    if (this == null || value == null) return null;
    return this! - value;
  }
}

extension DoubleHelper on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

extension NumHelper on num {
  bool inRange(num min, num max) => this >= min && this <= max;
}
