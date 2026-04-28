import 'package:flutter/services.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:synchronized/synchronized.dart';

import 'io.dart';

class AndroidSafDirectoryFileSystem extends DirectoryFileSystem {
  static const MethodChannel _channel = MethodChannel(
    'linwood.dev/lw_file_system/saf',
  );

  @override
  final LocalStorage? storage;
  final bool useIsolates;
  final _lock = Lock();

  late final IODirectoryFileSystem _io = IODirectoryFileSystem(
    storage: storage,
    config: config,
    useIsolates: useIsolates,
  );

  AndroidSafDirectoryFileSystem({
    this.storage,
    required super.config,
    super.createDefault,
    this.useIsolates = false,
  });

  static bool isSafStorage(String path) => path.startsWith('content://');

  static Future<String?> pickDirectory() =>
      _channel.invokeMethod<String>('pickDirectory');

  Future<bool> isSaf() async => isSafStorage(await getDirectory());

  @override
  Future<String> getDirectory() async {
    final storage = this.storage;
    if (storage is! LocalStorage) return config.getDirectory(storage);

    final variant = config.currentPathVariant;
    final variantPath = storage.paths[variant];
    final basePath = storage.getBasePath();

    String path;
    if (variantPath != null && isSafStorage(variantPath)) {
      path = variantPath;
    } else if (variantPath != null && isSafStorage(basePath)) {
      path = _joinSafPath(basePath, variantPath);
    } else {
      path = storage.getFullPath(variant);
    }

    if (path.isEmpty) return config.getDirectory(storage);
    return path;
  }

  String _getSafRootUri() {
    final storage = this.storage;
    if (storage == null) return '';

    final variantPath = storage.paths[config.currentPathVariant];
    if (variantPath != null && isSafStorage(variantPath)) return variantPath;

    final basePath = storage.getBasePath();
    return isSafStorage(basePath) ? basePath : '';
  }

  Future<String> _getSafRootPath() async {
    final directory = await getDirectory();
    final rootUri = _getSafRootUri();
    if (directory.isEmpty || rootUri.isEmpty || directory == rootUri) return '';
    if (!directory.startsWith('$rootUri/')) return '';
    return _normalizeSafPath(directory.substring(rootUri.length + 1));
  }

  Future<String> _toSafPath(String path) async {
    path = _normalizeSafPath(path);
    final rootPath = await _getSafRootPath();
    if (rootPath.isEmpty) return path;
    return _normalizeSafPath(universalPathContext.join(rootPath, path));
  }

  Future<String> _fromSafPath(String path) async {
    path = _normalizeSafPath(path);
    final rootPath = await _getSafRootPath();
    if (rootPath.isEmpty) return path;
    if (path == rootPath) return '';
    if (path.startsWith('$rootPath/')) {
      return _normalizeSafPath(path.substring(rootPath.length + 1));
    }
    return path;
  }

  String _normalizeSafPath(String path) {
    path = normalizePath(path);
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    return path;
  }

  String _joinSafPath(String root, String path) {
    path = _normalizeSafPath(path);
    if (path.isEmpty) return root;
    while (root.endsWith('/')) {
      root = root.substring(0, root.length - 1);
    }
    return '$root/$path';
  }

  @override
  Future<String> getAbsolutePath(String relativePath) async {
    final rootUri = await getDirectory();
    if (!isSafStorage(rootUri)) return _io.getAbsolutePath(relativePath);
    if (isSafStorage(relativePath)) return relativePath;
    return _joinSafPath(rootUri, relativePath);
  }

  @override
  Future<String?> toRelativePath(String path) async {
    final rootUri = await getDirectory();
    if (!isSafStorage(rootUri)) return _io.toRelativePath(path);
    if (!isSafStorage(path)) return normalizePath(path);
    if (path == rootUri) return '';
    if (path.startsWith('$rootUri/')) {
      return _normalizeSafPath(path.substring(rootUri.length + 1));
    }
    return null;
  }

