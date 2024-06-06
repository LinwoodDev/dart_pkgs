import 'dart:typed_data';

import 'package:lw_file_system/src/models/entity.dart';

import 'file_system_base.dart';

class WebDocumentFileSystem extends DirectoryFileSystem {
  WebDocumentFileSystem({required super.config});

  @override
  Future<FileSystemDirectory<Uint8List>> createDirectory(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAsset(String path) {
    throw UnimplementedError();
  }

  @override
  Future<bool> hasAsset(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateFile(String path, Uint8List data) {
    throw UnimplementedError();
  }
}

class WebTemplateFileSystem extends KeyFileSystem {
  WebTemplateFileSystem({required super.config});

  @override
  Future<void> deleteFile(String key) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List?> getFile(String key) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getKeys() {
    throw UnimplementedError();
  }

  @override
  Future<bool> hasKey(String name) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateFile(String key, Uint8List data) {
    throw UnimplementedError();
  }
}
