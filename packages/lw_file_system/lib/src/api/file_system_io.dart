import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:lw_file_system/lw_file_system.dart';

class IODirectoryFileSystem extends DirectoryFileSystem {
  @override
  final LocalStorage? storage;

  IODirectoryFileSystem({
    this.storage,
    required super.config,
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
    var oldDirectory = Directory(oldPath);
    if (await oldDirectory.exists()) {
      var files = await oldDirectory.list().toList();
      for (final file in files) {
        final newEntityPath = '$newPath/${file.path.substring(oldPath.length)}';
        if (file is File) {
          var newFile = File(newEntityPath);
          final content = await file.readAsBytes();
          await newFile.parent.create(recursive: true);
          await newFile.create(recursive: true);
          await newFile.writeAsBytes(content);
          await file.delete();
        } else if (file is Directory) {
          await moveAbsolute(file.path, newEntityPath);
        }
      }
    }
    return true;
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
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return RawFileSystemDirectory(
      AssetLocation(path: path, remote: remoteName),
      assets: [],
    );
  }

  @override
  Future<void> deleteAsset(String path) {
    path = normalizePath(path);
    return File(path).delete();
  }

  @override
  Future<void> updateFile(String path, Uint8List data) async {
    path = normalizePath(path);
    final file = File(path);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
  }

  @override
  Future<FileSystemEntity<Uint8List>?> readAsset(String path,
      {bool readData = true}) async {
    path = normalizePath(path);
    final file = File(path);
    if (await file.exists()) {
      return FileSystemFile(
        AssetLocation(path: path, remote: remoteName),
        data: readData ? await file.readAsBytes() : null,
      );
    }
    final directory = Directory(path);
    if (await directory.exists()) {
      return FileSystemDirectory(
        AssetLocation(path: path, remote: remoteName),
        assets: (await directory.list(followLinks: false).toList())
            .map((e) {
              if (e is File) {
                return RawFileSystemFile(
                  AssetLocation(path: e.path, remote: remoteName),
                  data: readData ? e.readAsBytesSync() : null,
                );
              } else if (e is Directory) {
                return RawFileSystemDirectory(
                  AssetLocation(path: e.path, remote: remoteName),
                  assets: [],
                );
              }
              return null;
            })
            .whereNotNull()
            .toList(),
      );
    }
    return null;
  }
}
