import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:mime/mime.dart';

import '../../files/file_dialog_models.dart';

Future<void> exportUsingShare({
  required Uint8List bytes,
  required String fileName,
  String? fileExtension,
  String? mimeType,
  String? label,
}) async {
  final extension = resolveFileExtension(
    fileName: fileName,
    fileExtension: fileExtension,
  );
  final name = extension == null
      ? fileName
      : withFileExtension(fileName, extension);
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          mimeType:
              mimeType ?? lookupMimeType(name) ?? 'application/octet-stream',
          name: name,
        ),
      ],
      fileNameOverrides: [name],
      downloadFallbackEnabled: true,
      title: label,
    ),
  );
}
