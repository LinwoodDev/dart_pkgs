part of '../file_system_base.dart';

mixin GeneralKeyFileSystem<T> on GeneralFileSystem {
  Future<T?> getFile(String key);

  Future<T?> getDefaultFile(String key) async =>
      await getFile(key) ?? (await listFiles().first).value;

  Future<String> findAvailableKey(String path) =>
      _findAvailableName(path, hasKey);

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
  Stream<MapEntry<String, T>> listFiles() async* {
    final keys = await getKeys();
    yield* Stream.fromIterable(keys).asyncExpand((key) async* {
      final data = await getFile(key);
      if (data != null) {
        yield MapEntry(key, data);
      }
    });
  }

  Stream<Map<String, T>> fetchFiles() async* {
    final files = <String, T>{};
    yield files;
    await for (final file in listFiles()) {
      files[file.key] = file.value;
      yield files;
    }
  }

  Future<Map<String, T>> getFiles() => fetchFiles().last;

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
    CreateDefaultCallback<KeyFileSystem>? createDefault,
  }) {
    if (kIsWeb) {
      return WebKeyFileSystem(config: config);
    } else {
      return KeyDirectoryFileSystem.build(config, storage: storage);
    }
  }

  void _runDefault() {
    createDefault(this);
  }
}

class KeyDirectoryFileSystem extends KeyFileSystem {
  final GeneralDirectoryFileSystem<Uint8List> _fileSystem;

  KeyDirectoryFileSystem._({
    required super.config,
    required GeneralDirectoryFileSystem<Uint8List> fileSystem,
  }) : _fileSystem = fileSystem;

  factory KeyDirectoryFileSystem.build(FileSystemConfig config,
      {ExternalStorage? storage}) {
    KeyDirectoryFileSystem? fileSystem;
    void createDefault(_) => fileSystem?._runDefault();

    final directory = DirectoryFileSystem.fromPlatform(
      config,
      createDefault: createDefault,
      storage: storage,
    );
    fileSystem =
        KeyDirectoryFileSystem._(config: config, fileSystem: directory);
    return fileSystem;
  }

  @override
  Future<void> deleteFile(String key) =>
      _fileSystem.deleteAsset(key + config.keySuffix);

  @override
  Future<Uint8List?> getFile(String key) async {
    final asset = await _fileSystem.getAsset(key + config.keySuffix);
    if (asset is RawFileSystemFile) return asset.data;
    return null;
  }

  @override
  Future<List<String>> getKeys() async {
    final directory = await _fileSystem.getRootDirectory(
        listLevel: allListLevel, readData: false);
    final assets = <String>[];
    final remaining = [...directory.assets];
    while (remaining.isNotEmpty) {
      final asset = remaining.removeAt(0);
      final path = asset.location.pathWithoutLeadingSlash;
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
  Future<bool> hasKey(String key) async {
    if (!await _fileSystem.hasAsset(key + config.keySuffix)) return false;
    final asset = await _fileSystem.getAsset(key + config.keySuffix);
    return asset is RawFileSystemFile;
  }

  @override
  Future<void> updateFile(String key, Uint8List data) async {
    key = normalizePath(key);
    final parent = key.substring(0, key.lastIndexOf('/'));
    if ((await _fileSystem.getAsset(parent,
        listLevel: noListLevel, readData: false)) is! RawFileSystemDirectory) {
      await _fileSystem.createDirectory(parent);
    }
    return _fileSystem.updateFile(key + config.keySuffix, data);
  }

  @override
  Future<bool> isInitialized() => _fileSystem.isInitialized();

  @override
  Future<void> runInitialize() => _fileSystem.runInitialize();
}