  @override
  Future<RawFileSystemDirectory> createDirectory(String path) async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) return _io.createDirectory(path);
    final rootUri = _getSafRootUri();
    path = normalizePath(path);
    await _lock.synchronized(
      () async => _channel.invokeMethod<void>('safCreateDirectory', {
        'rootUri': rootUri,
        'path': await _toSafPath(path),
      }),
    );
    return RawFileSystemDirectory(
      AssetLocation(path: path, remote: storage?.identifier ?? ''),
      assets: [],
    );
  }

  @override
  Future<void> deleteAsset(String path) async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) return _io.deleteAsset(path);
    final rootUri = _getSafRootUri();
    path = normalizePath(path);
    await _lock.synchronized(
      () async => _channel.invokeMethod<void>('safDeleteAsset', {
        'rootUri': rootUri,
        'path': await _toSafPath(path),
      }),
    );
  }

  @override
  Future<bool> hasAsset(String path) async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) return _io.hasAsset(path);
    final rootUri = _getSafRootUri();
    path = normalizePath(path);
    return _channel
        .invokeMethod<bool>('safExists', {
          'rootUri': rootUri,
          'path': await _toSafPath(path),
        })
        .then((value) => value ?? false);
  }

  @override
  Future<void> updateFile(
    String path,
    Uint8List data, {
    bool forceSync = false,
  }) async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) {
      return _io.updateFile(path, data, forceSync: forceSync);
    }
    final rootUri = _getSafRootUri();
    path = normalizePath(path);
    await _lock.synchronized(
      () async => _channel.invokeMethod<void>('safWriteFile', {
        'rootUri': rootUri,
        'path': await _toSafPath(path),
        'data': data,
      }),
    );
  }

  @override
  Future<RawFileSystemEntity?> readAsset(
    String path, {
    bool readData = true,
    bool forceRemote = false,
  }) async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) {
      return _io.readAsset(path, readData: readData, forceRemote: forceRemote);
    }
    final rootUri = _getSafRootUri();
    path = normalizePath(path);
    final safPath = await _toSafPath(path);
    final map = await _channel.invokeMapMethod<String, Object?>(
      'safReadAsset',
      {'rootUri': rootUri, 'path': safPath, 'readData': readData},
    );
    return map == null ? null : await _entityFromMap(map);
  }

  @override
  Future<RawFileSystemEntity?> moveAsset(
    String path,
    String newPath, {
    bool forceSync = false,
  }) async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) {
      return _io.moveAsset(path, newPath, forceSync: forceSync);
    }
    path = normalizePath(path);
    newPath = normalizePath(newPath);
    if (path == newPath) return getAsset(path);

    return _lock.synchronized(() async {
      final entity = await getAsset(path, listLevel: allListLevel);
      if (entity == null) return null;
      await _copyEntity(entity, newPath, forceSync: forceSync);
      await deleteAsset(path);
      return getAsset(newPath, listLevel: noListLevel);
    });
  }

  @override
  Future<Uint8List?> loadAbsolute(String path) async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) return _io.loadAbsolute(path);
    return _channel.invokeMethod<Uint8List>('safReadAbsolute', {'uri': path});
  }

  @override
  Future<void> saveAbsolute(String path, Uint8List bytes) async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) return _io.saveAbsolute(path, bytes);
    return super.saveAbsolute(path, bytes);
  }

  @override
  Future<bool> moveAbsolute(String oldPath, String newPath) async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) return _io.moveAbsolute(oldPath, newPath);
    final rootUri = _getSafRootUri();
    if (oldPath == newPath) return false;
    if (oldPath == rootUri && newPath.startsWith('content://')) {
      return await _channel.invokeMethod<bool>('copySafToSaf', {
            'sourceRootUri': oldPath,
            'targetRootUri': newPath,
          }) ??
          false;
    }
    if (oldPath == rootUri) {
      return await _channel.invokeMethod<bool>('exportSafToPath', {
            'rootUri': oldPath,
            'targetPath': newPath,
          }) ??
          false;
    }
    if (newPath == rootUri) {
      return await _channel.invokeMethod<bool>('importPathToSaf', {
            'sourcePath': oldPath,
            'rootUri': newPath,
          }) ??
          false;
    }
    return false;
  }

  @override
  Future<bool> isInitialized() async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) return _io.isInitialized();
    final rootUri = _getSafRootUri();
    final rootPath = await _getSafRootPath();
    return _channel
        .invokeMethod<bool>('safExists', {'rootUri': rootUri, 'path': rootPath})
        .then((value) => value ?? false);
  }

  @override
  Future<void> runInitialize() async {
    await createDirectory('');
    await createDefault(this);
  }

  Future<void> _copyEntity(
    RawFileSystemEntity entity,
    String targetPath, {
    bool forceSync = false,
  }) async {
    if (entity is RawFileSystemFile) {
      final data = entity.data;
      if (data == null) return;
      await updateFile(targetPath, data, forceSync: forceSync);
    } else if (entity is RawFileSystemDirectory) {
      await createDirectory(targetPath);
      for (final child in entity.assets) {
        await _copyEntity(
          child,
          universalPathContext.join(targetPath, child.fileName),
          forceSync: forceSync,
        );
      }
    }
  }

  Future<RawFileSystemEntity> _entityFromMap(Map<String, Object?> map) async {
    final path = await _fromSafPath(map['path'] as String? ?? '');
    final location = AssetLocation(
      path: path,
      remote: storage?.identifier ?? '',
    );
    final lastModified = _dateFromMillis(map['lastModified']);
    final size = (map['size'] as num?)?.toInt();
    if (map['isDirectory'] == true) {
      final assets = await Future.wait(
        (map['assets'] as List?)
                ?.whereType<Map>()
                .map((e) => _entityFromMap(e.cast<String, Object?>()))
                .toList() ??
            const <Future<RawFileSystemEntity>>[],
      );
      return RawFileSystemDirectory(
        location,
        assets: assets,
        lastModified: lastModified,
        size: size,
      );
    }
    return RawFileSystemFile(
      location,
      data: map['data'] as Uint8List?,
      lastModified: lastModified,
      size: size,
    );
  }

  DateTime? _dateFromMillis(Object? value) {
    final millis = (value as num?)?.toInt();
    return millis == null || millis <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
