import 'dart:async';

import 'package:archive/archive.dart';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

import 'file_system_dav.dart';
import 'file_system_io.dart';
import 'file_system_html_stub.dart'
    if (dart.library.js_interop) 'file_system_html.dart';

part 'base/directory.dart';
part 'base/key.dart';

typedef CreateDefaultCallback<T extends GeneralFileSystem> =
    FutureOr<void> Function(T fileSystem);

void defaultCreateDefault(GeneralFileSystem fileSystem) {}

abstract class GeneralFileSystem {
  final FileSystemConfig config;

  GeneralFileSystem({required this.config});

  FutureOr<bool> isInitialized();

  Future<void> runInitialize();

  Future<void> reset();

  final _initializeLock = Lock();

  Future<void> initialize({bool force = false}) async {
    return _initializeLock.synchronized(() async {
      if (force) await reset();
      if (force || !await isInitialized()) {
        await runInitialize();
      }
    });
  }

  @protected
  FutureOr<void> runDefault();

  @protected
  bool hasDefault();

  ExternalStorage? get storage => null;

  String normalizePath(String path) => universalPathContext.canonicalize(path);

  String convertNameToFileSystem({
    String? name,
    String? suffix,
    String? directory,
  }) => convertNameToFile(
    name: name,
    suffix: suffix,
    directory: directory,
    getUnnamed: config.getUnnamed,
  );

  Future<String> _findAvailableName(
    String path,
    Future<bool> Function(String) hasAsset,
  ) async {
    final dir = p.dirname(path);
    final fileExtension = p.extension(path);
    final name = p.basenameWithoutExtension(path);
    var newName = name;
    var i = 1;
    while (await hasAsset(
      universalPathContext.join(dir, '$newName$fileExtension'),
    )) {
      newName = '$name ($i)';
      i++;
    }
    return universalPathContext.join(dir, '$newName$fileExtension');
  }

  FutureOr<String> getAbsolutePath(String relativePath) async {
    relativePath = normalizePath(relativePath);
    if (relativePath.startsWith('/')) relativePath = relativePath.substring(1);
    final root = await getDirectory();
    return p.Context(
      style: p.Style.posix,
      current: root,
    ).absolute(relativePath);
  }

  Future<String> getDirectory() async {
    final storage = this.storage;
    if (storage is! LocalStorage) {
      return config.getDirectory(storage);
    }
    final variant = storage.getFullPath(config.currentPathVariant);
    if (variant.isEmpty) {
      return config.getDirectory(storage);
    }
    return variant;
  }

  Future<Uint8List?> loadAbsolute(String path) => Future.value(null);

  Future<void> saveAbsolute(String path, Uint8List bytes) => Future.value();

  Future<bool> moveAbsolute(String oldPath, String newPath) =>
      Future.value(false);
}

Archive exportDirectory(RawFileSystemDirectory directory, {int? lastModTime}) {
  final archive = Archive();
  void addToArchive(RawFileSystemEntity asset) {
    final path = asset.pathWithoutLeadingSlash;
    if (asset is RawFileSystemFile) {
      final data = asset.data;
      if (data == null) return;
      final file = ArchiveFile.bytes(path, data);
      if (lastModTime != null) file.lastModTime = lastModTime;
      archive.addFile(file);
    } else if (asset is RawFileSystemDirectory) {
      archive.addFile(ArchiveFile.directory(path));
      var assets = asset.assets;
      for (var current in assets) {
        addToArchive(current);
      }
    }
  }

  addToArchive(directory);
  return archive;
}
