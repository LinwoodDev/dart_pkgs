import 'dart:io';

import 'save_stub.dart'
    if (dart.library.io) 'save_io.dart'
    if (dart.library.js) 'save_html.dart' as save;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
    return exportUsingShare(bytes, fileName, fileExtension, mimeType);
  }
  return save.exportFile(context, bytes, fileName, fileExtension, mimeType,
      uniformTypeIdentifier, label);
}

Future<void> exportUsingShare(List<int> bytes, String fileName,
    String fileExtension, String mimeType) async {
  await Share.shareXFiles(
    [
      XFile.fromData(Uint8List.fromList(bytes),
          mimeType: mimeType, name: '$fileName.$fileExtension')
    ],
  );
}
