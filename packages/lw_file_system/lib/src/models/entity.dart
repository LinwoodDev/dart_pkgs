import 'dart:typed_data';

import 'location.dart';

sealed class AppDocumentEntity<T> {
  final AssetLocation location;

  AppDocumentEntity(this.location);

  String get fileName => location.fileName;

  String get fileExtension => location.fileExtension;

  String get fileNameWithoutExtension => fileName.substring(0,
      fileName.contains('.') ? fileName.lastIndexOf('.') : fileName.length - 1);

  String get pathWithLeadingSlash => location.pathWithLeadingSlash;

  String get pathWithoutLeadingSlash => location.pathWithoutLeadingSlash;

  String get parent => pathWithLeadingSlash
      .split('/')
      .sublist(0, pathWithLeadingSlash.split('/').length - 1)
      .join('/');
}

class AppDocumentFile<T> extends AppDocumentEntity<T> {
  final Uint8List? data;
  final bool cached;
  final T? metadata;
  final Uint8List? thumbnail;

  AppDocumentFile(
    super.location, {
    this.data,
    this.cached = false,
    this.thumbnail,
    this.metadata,
  });

  bool get hasData => data != null;
}

class AppDocumentDirectory<T> extends AppDocumentEntity<T> {
  final List<AppDocumentEntity<T>> assets;

  AppDocumentDirectory(super.location, {this.assets = const []});
}
