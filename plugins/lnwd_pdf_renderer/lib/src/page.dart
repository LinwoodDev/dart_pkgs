import 'dart:typed_data';

import 'package:flutter/foundation.dart';

@immutable
class PdfPage {
  final int width;
  final int height;
  final Uint8List data;

  const PdfPage(this.width, this.height, this.data);
}
