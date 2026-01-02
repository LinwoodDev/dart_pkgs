import 'dart:async';
import 'dart:typed_data';

import 'package:lw_file_system/lw_file_system.dart';

class MockFileSystem extends DirectoryFileSystem {
  final Map<String, Uint8List> _files = {};
  bool _initialized = false;

  MockFileSystem({required super.config, super.createDefault});

  @override
  FutureOr<bool> isInitialized() => _initialized;

  @override
  Future<void> runInitialize() async {
    _initialized = true;
    await runDefault();
  }

  @override
  Future<void> reset() async {
    _files.clear();
    _initialized = false;
  }

  @override
  Future<Uint8List?> loadAbsolute(String path) async {
    return _files[path];
  }

  @override
  Future<void> saveAbsolute(String path, Uint8List bytes) async {
    _files[path] = bytes;
  }

  @override
  Future<bool> moveAbsolute(String oldPath, String newPath) async {
    if (_files.containsKey(oldPath)) {
      _files[newPath] = _files[oldPath]!;
      _files.remove(oldPath);
      return true;
    }
    return false;
  }

  @override
  Future<FileSystemDirectory<Uint8List>> createDirectory(String path) async {
    return FileSystemDirectory(
      AssetLocation(path: normalizePath(path), remote: ''),
    );
  }

  @override
  Future<void> updateFile(
    String path,
    Uint8List data, {
    bool forceSync = false,
  }) async {
    _files[normalizePath(path)] = data;
  }

  @override
  Future<void> deleteAsset(String path) async {
    path = normalizePath(path);
    _files.remove(path);
    final prefix = '$path/';
    _files.removeWhere((key, value) => key.startsWith(prefix));
  }

  @override
  Future<FileSystemEntity<Uint8List>?> moveAsset(
    String path,
    String newPath, {
    bool forceSync = false,
  }) async {
    path = normalizePath(path);
    newPath = normalizePath(newPath);

    if (_files.containsKey(path)) {
      final data = _files[path]!;
      _files.remove(path);
      _files[newPath] = data;
      return FileSystemFile(
        AssetLocation(path: newPath, remote: ''),
        data: data,
      );
    }

    final prefix = '$path/';
    final keysToMove = _files.keys.where((k) => k.startsWith(prefix)).toList();
    if (keysToMove.isNotEmpty) {
      for (final key in keysToMove) {
        final suffix = key.substring(prefix.length);
        final newKey = '$newPath/$suffix';
        _files[newKey] = _files[key]!;
        _files.remove(key);
      }
      return FileSystemDirectory(AssetLocation(path: newPath, remote: ''));
    }

    return null;
  }

  @override
  Future<FileSystemEntity<Uint8List>?> readAsset(
    String path, {
    bool readData = true,
    bool forceRemote = false,
  }) async {
    path = normalizePath(path);

    if (_files.containsKey(path)) {
      return FileSystemFile(
        AssetLocation(path: path, remote: ''),
        data: readData ? _files[path] : null,
      );
    }

    final prefix = path.isEmpty ? '' : '$path/';
    final children = _files.keys
        .where((k) => k.startsWith(prefix) && k != path)
        .toList();

    if (children.isEmpty && path.isNotEmpty) {
      return null;
    }

    final assets = <FileSystemEntity<Uint8List>>[];
    final seen = <String>{};

    for (final childPath in children) {
      final relative = childPath.substring(prefix.length);
      final parts = relative.split('/');
      final name = parts.first;
      if (seen.contains(name)) continue;
      seen.add(name);

      final fullChildPath = prefix + name;
      if (_files.containsKey(fullChildPath)) {
        assets.add(
          FileSystemFile(
            AssetLocation(path: fullChildPath, remote: ''),
            data: readData ? _files[fullChildPath] : null,
          ),
        );
      } else {
        assets.add(
          FileSystemDirectory(AssetLocation(path: fullChildPath, remote: '')),
        );
      }
    }

    return FileSystemDirectory(
      AssetLocation(path: path, remote: ''),
      assets: assets,
    );
  }

  void addFile(String path, Uint8List content) {
    _files[normalizePath(path)] = content;
  }
}

class MockKeyFileSystem extends KeyFileSystem {
  final Map<String, Uint8List> _files = {};
  bool _initialized = false;

  MockKeyFileSystem({required super.config, super.createDefault});

  @override
  FutureOr<bool> isInitialized() => _initialized;

  @override
  Future<void> runInitialize() async {
    _initialized = true;
    await runDefault();
  }

  @override
  Future<void> reset() async {
    _files.clear();
    _initialized = false;
  }

  @override
  Future<Uint8List?> loadAbsolute(String path) async {
    return _files[path];
  }

  @override
  Future<void> saveAbsolute(String path, Uint8List bytes) async {
    _files[path] = bytes;
  }

  @override
  Future<bool> moveAbsolute(String oldPath, String newPath) async {
    if (_files.containsKey(oldPath)) {
      _files[newPath] = _files[oldPath]!;
      _files.remove(oldPath);
      return true;
    }
    return false;
  }

  @override
  Future<Uint8List?> getFile(String key) async {
    return _files[normalizePath(key)];
  }

  @override
  Future<bool> hasKey(String key) async {
    return _files.containsKey(normalizePath(key));
  }

  @override
  Future<void> updateFile(String key, Uint8List data) async {
    _files[normalizePath(key)] = data;
  }

  @override
  Future<void> deleteFile(String key) async {
    _files.remove(normalizePath(key));
  }

  @override
  Future<List<String>> getKeys() async {
    return _files.keys.toList();
  }
}
