import 'dart:async';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:rxdart/rxdart.dart';

import 'file_system_dav.dart';
import 'file_system_io.dart';
import 'file_system_html_stub.dart'
    if (dart.library.js) 'file_system_html.dart';

part 'base/directory.dart';
part 'base/key.dart';

typedef CreateDefaultCallback<T extends GeneralFileSystem> = FutureOr<void>
    Function(T fileSystem);

typedef CreateFileCallback = FutureOr<Uint8List> Function(
    String path, Uint8List data);

void defaultCreateDefault(GeneralFileSystem fileSystem) {}

abstract class GeneralFileSystem {
  final FileSystemConfig config;

  GeneralFileSystem({
    required this.config,
  });

  FutureOr<bool> isInitialized();

  Future<void> runInitialize();

  Future<void> reset();

  Future<void> initialize({bool force = false}) async {
    if (force) await reset();
    if (force || !await isInitialized()) {
      await runInitialize();
    }
  }

  @protected
  FutureOr<void> runDefault();

  @protected
  bool hasDefault();

  ExternalStorage? get storage => null;

  String normalizePath(String path, {bool leadingSlash = true}) {
    // Add leading slash
    if (!path.startsWith('/') && leadingSlash) {
      path = '/$path';
    }
    if (path.startsWith('/') && !leadingSlash) {
      path = path.substring(1);
    }
    // Remove trailing slash
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  String convertNameToFile(String name) {
    return name.replaceAll(RegExp(r'[\\/:\*\?"<>\|\n\0-\x1F\x7F-\xFF]'), '_');
  }

  Future<String> _findAvailableName(
      String path, Future<bool> Function(String) hasAsset) async {
    final slashIndex = path.lastIndexOf('/');
    var dir = slashIndex < 0 ? '' : path.substring(0, slashIndex);
    if (dir.isNotEmpty) dir = '$dir/';
    final dotIndex = path.lastIndexOf('.');
    var ext = dotIndex < 0 ? '' : path.substring(dotIndex + 1);
    if (ext.isNotEmpty) ext = '.$ext';
    var name = dotIndex < 0
        ? path.substring(dir.length)
        : path.substring(slashIndex + 1, dotIndex);
    var newName = name;
    var i = 1;
    while (await hasAsset('$dir$newName$ext')) {
      newName = '$name ($i)';
      i++;
    }
    return '$dir$newName$ext';
  }

  FutureOr<String> getAbsolutePath(String relativePath) async {
    // Convert \ to /
    relativePath = relativePath.replaceAll('\\', '/');
    // Remove leading slash
    if (relativePath.startsWith('/')) {
      relativePath = relativePath.substring(1);
    }
    final root = await getDirectory();
    return '$root/$relativePath';
  }

  Future<String> getDirectory() async => config.getDirectory(storage);

  Future<Uint8List?> loadAbsolute(String path) => Future.value(null);

  Future<void> saveAbsolute(String path, Uint8List bytes) => Future.value();

  Future<bool> moveAbsolute(String oldPath, String newPath) =>
      Future.value(false);
}

Archive exportDirectory(FileSystemDirectory directory) {
  final archive = Archive();
  void addToArchive(FileSystemEntity asset) {
    if (asset is FileSystemFile) {
      final data = asset.data;
      if (data == null) return;
      final size = data.length;
      final file = ArchiveFile(asset.pathWithoutLeadingSlash, size, data);
      archive.addFile(file);
    } else if (asset is FileSystemDirectory) {
      var assets = asset.assets;
      for (var current in assets) {
        addToArchive(current);
      }
    }
  }

  addToArchive(directory);
  return archive;
}
