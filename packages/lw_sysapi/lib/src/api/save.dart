import 'dart:io';

import 'package:lw_sysapi/src/api/src/share.dart';

import 'src/save.dart' as save;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool supportsShare() => kIsWeb || !Platform.isLinux;
bool supportsSave() => kIsWeb || !Platform.isIOS;

Future<void> exportFile({
  required BuildContext context,
  required Uint8List bytes,
  required String fileName,
  required String fileExtension,
  required String mimeType,
  required String uniformTypeIdentifier,
  required String label,
  bool share = false,
}) async {
  if (share && supportsShare() || (!share && !supportsSave())) {
    return exportUsingShare(
      bytes: bytes,
      fileName: fileName,
      fileExtension: fileExtension,
      mimeType: mimeType,
      label: label,
    );
  }
  if (supportsSave()) {
    return save.exportFile(
      bytes,
      fileName,
      fileExtension,
      mimeType,
      uniformTypeIdentifier,
      label,
    );
  }
}
