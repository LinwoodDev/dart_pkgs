import 'package:flutter/foundation.dart';

import 'page.dart';

@immutable
class PdfDocument {
  final List<PdfPage> pages;
  const PdfDocument({this.pages = const []});
}
