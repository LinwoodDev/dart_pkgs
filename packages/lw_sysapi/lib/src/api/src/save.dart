import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<void> exportFile(
  Uint8List bytes,
  String fileName,
  String fileExtension,
  String mimeType,
  String uniformTypeIdentifier,
  String label,
) async {
  await FilePicker.platform.saveFile(
    dialogTitle: label,
    fileName: '$fileName.$fileExtension',
    bytes: bytes,
    type: FileType.custom,
    allowedExtensions: [fileExtension],
  );
}
