import 'dart:io';
import 'dart:typed_data';

import '../api/api.dart';
import 'file_dialog_models.dart';

Future<List<SelectedFile>> pickFiles({
  required List<String> extensions,
  required bool multiple,
  String? dialogTitle,
}) async {
  final results = await platform.invokeListMethod<dynamic>('pickFiles', {
    'extensions': extensions,
    'multiple': multiple,
    'title': dialogTitle,
  });
  return [
    for (final value in results ?? const [])
      SelectedFile(
        name: (value as Map)['name'] as String,
        path: value['path'] as String,
        read: () async {
          final path = value['path'] as String;
          if (Platform.isAndroid || Platform.isMacOS || Platform.isIOS) {
            final bytes = await platform.invokeMethod<Uint8List>('readFile', {
              'path': path,
            });
            if (bytes == null) {
              throw FileSystemException('Unable to read file', path);
            }
            return bytes;
          }
          return File(path).readAsBytes();
        },
      ),
  ];
}

Future<String?> getDirectoryPath({String? dialogTitle}) =>
    platform.invokeMethod<String>('pickDirectory', {'title': dialogTitle});

Future<bool> saveFile({
  required String fileName,
  String? extension,
  required Uint8List bytes,
  required String mimeType,
  String? uniformTypeIdentifier,
  String? dialogTitle,
}) async {
  final arguments = <String, Object?>{
    'name': fileName,
    'extension': extension,
    'mime': mimeType,
    'uti': uniformTypeIdentifier,
    'title': dialogTitle,
  };
  if (Platform.isAndroid || Platform.isIOS) {
    return await platform.invokeMethod<bool>('saveFile', {
          ...arguments,
          'data': bytes,
        }) ??
        false;
  }
  final path = await platform.invokeMethod<String>('getSavePath', arguments);
  if (path == null) return false;
  // The native dialog validates the final extension before overwrite consent.
  // Never silently change the target after that consent has been obtained.
  if (extension != null && withFileExtension(path, extension) != path) {
    throw FileSystemException(
      'The save dialog returned an invalid extension',
      path,
    );
  }
  await File(path).writeAsBytes(bytes);
  return true;
}
