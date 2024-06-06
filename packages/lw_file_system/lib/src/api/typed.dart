import 'dart:typed_data';

import 'package:lw_file_system/lw_file_system.dart';
import 'package:lw_file_system/src/models/entity.dart';

typedef EncodeTypedFileSystemCallback<T> = Uint8List Function(T data);
typedef DecodeTypedFileSystemCallback<T> = T Function(Uint8List data);

sealed class TypedFileSystem<T> extends GeneralFileSystem {
  final EncodeTypedFileSystemCallback<T> onEncode;
  final DecodeTypedFileSystemCallback<T> onDecode;

  TypedFileSystem(
      {required this.onEncode, required this.onDecode, required super.config});

  GeneralFileSystem get fileSystem;
}

class TypedDirectoryFileSystem<T> extends TypedFileSystem<T>
    with GeneralDirectoryFileSystem<T> {
  @override
  final DirectoryFileSystem fileSystem;

  TypedDirectoryFileSystem(
    this.fileSystem, {
    required super.onDecode,
    required super.onEncode,
    required super.config,
  });

  FileSystemEntity<T> _toTypedAsset(RawFileSystemEntity entity) =>
      switch (entity) {
        RawFileSystemFile file => FileSystemFile(
            file.location,
            data: file.data == null ? null : onDecode(file.data!),
          ),
        RawFileSystemDirectory directory => _toTypedDirectory(directory),
      };

  FileSystemDirectory<T> _toTypedDirectory(RawFileSystemDirectory directory) =>
      FileSystemDirectory(
        directory.location,
        assets: directory.assets.map((e) => _toTypedAsset(e)).toList(),
      );

  @override
  Future<FileSystemDirectory<T>> createDirectory(String path) async =>
      _toTypedDirectory(await fileSystem.createDirectory(path));

  @override
  Future<void> deleteAsset(String path) => fileSystem.deleteAsset(path);

  @override
  Future<bool> hasAsset(String path) => fileSystem.hasAsset(path);

  @override
  Future<void> updateFile(String path, T data) =>
      fileSystem.updateFile(path, onEncode(data));
}

class TypedKeyFileSystem<T> extends TypedFileSystem<T>
    with GeneralKeyFileSystem<T> {
  @override
  final KeyFileSystem fileSystem;

  TypedKeyFileSystem(
    this.fileSystem, {
    required super.onDecode,
    required super.onEncode,
    required super.config,
  });

  @override
  Future<void> deleteFile(String key) => fileSystem.deleteFile(key);

  @override
  Future<T?> getFile(String key) async {
    final asset = await fileSystem.getFile(key);
    if (asset == null) return null;
    return onDecode(asset);
  }

  @override
  Future<List<String>> getKeys() => fileSystem.getKeys();

  @override
  Future<bool> hasKey(String name) => fileSystem.hasKey(name);

  @override
  Future<void> updateFile(String key, T data) =>
      fileSystem.updateFile(key, onEncode(data));
}
