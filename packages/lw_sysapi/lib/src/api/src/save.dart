import 'package:flutter/foundation.dart';
import 'package:lw_sysapi/src/files/file_dialogs.dart';

Future<void> exportFile({
  required Uint8List bytes,
  required String fileName,
  String? fileExtension,
  String? mimeType,
  String? uniformTypeIdentifier,
  String? label,
}) async {
  await SystemFileDialogs.saveFile(
    fileName: fileName,
    fileExtension: fileExtension,
    bytes: bytes,
    mimeType: mimeType,
    uniformTypeIdentifier: uniformTypeIdentifier,
    dialogTitle: label,
  );
}
