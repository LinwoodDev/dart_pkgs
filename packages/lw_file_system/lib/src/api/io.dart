import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:synchronized/synchronized.dart';

Future<void> _updateFile((String, Uint8List) e) async {
  final file = File(e.$1);
  if (!await file.exists()) {
    await file.create(recursive: true);
  }
  await file.writeAsBytes(e.$2);
}

class IODirectoryFileSystem extends DirectoryFileSystem {
  @override
  final LocalStorage? storage;
  final bool useIsolates;

  final _lock = Lock();

  IODirectoryFileSystem({
    this.storage,
    required super.config,
    super.createDefault,
    this.useIsolates = false,
  });

  String get remoteName => storage?.identifier ?? '';

  @override
  Future<bool> moveAbsolute(String oldPath, String newPath) async {
    if (oldPath.isEmpty) {
      oldPath = await config.getDirectory(storage);
    }
    if (newPath.isEmpty) {
      newPath = await config.getDirectory(storage);
    }
    if (oldPath == newPath) {
      return false;
    }

    final stat = await FileStat.stat(oldPath);
    final type = stat.type;
    if (type == FileSystemEntityType.notFound) return false;

    // Try atomic rename first
    try {
      if (type == FileSystemEntityType.file) {
        await File(oldPath).rename(newPath);
        return true;
      } else if (type == FileSystemEntityType.directory) {
        await Directory(oldPath).rename(newPath);
        return true;
      }
    } catch (_) {
      // Fallback to copy-delete if rename fails (e.g. cross-device)
    }

    if (type == FileSystemEntityType.file) {
      final file = File(oldPath);
      final newFile = File(newPath);
      await newFile.parent.create(recursive: true);
      // Use copy which is more efficient than reading bytes
      await file.copy(newPath);
      await file.delete();
      return true;
    } else if (type == FileSystemEntityType.directory) {
      var oldDirectory = Directory(oldPath);
      var files = await oldDirectory.list().toList();
      for (final file in files) {
        final filePath = file.path.replaceAll('\\', '/');
        final oldPathPosix = oldPath.replaceAll('\\', '/');
        final newPathPosix = newPath.replaceAll('\\', '/');

        final relativePath = universalPathContext.relative(
          filePath,
          from: oldPathPosix,
        );
        final newEntityPath = universalPathContext.join(
          newPathPosix,
          relativePath,
        );

        await moveAbsolute(filePath, newEntityPath);
      }
      await oldDirectory.delete();
      return true;
    }
    return false;
  }

  @override
  Future<Uint8List?> loadAbsolute(String path) async {
    var file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  @override
  Future<RawFileSystemDirectory> createDirectory(String path) async {
    path = normalizePath(path);
    return _lock.synchronized(() async {
      final directory = Directory(await getAbsolutePath(path));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return RawFileSystemDirectory(
        AssetLocation(path: path, remote: remoteName),
        assets: [],
      );
    });
  }

  @override
  Future<FileSystemEntity<Uint8List>?> moveAsset(
    String path,
    String newPath, {
    bool forceSync = false,
  }) async {
    path = normalizePath(path);
    newPath = normalizePath(newPath);
    if (path == newPath) return getAsset(path);

    return _lock.synchronized(() async {
      final oldFile = File(await getAbsolutePath(path));
      final oldDir = Directory(await getAbsolutePath(path));
      final newAbsolutePath = await getAbsolutePath(newPath);

      if (await oldFile.exists()) {
        try {
          await oldFile.rename(newAbsolutePath);
        } catch (_) {
          await oldFile.copy(newAbsolutePath);
          await oldFile.delete();
        }
        return FileSystemFile(
          AssetLocation.local(newPath),
          data: await File(newAbsolutePath).readAsBytes(),
        );
      } else if (await oldDir.exists()) {
        try {
          await oldDir.rename(newAbsolutePath);
        } catch (_) {
          // Fallback for directories is complex, use moveAbsolute logic or similar
          // But moveAbsolute works on absolute paths, so we can use it.
          await moveAbsolute(oldDir.path, newAbsolutePath);
        }
        return getAsset(newPath, listLevel: 0);
      }
      return null;
    });
  }

  @override
  Future<void> deleteAsset(String path) async {
    path = normalizePath(path);
    return _lock.synchronized(() async {
      final absPath = await getAbsolutePath(path);
      final stat = await FileStat.stat(absPath);
      final type = stat.type;
      if (type == FileSystemEntityType.file) {
        await File(absPath).delete();
      } else if (type == FileSystemEntityType.directory) {
        await Directory(absPath).delete(recursive: true);
      }
    });
  }

  @override
  Future<void> updateFile(
    String path,
    Uint8List data, {
    bool forceSync = false,
  }) async {
    path = normalizePath(path);
    path = await getAbsolutePath(path);
    return _lock.synchronized(() async {
      if (useIsolates) {
        await compute(_updateFile, (path, data));
      } else {
        await _updateFile((path, data));
      }
    });
  }

  @override
  Future<FileSystemEntity<Uint8List>?> readAsset(
    String path, {
    bool readData = true,
    bool forceRemote = false,
  }) async {
    path = normalizePath(path);
    final absolutePath = await getAbsolutePath(path);
    final absolutePathPosix = absolutePath.replaceAll('\\', '/');
    final file = File(absolutePath);
    if (await file.exists()) {
      return FileSystemFile(
        AssetLocation(path: path, remote: remoteName),
        data: readData ? await file.readAsBytes() : null,
      );
    }
    final directory = Directory(absolutePath);
    if (await directory.exists()) {
      return FileSystemDirectory(
        AssetLocation(path: path, remote: remoteName),
        assets: (await Future.wait(
          (await directory.list(followLinks: false).toList()).map((e) async {
            final current = universalPathContext.join(
              path,
              universalPathContext.relative(
                e.path.replaceAll('\\', '/'),
                from: absolutePathPosix,
              ),
            );
            if (e is File) {
              return RawFileSystemFile(
                AssetLocation(path: current, remote: remoteName),
                data: readData ? await e.readAsBytes() : null,
              );
            } else if (e is Directory) {
              return RawFileSystemDirectory(
                AssetLocation(path: current, remote: remoteName),
              );
            }
            return null;
          }),
        )).nonNulls.toList(),
      );
    }
    return null;
  }

  @override
  Future<bool> isInitialized() async =>
      Directory(await getDirectory()).exists();

  @override
  Future<void> runInitialize() async {
    await createDirectory('');
    await createDefault(this);
  }
}
