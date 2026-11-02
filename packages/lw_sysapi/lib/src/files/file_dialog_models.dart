import 'dart:typed_data';

/// A user-selected file, with lazy reads for local files and document providers.
class SelectedFile {
  final String name;
  final String? path;
  final Future<Uint8List> Function() _read;

  SelectedFile({
    required this.name,
    this.path,
    required Future<Uint8List> Function() read,
  }) : _read = read;

  String? get extension {
    final dot = name.lastIndexOf('.');
    return dot <= 0 || dot == name.length - 1 ? null : name.substring(dot + 1);
  }

  Future<Uint8List> readAsBytes() => _read();
}

String normalizeFileExtension(String extension) {
  final value = extension.trim().replaceFirst(RegExp(r'^\.+'), '');
  if (value.isEmpty || RegExp(r'[/\\:*?"<>|;\x00-\x1f]').hasMatch(value)) {
    throw ArgumentError.value(extension, 'extension', 'Invalid file extension');
  }
  return value;
}

String withFileExtension(String name, String extension) {
  final suffix = '.${normalizeFileExtension(extension)}';
  return name.toLowerCase().endsWith(suffix.toLowerCase())
      ? name
      : '$name$suffix';
}

String? resolveFileExtension({
  required String fileName,
  String? fileExtension,
}) {
  if (fileExtension != null) return normalizeFileExtension(fileExtension);
  final dot = fileName.lastIndexOf('.');
  if (dot <= 0 || dot == fileName.length - 1) return null;
  return normalizeFileExtension(fileName.substring(dot + 1));
}
