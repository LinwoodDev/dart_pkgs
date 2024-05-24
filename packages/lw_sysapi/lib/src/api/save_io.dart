import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';
import 'api.dart';
import 'save.dart';

Future<void> exportFile(
  BuildContext context,
  List<int> bytes,
  String fileName,
  String fileExtension,
  String mimeType,
  String uniformTypeIdentifier,
  String label,
) async {
  if (Platform.isIOS) {
    return exportUsingShare(bytes, fileName, fileExtension, mimeType);
  }
  if (Platform.isAndroid) {
    await platform.invokeMethod('saveFile', {
      'mime': mimeType,
      'data': Uint8List.fromList(bytes),
      'name': '$fileName.$fileExtension',
    });
    return;
  }
  final file = fs.XFile.fromData(Uint8List.fromList(bytes),
      mimeType: mimeType, name: '$fileName.$fileExtension');
  final result = await fs.getSaveLocation(
    acceptedTypeGroups: [
      fs.XTypeGroup(
        label: label,
        uniformTypeIdentifiers: [uniformTypeIdentifier],
        extensions: [fileExtension],
        mimeTypes: [mimeType],
      ),
    ],
  );
  if (result == null) return;
  await file.saveTo(result.path);
}
