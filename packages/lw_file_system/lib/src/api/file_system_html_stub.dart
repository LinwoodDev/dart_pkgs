import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lw_file_system/src/models/entity.dart';

import 'file_system_base.dart';

class WebDocumentFileSystem<T> extends DirectoryFileSystem<T> {
  WebDocumentFileSystem({required super.config});

  @override
  Future<AppDocumentDirectory<T>> createDirectory(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAsset(String path) {
    throw UnimplementedError();
  }

  @override
  Stream<AppDocumentEntity<T>?> fetchAsset(String path,
      [bool? listFiles = true]) {
    throw UnimplementedError();
  }

  @override
  Future<bool> hasAsset(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateFile(String path, List<int> data) {
    throw UnimplementedError();
  }
}

class WebTemplateFileSystem<T> extends KeyFileSystem<T> {
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
  Future<List<AppDocumentFile<T>>> getFiles() {
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
