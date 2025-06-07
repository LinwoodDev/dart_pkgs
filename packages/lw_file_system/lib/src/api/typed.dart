import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lw_file_system/lw_file_system.dart';

typedef EncodeTypedFileSystemCallback<T> = Uint8List Function(T data);
typedef DecodeTypedFileSystemCallback<T> = T Function(Uint8List data);

sealed class TypedFileSystem<T> extends GeneralFileSystem {
  final EncodeTypedFileSystemCallback<T> onEncode;
  final DecodeTypedFileSystemCallback<T> onDecode;

  RemoteFileSystem? get remoteSystem;

  TypedFileSystem({
    required this.onEncode,
    required this.onDecode,
    required super.config,
  });

  GeneralFileSystem get fileSystem;

  @override
  Future<Uint8List?> loadAbsolute(String path) => fileSystem.loadAbsolute(path);

  @override
  Future<void> saveAbsolute(String path, Uint8List bytes) =>
      fileSystem.saveAbsolute(path, bytes);
}

class TypedDirectoryFileSystem<T> extends TypedFileSystem<T>
    with GeneralDirectoryFileSystem<T> {
  @override
  final DirectoryFileSystem fileSystem;
  final CreateDefaultCallback<TypedDirectoryFileSystem<T>> createDefault;

  @override
  RemoteDirectoryFileSystem? get remoteSystem {
    final fs = fileSystem;
    if (fs is RemoteDirectoryFileSystem) return fs;
    return null;
  }

  TypedDirectoryFileSystem._(
    this.fileSystem, {
    required super.onDecode,
    required super.onEncode,
    required super.config,
    this.createDefault = defaultCreateDefault,
  });

  factory TypedDirectoryFileSystem.build(
    FileSystemConfig config, {
    ExternalStorage? storage,
    CreateDefaultCallback<TypedDirectoryFileSystem<T>> createDefault =
        defaultCreateDefault,
    required EncodeTypedFileSystemCallback<T> onEncode,
    required DecodeTypedFileSystemCallback<T> onDecode,
  }) {
    TypedDirectoryFileSystem<T>? fileSystem;
    Future<void> createWrappedDefault(_) =>
        Future.value(fileSystem?.runDefault());
    final directorySystem = DirectoryFileSystem.fromPlatform(
      config,
      storage: storage,
      createDefault: createWrappedDefault,
    );
    fileSystem = TypedDirectoryFileSystem._(
      directorySystem,
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
        assets: directory.assets
            .map((e) {
              try {
                return _toTypedAsset(e);
              } catch (_) {
                return null;
              }
            })
            .nonNulls
            .toList(),
      );

  @override
  Future<FileSystemDirectory<T>> createDirectory(String path) async =>
      _toTypedDirectory(await fileSystem.createDirectory(path));

  @override
  Future<void> deleteAsset(String path) => fileSystem.deleteAsset(path);

  @override
  Future<bool> hasAsset(String path) => fileSystem.hasAsset(path);

  @override
  Future<void> updateFile(String path, T data, {bool forceSync = false}) =>
      fileSystem.updateFile(path, onEncode(data));

  @override
  Future<FileSystemEntity<T>?> readAsset(
    String path, {
    bool readData = true,
    bool forceRemote = false,
  }) => fileSystem
      .readAsset(path, readData: readData, forceRemote: forceRemote)
      .then((entity) => entity == null ? null : _toTypedAsset(entity));

  @override
  FutureOr<bool> isInitialized() => fileSystem.isInitialized();

  @override
  Future<void> runInitialize() => fileSystem.runInitialize();

  @override
  @protected
  FutureOr<void> runDefault() => createDefault(this);

  @override
  @protected
  bool hasDefault() => createDefault != defaultCreateDefault;

  @override
  Future<Uint8List?> loadAbsolute(String path) => fileSystem.loadAbsolute(path);

  @override
  Future<bool> moveAbsolute(String oldPath, String newPath) =>
      fileSystem.moveAbsolute(oldPath, newPath);
}

class TypedKeyFileSystem<T> extends TypedFileSystem<T>
    with GeneralKeyFileSystem<T> {
  @override
  final KeyFileSystem fileSystem;
  final CreateDefaultCallback<TypedKeyFileSystem<T>> createDefault;

  @override
  RemoteFileSystem? get remoteSystem {
    final fs = fileSystem;
    if (fs is KeyDirectoryFileSystem) {
      final remote = fs.fileSystem;
      if (remote is RemoteDirectoryFileSystem) return remote;
    }
    return null;
  }

  TypedKeyFileSystem._(
    this.fileSystem, {
    required super.onDecode,
    required super.onEncode,
    required super.config,
    this.createDefault = defaultCreateDefault,
  });

  factory TypedKeyFileSystem.build(
    FileSystemConfig config, {
    ExternalStorage? storage,
    CreateDefaultCallback<TypedKeyFileSystem<T>> createDefault =
        defaultCreateDefault,
    required EncodeTypedFileSystemCallback<T> onEncode,
    required DecodeTypedFileSystemCallback<T> onDecode,
  }) {
    TypedKeyFileSystem<T>? fileSystem;
    Future<void> createWrappedDefault(_) =>
        Future.value(fileSystem?.runDefault());
    final keySystem = KeyFileSystem.fromPlatform(
      config,
      storage: storage,
      createDefault: createWrappedDefault,
    );
    fileSystem = TypedKeyFileSystem._(
      keySystem,
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
  FutureOr<bool> isInitialized() => fileSystem.isInitialized();

  @override
  Future<void> runInitialize() => fileSystem.runInitialize();

  @override
  Future<void> reset() => fileSystem.reset();

  @override
  @protected
  FutureOr<void> runDefault() => createDefault(this);

  @override
  @protected
  bool hasDefault() => createDefault != defaultCreateDefault;
}
