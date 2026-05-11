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

  static Future<String?> pickDirectory() {
    return _channel.invokeMethod<String>('pickDirectory');
  }

  @override
  Future<void> release() async {
    final directory = await getDirectory();

    if (!isSafStorage(directory)) {
      return _io.release();
    }

    await _channel.invokeMethod<void>('releasePersistableUriPermission', {
      'uri': directory,
    });
  }

  Future<bool> isSaf() async {
    return isSafStorage(await getDirectory());
  }

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
        return normalizeRelativePath(path.substring(root.length));
      }

      return null;
    }

    return normalizeRelativePath(path);
  }

  @override
  Future<String> getAbsolutePath(String relativePath) async {
    if (isSafStorage(relativePath)) {
      return relativePath;
    }

    final directory = await getDirectory();

    if (isSafStorage(directory)) {
      final normalizedRelativePath = normalizeRelativePath(relativePath);

      if (normalizedRelativePath.isEmpty) {
        return directory;
      }

      return '$directory/$normalizedRelativePath';
    }

    return super.getAbsolutePath(relativePath);
  }

  @override
  Future<RawFileSystemDirectory> createDirectory(String path) async {
    final directory = await getDirectory();

    if (!isSafStorage(directory)) {
      return _io.createDirectory(path);
    }

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

    if (!isSafStorage(directory)) {
      return _io.deleteAsset(path);
    }

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

    if (!isSafStorage(directory)) {
      return _io.hasAsset(path);
    }

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

    if (path == newPath) {
      return getAsset(path);
    }

    final moved =
        await _lock.synchronized(
          () async => _channel.invokeMethod<bool>('safMoveAsset', {
            'rootUri': directory,
            'path': await toRelativePath(path),
            'newPath': await toRelativePath(newPath),
          }),
        ) ??
        false;

    if (!moved) {
      return null;
    }

    return getAsset(newPath, listLevel: noListLevel);
  }

  @override
  Future<Uint8List?> loadAbsolute(String path) async {
    final directory = await getDirectory();

    if (!isSafStorage(directory)) {
      return _io.loadAbsolute(path);
    }

    if (isSafStorage(path) && path.startsWith(directory)) {
      return _channel.invokeMethod<Uint8List>('safReadAbsolute', {
        'uri': directory,
        'path': await toRelativePath(path),
      });
    }

    return _channel.invokeMethod<Uint8List>('safReadAbsolute', {'uri': path});
  }

  @override
  Future<void> saveAbsolute(String path, Uint8List bytes) async {
    final directory = await getDirectory();

    if (!isSafStorage(directory)) {
      return _io.saveAbsolute(path, bytes);
    }

    if (isSafStorage(path) && path.startsWith(directory)) {
      final relativePath = await toRelativePath(path);

      if (relativePath == null) {
        return;
      }

      return updateFile(relativePath, bytes);
    }

    if (!isSafStorage(path) && universalPathContext.isRelative(path)) {
      return updateFile(path, bytes);
    }

    return super.saveAbsolute(path, bytes);
  }

  @override
  Future<bool> moveAbsolute(String oldPath, String newPath) async {
    final directory = await getDirectory();

    if (oldPath.isEmpty) {
      oldPath = directory;
    }
    if (newPath.isEmpty) {
      newPath = directory;
    }
    if (oldPath == newPath) {
      return false;
    }

    final oldPathIsSaf = isSafStorage(oldPath);
    final newPathIsSaf = isSafStorage(newPath);

    if (!oldPathIsSaf && !newPathIsSaf) {
      return _io.moveAbsolute(oldPath, newPath);
    }

    if (oldPathIsSaf && newPathIsSaf) {
      return await _channel.invokeMethod<bool>('copySafToSaf', {
            'sourceRootUri': oldPath,
            'targetRootUri': newPath,
          }) ??
          false;
    }

    if (oldPathIsSaf) {
      return await _channel.invokeMethod<bool>('exportSafToPath', {
            'rootUri': oldPath,
            'targetPath': newPath,
          }) ??
          false;
    }

    if (newPathIsSaf) {
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

    if (!isSafStorage(directory)) {
      return _io.isInitialized();
    }

    return _channel
        .invokeMethod<bool>('safExists', {'rootUri': directory, 'path': ''})
        .then((value) => value ?? false);
  }

  @override
  Future<void> runInitialize() async {
    await createDirectory('');
    await createDefault(this);
  }

  Future<String?> resolveSafUri(String path) async {
    final directory = await getDirectory();

    if (!isSafStorage(directory)) {
      return getAbsolutePath(path);
    }

    return _channel.invokeMethod<String>('safResolveUri', {
      'rootUri': directory,
      'path': await toRelativePath(path),
    });
  }

  Future<RawFileSystemEntity> _entityFromMap(Map<String, Object?> map) async {
    final path = normalizeRelativePath(map['path'] as String? ?? '');

    final location = AssetLocation(
      path: path,
      remote: storage?.identifier ?? '',
    );

    final lastModified = _dateFromMillis(map['lastModified']);
    final size = (map['size'] as num?)?.toInt();

    if (map['isDirectory'] == true) {
      final assets = await Future.wait(
        (map['assets'] as List?)?.whereType<Map>().map((entry) {
              return _entityFromMap(entry.cast<String, Object?>());
            }).toList() ??
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
