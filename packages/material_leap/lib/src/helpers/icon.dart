import 'package:phosphor_flutter/phosphor_flutter.dart';

class IconGetter {
  final PhosphorIconData light;
  final PhosphorIconData fill;

  const IconGetter(this.light, this.fill);

  PhosphorIconData call([bool filled = false]) => filled ? fill : light;
}
