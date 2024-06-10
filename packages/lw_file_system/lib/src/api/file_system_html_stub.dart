import 'dart:typed_data';

import 'package:lw_file_system/src/models/entity.dart';

import 'file_system_base.dart';

class WebDirectoryFileSystem extends DirectoryFileSystem {
  WebDirectoryFileSystem({required super.config});

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

  @override
  Future<FileSystemEntity<Uint8List>?> readAsset(String path,
      {bool readData = true}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isInitialized() {
    throw UnimplementedError();
  }

  @override
  Future<void> runInitialize() {
    throw UnimplementedError();
  }
}

class WebKeyFileSystem extends KeyFileSystem {
  WebKeyFileSystem({required super.config});

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
  Future<bool> hasKey(String key) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateFile(String key, Uint8List data) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isInitialized() {
    throw UnimplementedError();
  }

  @override
  Future<void> runInitialize() {
    throw UnimplementedError();
  }
}
