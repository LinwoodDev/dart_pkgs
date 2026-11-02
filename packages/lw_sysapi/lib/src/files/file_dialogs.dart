import 'dart:typed_data';

import 'package:mime/mime.dart';

import 'file_dialog_models.dart';
import 'file_dialogs_native.dart'
    if (dart.library.js_interop) 'file_dialogs_web.dart'
    as backend;

export 'file_dialog_models.dart' show SelectedFile;

/// Native system file dialogs, or browser file inputs and downloads on the web.
abstract final class SystemFileDialogs {
  static Future<List<SelectedFile>> pickFiles({
    List<String> extensions = const [],
    bool multiple = true,
    String? dialogTitle,
  }) => backend.pickFiles(
    extensions: extensions.map(normalizeFileExtension).toSet().toList(),
    multiple: multiple,
    dialogTitle: dialogTitle,
  );

  static Future<SelectedFile?> pickFile({
    List<String> extensions = const [],
    String? dialogTitle,
  }) async {
    final files = await pickFiles(
      extensions: extensions,
      multiple: false,
      dialogTitle: dialogTitle,
    );
    return files.firstOrNull;
  }

  static Future<String?> getDirectoryPath({String? dialogTitle}) =>
      backend.getDirectoryPath(dialogTitle: dialogTitle);

  /// Saves with the extension inferred from [fileName], unless [fileExtension]
  /// overrides it. Extension-less names are supported when neither supplies one.
  static Future<bool> saveFile({
    required String fileName,
    String? fileExtension,
    required Uint8List bytes,
    String? mimeType,
    String? uniformTypeIdentifier,
    String? dialogTitle,
  }) {
    final extension = resolveFileExtension(
      fileName: fileName,
      fileExtension: fileExtension,
    );
    final name = extension == null
        ? fileName
        : withFileExtension(fileName, extension);
    return backend.saveFile(
      fileName: name,
      extension: extension,
      bytes: bytes,
      mimeType: mimeType ?? lookupMimeType(name) ?? 'application/octet-stream',
      uniformTypeIdentifier: uniformTypeIdentifier,
      dialogTitle: dialogTitle,
    );
  }
}
