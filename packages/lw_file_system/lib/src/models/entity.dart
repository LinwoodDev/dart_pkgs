import 'dart:typed_data';

import 'location.dart';

sealed class FileSystemEntity<T> {
  final AssetLocation location;

  FileSystemEntity(this.location);

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

class FileSystemFile<T> extends FileSystemEntity<T> {
  final T? data;
  final bool cached;

  FileSystemFile(
    super.location, {
    this.data,
    this.cached = false,
  });

  bool get hasData => data != null;
}

class FileSystemDirectory<T> extends FileSystemEntity<T> {
  final List<FileSystemEntity<T>> assets;

  FileSystemDirectory(super.location, {this.assets = const []});

  FileSystemDirectory<T> withAssets(List<FileSystemEntity<T>> assets) =>
      FileSystemDirectory(
        location,
        assets: assets,
      );
}

typedef RawFileSystemEntity = FileSystemEntity<Uint8List>;
typedef RawFileSystemFile = FileSystemFile<Uint8List>;
typedef RawFileSystemDirectory = FileSystemDirectory<Uint8List>;
