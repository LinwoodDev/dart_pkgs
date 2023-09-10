import 'package:flutter/material.dart';

bool isDarkColor(Color color) {
  // Berechne die Helligkeit der Farbe basierend auf dem relativen Luminanzwert.
  double luminance = color.computeLuminance();
  // Definiere einen Schwellenwert, der angibt, ab welchem Luminanzwert eine Farbe als "dunkel" gilt.
  const double threshold = 0.5;
  // Wenn die Helligkeit der Farbe unter dem Schwellenwert liegt, geben wir true zurück (die Farbe ist dunkel).
  // Andernfalls geben wir false zurück (die Farbe ist hell).
  return luminance < threshold;
}

extension IntColorHelper on int {
  String toHexColor(
      {bool leadingHash = true, bool alpha = true, bool useArgb = false}) {
    final color = Color(this);
    var hex = '';
    if (leadingHash) {
      hex += '#';
    }
    if (alpha && useArgb) hex += color.alpha.toRadixString(16).padLeft(2, '0');
    hex += color.red.toRadixString(16).padLeft(2, '0');
    hex += color.green.toRadixString(16).padLeft(2, '0');
    hex += color.blue.toRadixString(16).padLeft(2, '0');
    if (alpha && !useArgb) hex += color.alpha.toRadixString(16).padLeft(2, '0');
    return hex;
  }
}

extension ColorHelper on Color {
  String toHexColor({bool leadingHash = true, bool alpha = true}) =>
      value.toHexColor(leadingHash: leadingHash, alpha: alpha);
}
