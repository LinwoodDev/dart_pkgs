import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart';

Future<void> exportFile(
  BuildContext context,
  List<int> bytes,
  String fileName,
  String fileExtension,
  String mimeType,
  String uniformTypeIdentifier,
  String label,
) async {
  final a = document.createElement('a') as HTMLAnchorElement;
  // Create data URL
  final blob = Blob([bytes.toJSBox].toJS, BlobPropertyBag(type: mimeType));
  final url = URL.createObjectURL(blob);
  a.href = url;
  a.download = '$fileName.$fileExtension';
  a.click();
  URL.revokeObjectURL(url);
}
