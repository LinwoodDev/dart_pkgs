import 'dart:io';

import 'package:lw_sysapi/src/api/src/share.dart';

import 'src/save.dart' as save;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

bool supportsShare() => kIsWeb || !Platform.isLinux;
bool supportsSave() => kIsWeb || !Platform.isIOS;

Future<void> exportFile({
  BuildContext? context,
  required Uint8List bytes,
  required String fileName,
  String? fileExtension,
  String? mimeType,
  String? uniformTypeIdentifier,
  String? label,
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
      bytes: bytes,
      fileName: fileName,
      fileExtension: fileExtension,
      mimeType: mimeType,
      uniformTypeIdentifier: uniformTypeIdentifier,
      label: label,
    );
  }
}
