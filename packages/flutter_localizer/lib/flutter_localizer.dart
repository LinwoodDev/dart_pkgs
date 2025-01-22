/// Flutter port of the localizer library.
library;

import 'package:flutter/services.dart';
import 'package:localizer/localizer.dart';

export 'package:localizer/localizer.dart';

extension FlutterLocalizerExtension on Localizer {
  Future<void> loadJsonAsset(String locale, String assetPath) async {
    final data = await rootBundle.loadString(assetPath);
    loadJson(locale, data);
  }

  Future<void> loadYamlAsset(String locale, String assetPath) async {
    final data = await rootBundle.loadString(assetPath);
    loadYaml(locale, data);
  }
}
