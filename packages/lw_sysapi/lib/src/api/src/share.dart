import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> exportUsingShare({
  required Uint8List bytes,
  required String fileName,
  required String fileExtension,
  required String mimeType,
  required String label,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          mimeType: mimeType,
          name: '$fileName.$fileExtension',
        ),
      ],
      fileNameOverrides: ['$fileName.$fileExtension'],
      downloadFallbackEnabled: true,
      title: label,
    ),
  );
}
