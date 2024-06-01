import 'dart:typed_data';

import 'location.dart';

sealed class AppDocumentEntity {
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

class AppDocumentFile extends AppDocumentEntity {
  final List<int> data;
  final bool cached;
  final Uint8List? thumbnail;

  AppDocumentFile(
    super.location, {
    this.data = const [],
    this.cached = false,
    this.thumbnail,
  });
}

class AppDocumentDirectory extends AppDocumentEntity {
  final List<AppDocumentEntity> assets;

  AppDocumentDirectory(super.location, {this.assets = const []});
}
