part of '../file_system_base.dart';

mixin GeneralKeyFileSystem<T> on GeneralFileSystem {
  Future<T?> getFile(String key);

  Future<T?> getDefaultFile(String key) async =>
      await getFile(key) ?? (await listFiles().first).data;

  Future<String> findAvailableKey(String path) =>
      _findAvailableName(path, hasKey);

  Future<String> createFileWithName(T data,
      {String? name, String? fileExtension, String? directory}) {
    final path = convertNameToFile(
      name: name,
      fileExtension: fileExtension,
      directory: directory,
    );
    return createFile(path, data);
  }

  Future<String> createFile(String key, T data) async {
    key = normalizePath(key);
    final name = findAvailableKey(key);
    await updateFile(key, data);
    return name;
  }

  Future<bool> hasKey(String key);
  Future<void> updateFile(String key, T data);
  Future<void> deleteFile(String key);
  Future<List<String>> getKeys();
  Stream<FileSystemFile<T>> listFiles() async* {
    final keys = await getKeys();
    yield* Stream.fromIterable(keys).asyncExpand((key) async* {
      final data = await getFile(key);
      if (data != null) {
        yield FileSystemFile(
          AssetLocation(path: key, remote: storage?.identifier ?? ''),
          data: data,
        );
      }
    });
  }

  Stream<List<FileSystemFile<T>>> fetchFiles() async* {
    final files = <FileSystemFile<T>>[];
    yield files;
    await for (final file in listFiles()) {
      files.add(file);
      yield files;
    }
  }

  Future<List<FileSystemFile<T>>> getFiles() => fetchFiles().last;

  Future<String?> renameFile(
    String oldKey,
    String newKey, {
    bool override = false,
  }) async {
    oldKey = normalizePath(oldKey);
    newKey = normalizePath(newKey);
    var data = await getFile(oldKey);
    if (data == null) return null;
    final newTemplate = await createFile(newKey, data);
    await deleteFile(oldKey);
    return newTemplate;
  }
}

abstract class KeyFileSystem extends GeneralFileSystem
    with GeneralKeyFileSystem<Uint8List> {
  final CreateDefaultCallback<KeyFileSystem> createDefault;

  KeyFileSystem({
    required super.config,
    this.createDefault = defaultCreateDefault,
  });

  static KeyFileSystem fromPlatform(
    FileSystemConfig config, {
    ExternalStorage? storage,
    CreateDefaultCallback<KeyFileSystem> createDefault = defaultCreateDefault,
  }) {
    if (kIsWeb) {
      return WebKeyFileSystem(config: config, createDefault: createDefault);
    } else {
      return KeyDirectoryFileSystem.build(config,
          storage: storage, createDefault: createDefault);
    }
  }

  @override
  @protected
  FutureOr<void> runDefault() => createDefault(this);

  @override
  @protected
  bool hasDefault() => createDefault != defaultCreateDefault;

  @override
  Future<void> reset() async {
    final files = await getKeys();
    for (final file in files) {
      await deleteFile(file);
    }
  }
}

class KeyDirectoryFileSystem extends KeyFileSystem {
  final GeneralDirectoryFileSystem<Uint8List> fileSystem;

  KeyDirectoryFileSystem._({
    required super.config,
    required this.fileSystem,
    super.createDefault,
  });

  factory KeyDirectoryFileSystem.build(
    FileSystemConfig config, {
    ExternalStorage? storage,
    CreateDefaultCallback<KeyFileSystem> createDefault = defaultCreateDefault,
  }) {
    KeyDirectoryFileSystem? fileSystem;
    Future<void> createWrappedDefault(_) =>
        Future.value(fileSystem?.runDefault());

    final directory = DirectoryFileSystem.fromPlatform(
      config,
      createDefault: createWrappedDefault,
      storage: storage,
    );
    fileSystem = KeyDirectoryFileSystem._(
      config: config,
      fileSystem: directory,
      createDefault: createDefault,
    );
    return fileSystem;
  }

  @override
  Future<void> deleteFile(String key) =>
      fileSystem.deleteAsset(key + config.keySuffix);

  @override
  Future<Uint8List?> getFile(String key) async {
    final asset = await fileSystem.getAsset(key + config.keySuffix);
    if (asset is RawFileSystemFile) return asset.data;
    return null;
  }

  @override
  Future<List<String>> getKeys() async {
    final directory = await fileSystem.getRootDirectory(
        listLevel: allListLevel, readData: false);
    final assets = <String>[];
    final remaining = [...directory.assets];
    while (remaining.isNotEmpty) {
      final asset = remaining.removeAt(0);
      final path = asset.path;
      if (asset is RawFileSystemFile) {
        if (path.endsWith(config.keySuffix)) {
          assets.add(path.substring(0, path.length - config.keySuffix.length));
        }
      } else if (asset is RawFileSystemDirectory) {
        remaining.addAll(asset.assets);
      }
    }
    return assets;
  }

  @override
  Stream<RawFileSystemFile> listFiles() async* {
    final directory = await fileSystem.getRootDirectory(
        listLevel: allListLevel, readData: false);
    final remaining = [...directory.assets];
    final assets = <RawFileSystemFile>[];
    while (remaining.isNotEmpty) {
      final asset = remaining.removeAt(0);
      final path = asset.path;
      if (asset is RawFileSystemFile) {
        if (path.endsWith(config.keySuffix)) {
          assets.add(asset);
        }
      } else if (asset is RawFileSystemDirectory) {
        remaining.addAll(asset.assets);
      }
    }
    yield* Stream.fromIterable(assets);
  }

  @override
  Future<bool> hasKey(String key) async {
    if (!await fileSystem.hasAsset(key + config.keySuffix)) return false;
    final asset = await fileSystem.getAsset(key + config.keySuffix);
    return asset is RawFileSystemFile;
  }

  @override
  Future<void> updateFile(String key, Uint8List data) async {
    key = normalizePath(key);
    final parent = key.substring(0, key.lastIndexOf('/'));
    if ((await fileSystem.getAsset(parent,
        listLevel: noListLevel, readData: false)) is! RawFileSystemDirectory) {
      await fileSystem.createDirectory(parent);
    }
    return fileSystem.updateFile(key + config.keySuffix, data);
  }

  @override
  FutureOr<bool> isInitialized() => fileSystem.isInitialized();

  @override
  Future<void> runInitialize() => fileSystem.runInitialize();

  @override
  Future<Uint8List?> loadAbsolute(String path) => fileSystem.loadAbsolute(path);

  @override
  Future<void> saveAbsolute(String path, Uint8List bytes) =>
      fileSystem.saveAbsolute(path, bytes);
}
