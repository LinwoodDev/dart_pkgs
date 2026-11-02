import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'file_dialog_models.dart';

bool _dialogOpen = false;

Future<List<SelectedFile>> pickFiles({
  required List<String> extensions,
  required bool multiple,
  String? dialogTitle,
}) async {
  if (_dialogOpen) throw StateError('A file dialog is already open');
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = multiple
    ..accept = extensions.map((extension) => '.$extension').join(',');
  input.style.display = 'none';
  final selected = Completer<List<SelectedFile>>();
  final onChange = ((web.Event event) {
    if (selected.isCompleted) return;
    final files = input.files;
    selected.complete([
      if (files != null)
        for (var i = 0; i < files.length; i++) _selectedFile(files.item(i)!),
    ]);
  }).toJS;
  final onCancel = ((web.Event event) {
    if (!selected.isCompleted) selected.complete([]);
  }).toJS;
  input.addEventListener('change', onChange);
  input.addEventListener('cancel', onCancel);
  web.document.body!.append(input);
  _dialogOpen = true;
  try {
    input.click();
    return await selected.future;
  } finally {
    _dialogOpen = false;
    input.removeEventListener('change', onChange);
    input.removeEventListener('cancel', onCancel);
    input.remove();
  }
}

SelectedFile _selectedFile(web.File file) => SelectedFile(
  name: file.name,
  read: () async => (await file.arrayBuffer().toDart).toDart.asUint8List(),
);

Future<String?> getDirectoryPath({String? dialogTitle}) async =>
    throw UnsupportedError('Browsers do not expose local directory paths');

Future<bool> saveFile({
  required String fileName,
  String? extension,
  required Uint8List bytes,
  required String mimeType,
  String? uniformTypeIdentifier,
  String? dialogTitle,
}) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = extension == null
        ? fileName
        : withFileExtension(fileName, extension);
  anchor.style.display = 'none';
  web.document.body!.append(anchor);
  try {
    anchor.click();
  } finally {
    anchor.remove();
    Timer(const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
  }
  return true;
}
