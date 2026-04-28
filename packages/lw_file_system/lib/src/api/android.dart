import 'dart:async';

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
  Future<String?> toRelativePath(String path) async {
    final root = await getDirectory();
    if (!isSafStorage(root)) {
      if (isSafStorage(path)) {
        return null;
      }
      return super.toRelativePath(path);
    }
    if (isSafStorage(path)) {
      if (path.startsWith(root)) {
        return path.substring(root.length).replaceFirst(RegExp(r'^/'), '');
      }
      return null;
    }
    return path;
  }

  @override
  Future<String> getAbsolutePath(String relativePath) async {
    if (isSafStorage(relativePath)) {
      return relativePath;
    }
    final directory = await getDirectory();
    if (isSafStorage(directory)) {
      return '$directory/${relativePath.replaceFirst(RegExp(r'^/'), '')}';
    }
    return super.getAbsolutePath(relativePath);
  }

  @override
  Future<RawFileSystemDirectory> createDirectory(String path) async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) return _io.createDirectory(path);
    path = normalizePath(path);
    await _lock.synchronized(
      () async => _channel.invokeMethod<void>('safCreateDirectory', {
        'rootUri': directory,
        'path': await toRelativePath(path),
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
    path = normalizePath(path);
    await _lock.synchronized(
      () async => _channel.invokeMethod<void>('safDeleteAsset', {
        'rootUri': directory,
        'path': await toRelativePath(path),
      }),
    );
  }

  @override
  Future<bool> hasAsset(String path) async {
    final directory = await getDirectory();
    if (!isSafStorage(directory)) return _io.hasAsset(path);
    path = normalizePath(path);
    return _channel
        .invokeMethod<bool>('safExists', {
          'rootUri': directory,
          'path': await toRelativePath(path),
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
    path = normalizePath(path);
    await _lock.synchronized(
      () async => _channel.invokeMethod<void>('safWriteFile', {
        'rootUri': directory,
        'path': await toRelativePath(path),
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
    path = normalizePath(path);
    final safPath = await toRelativePath(path);
    final map = await _channel.invokeMapMethod<String, Object?>(
      'safReadAsset',
      {'rootUri': directory, 'path': safPath, 'readData': readData},
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
    if (oldPath == newPath) return false;
    if (oldPath == directory && isSafStorage(newPath)) {
      return await _channel.invokeMethod<bool>('copySafToSaf', {
            'sourceRootUri': oldPath,
            'targetRootUri': newPath,
          }) ??
          false;
    }
    if (oldPath == directory) {
      return await _channel.invokeMethod<bool>('exportSafToPath', {
            'rootUri': oldPath,
            'targetPath': newPath,
          }) ??
          false;
    }
    if (newPath == directory) {
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
    return _channel
        .invokeMethod<bool>('safExists', {'rootUri': directory})
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
    final path = await toRelativePath(map['path'] as String? ?? '');
    final location = AssetLocation(
      path: path ?? '',
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
