import 'dart:typed_data';

import 'package:flutter/foundation.dart';

@immutable
class PdfPage {
  final int width;
  final int height;
  final Uint8List data;

  const PdfPage(
      {required this.width, required this.height, required this.data});
}
