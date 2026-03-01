import 'dart:typed_data';

import 'location.dart';

sealed class FileSystemEntity<T> {
  final AssetLocation location;
  final DateTime? lastModified;
  final DateTime? creationTime;
  final int? size;

  FileSystemEntity(
    this.location, {
    this.lastModified,
    this.creationTime,
    this.size,
  });

  String get path => location.path;

  String get remote => location.remote;

  String get pathWithoutLeadingSlash => location.pathWithoutLeadingSlash;

  bool get isEmpty => location.isEmpty;

  bool get isRemote => location.isRemote;

  bool get isLocal => location.isLocal;

  String get identifier => location.identifier;

  String get fileExtension => location.fileExtension;

  String get fileName => location.fileName;

  String get fileNameWithoutExtension => location.fileNameWithoutExtension;

  String get parent => location.parent;
}

class FileSystemFile<T> extends FileSystemEntity<T> {
  final T? data;
  final bool cached;

  FileSystemFile(
    super.location, {
    this.data,
    this.cached = false,
    super.lastModified,
    super.creationTime,
    super.size,
  });

  bool get hasData => data != null;
}

class FileSystemDirectory<T> extends FileSystemEntity<T> {
  final List<FileSystemEntity<T>> assets;

  FileSystemDirectory(
    super.location, {
    this.assets = const [],
    super.lastModified,
    super.creationTime,
    super.size,
  });

  FileSystemDirectory<T> withAssets(List<FileSystemEntity<T>> assets) =>
      FileSystemDirectory(
        location,
        assets: assets,
        lastModified: lastModified,
        creationTime: creationTime,
        size: size,
      );
}

typedef RawFileSystemEntity = FileSystemEntity<Uint8List>;
typedef RawFileSystemFile = FileSystemFile<Uint8List>;
typedef RawFileSystemDirectory = FileSystemDirectory<Uint8List>;
