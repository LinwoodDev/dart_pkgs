import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:lw_sysapi/src/api/api.dart';

Future<void> exportFile(
  Uint8List bytes,
  String fileName,
  String fileExtension,
  String mimeType,
  String uniformTypeIdentifier,
  String label,
) async {
  if (!kIsWeb && Platform.isAndroid) {
    await platform.invokeMethod('saveFile', {
      'mime': mimeType,
      'data': bytes,
      'name': '$fileName.$fileExtension',
    });
    return;
  }
  var file = await FilePicker.platform.saveFile(
    dialogTitle: label,
    fileName: '$fileName.$fileExtension',
    bytes: bytes,
    type: FileType.custom,
    allowedExtensions: [fileExtension],
  );
  if (file == null) return;
  if (!file.endsWith('.$fileExtension')) {
    final dotIndex = file.lastIndexOf('.');
    if (dotIndex != -1) {
      file = file.substring(0, dotIndex);
    }
    file = '$file.$fileExtension';
  }
  final outputFile = File(file);
  await outputFile.writeAsBytes(bytes);
}
