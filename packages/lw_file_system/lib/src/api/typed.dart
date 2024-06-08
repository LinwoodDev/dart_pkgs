import 'dart:typed_data';

import 'package:lw_file_system/lw_file_system.dart';

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
  final CreateDefaultCallback<TypedDirectoryFileSystem<T>> createDefault;

  TypedDirectoryFileSystem._(
    this.fileSystem, {
    required super.onDecode,
    required super.onEncode,
    required super.config,
    this.createDefault = defaultCreateDefault,
  });

  factory TypedDirectoryFileSystem.build(
    FileSystemConfig config,
    CreateDefaultCallback<TypedDirectoryFileSystem<T>> createDefault,
    ExternalStorage? storage, {
    required EncodeTypedFileSystemCallback<T> onEncode,
    required DecodeTypedFileSystemCallback<T> onDecode,
  }) {
    TypedDirectoryFileSystem<T>? fileSystem;
    fileSystem = TypedDirectoryFileSystem._(
      DirectoryFileSystem.fromPlatform(config,
          createDefault: (_) => fileSystem?.createDefault(fileSystem)),
      onEncode: onEncode,
      onDecode: onDecode,
      config: config,
      createDefault: createDefault,
    );
    return fileSystem;
  }
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

  @override
  Future<FileSystemEntity<T>?> readAsset(String path, {bool readData = true}) =>
      fileSystem
          .readAsset(path, readData: readData)
          .then((entity) => entity == null ? null : _toTypedAsset(entity));

  @override
  Future<bool> isInitialized() => fileSystem.isInitialized();

  @override
  Future<void> runInitialize() => fileSystem.runInitialize();
}

class TypedKeyFileSystem<T> extends TypedFileSystem<T>
    with GeneralKeyFileSystem<T> {
  @override
  final KeyFileSystem fileSystem;
  final CreateDefaultCallback<TypedKeyFileSystem<T>> createDefault;

  TypedKeyFileSystem._(
    this.fileSystem, {
    required super.onDecode,
    required super.onEncode,
    required super.config,
    this.createDefault = defaultCreateDefault,
  });

  factory TypedKeyFileSystem.build(
    FileSystemConfig config,
    CreateDefaultCallback<TypedKeyFileSystem<T>> createDefault,
    ExternalStorage? storage, {
    required EncodeTypedFileSystemCallback<T> onEncode,
    required DecodeTypedFileSystemCallback<T> onDecode,
  }) {
    TypedKeyFileSystem<T>? fileSystem;
    fileSystem = TypedKeyFileSystem._(
      KeyFileSystem.fromPlatform(config,
          createDefault: (_) => fileSystem?.createDefault(fileSystem)),
      onEncode: onEncode,
      onDecode: onDecode,
      config: config,
      createDefault: createDefault,
    );
    return fileSystem;
  }

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
  Future<bool> hasKey(String key) => fileSystem.hasKey(key);

  @override
  Future<void> updateFile(String key, T data) =>
      fileSystem.updateFile(key, onEncode(data));

  @override
  Future<bool> isInitialized() => fileSystem.isInitialized();

  @override
  Future<void> runInitialize() => fileSystem.runInitialize();
}
