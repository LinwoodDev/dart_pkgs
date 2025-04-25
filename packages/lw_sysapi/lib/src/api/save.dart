import 'dart:io';

import 'package:lw_sysapi/src/api/src/share.dart';

import 'src/save_stub.dart'
    if (dart.library.io) 'src/save_io.dart'
    if (dart.library.js_interop) 'src/save_html.dart' as save;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool supportsShare() => kIsWeb || !Platform.isLinux;

Future<void> exportFile(
    {required BuildContext context,
    required List<int> bytes,
    required String fileName,
    required String fileExtension,
    required String mimeType,
    required String uniformTypeIdentifier,
    required String label,
    bool share = false}) async {
  if (share && supportsShare()) {
    return exportUsingShare(
      bytes: bytes,
      fileName: fileName,
      fileExtension: fileExtension,
      mimeType: mimeType,
      label: label,
    );
  }
  return save.exportFile(context, bytes, fileName, fileExtension, mimeType,
      uniformTypeIdentifier, label);
}
