import 'dart:async';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:rxdart/rxdart.dart';

import 'file_system_dav.dart';
import 'file_system_io.dart';
import 'file_system_html_stub.dart'
    if (dart.library.js) 'file_system_html.dart';

typedef FileDisplayCallback<T> = (T?, Uint8List?) Function(List<int> data);
typedef InitFSCallback = FutureOr<void> Function(GeneralFileSystem fileSystem);
typedef CreateFileCallback = FutureOr<Uint8List> Function(
    String path, Uint8List data);
typedef EncodeFileCallback<T> = FutureOr<Uint8List> Function(T);
typedef DecodeFileCallback<T> = FutureOr<T> Function(Uint8List);

Future<AppDocumentFile<T>> getAppDocumentFile<T>(
  AssetLocation location,
  Uint8List data, {
  bool cached = false,
  bool readMetadata = true,
  FileDisplayCallback<T>? onFileDisplay,
}) async {
  final (metadata, thumbnail) = (readMetadata && onFileDisplay != null)
      ? await compute(onFileDisplay, data)
      : (null, null);
  return AppDocumentFile(
    location,
    data: data,
    metadata: metadata,
    thumbnail: thumbnail,
    cached: cached,
  );
}

abstract class GeneralFileSystem<T> {
  final InitFSCallback onInit;
  final FileDisplayCallback? onFileDisplay;
  final FileSystemConfig config;

  GeneralFileSystem({
    this.onInit = _defaultInit,
    this.onFileDisplay,
    required this.config,
  });

  static Future<void> _defaultInit(GeneralFileSystem fileSystem) async {}

  RemoteStorage? get remote => null;

  String normalizePath(String path) {
    // Add leading slash
    if (!path.startsWith('/')) {
      path = '/$path';
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

  FutureOr<String> getDirectory() => '/';
}

abstract class DirectoryFileSystem<T> extends GeneralFileSystem<T> {
  DirectoryFileSystem({required super.config});

  Future<AppDocumentDirectory> getRootDirectory([bool recursive = false]) {
    return getAsset('', recursive ? null : true)
        .then((value) => value as AppDocumentDirectory);
  }

  @override
  FutureOr<String> getDirectory();

  /// If listFiles is null, it will fetch recursively
  Stream<AppDocumentEntity<T>?> fetchAsset(String path,
      [bool? listFiles = true]);

  Stream<List<AppDocumentEntity<T>>> fetchAssets(Stream<String> paths,
      [bool? listFiles = true]) {
    final files = <AppDocumentEntity<T>>[];
    final streams = paths.asyncExpand((e) async* {
      int? index;
      await for (final file in fetchAsset(e, listFiles)) {
        if (file == null) continue;
        if (index == null) {
          index = files.length;
          files.add(file);
        } else {
          files[index] = file;
        }
        yield null;
      }
    });
    return streams.map((event) => files);
  }

  Stream<List<AppDocumentEntity<T>>> fetchAssetsSync(Iterable<String> paths,
          [bool? listFiles = true]) =>
      fetchAssets(Stream.fromIterable(paths), listFiles);

  static Stream<List<AppDocumentEntity<T>>> fetchAssetsGlobal<T>(
      Stream<AssetLocation> locations,
      Map<String, DirectoryFileSystem<T>> fileSystems,
      [bool? listFiles = true]) {
    final files = <AppDocumentEntity<T>>[];
    final streams = locations.asyncExpand((e) async* {
      final fileSystem = fileSystems[e.remote];
      if (fileSystem == null) return;
      int? index;
      await for (final file
          in fileSystem.fetchAsset(e.path, listFiles).whereNotNull()) {
        if (index == null) {
          index = files.length;
          files.add(file);
        } else {
          files[index] = file;
        }
        yield null;
      }
    });
    return streams.map((event) => files);
  }

  static Stream<List<AppDocumentEntity<T>>> fetchAssetsGlobalSync<T>(
          Iterable<AssetLocation> locations,
          Map<String, DirectoryFileSystem<T>> fileSystems,
          [bool? listFiles = true]) =>
      fetchAssetsGlobal(Stream.fromIterable(locations), fileSystems, listFiles);

  Future<AppDocumentEntity<T>?> getAsset(String path,
          [bool? listFiles = true]) =>
      fetchAsset(path, listFiles).last;

  Future<AppDocumentDirectory<T>> createDirectory(String path);

  Future<void> updateFile(String path, List<int> data);

  Future<String> findAvailableName(String path) =>
      _findAvailableName(path, hasAsset);

  Future<AppDocumentFile<T>?> createFile(String path, Uint8List data) async {
    path = normalizePath(path);
    final uniquePath = await findAvailableName(path);
    return updateFile(uniquePath, data)
        .then((_) => getAppDocumentFile(AssetLocation.local(uniquePath), data));
  }

  Future<bool> hasAsset(String path);

  Future<void> deleteAsset(String path);

  Future<AppDocumentEntity<T>?> renameAsset(String path, String newName) async {
    path = normalizePath(path);
    if (newName.startsWith('/')) {
      newName = newName.substring(1);
    }
    final asset = await getAsset(path);
    if (asset == null) return null;
    final newPath = '${path.substring(0, path.lastIndexOf('/') + 1)}$newName';
    return moveAsset(path, newPath);
  }

  Future<AppDocumentEntity<T>?> duplicateAsset(
      String path, String newPath) async {
    path = normalizePath(path);
    final asset = await getAsset(path);
    if (asset == null) return null;
    if (asset is AppDocumentFile<T>) {
      final data = asset.data;
      if (data != null) {
        return createFile(newPath, data);
      }
    } else if (asset is AppDocumentDirectory<T>) {
      var newDir = await createDirectory(newPath);
      for (var child in asset.assets) {
        await duplicateAsset(
            '$path/${child.fileName}', '$newPath/${child.fileName}');
      }
      return newDir;
    }
    return null;
  }

  Future<AppDocumentEntity<T>?> moveAsset(String path, String newPath) async {
    var asset = await duplicateAsset(path, newPath);
    if (asset == null) return null;
    if (path != newPath) await deleteAsset(path);
    return asset;
  }

  static DirectoryFileSystem<T> fromPlatform<T>(FileSystemConfig config,
      {final ExternalStorage? remote}) {
    if (kIsWeb) {
      return WebDocumentFileSystem(config: config);
    } else {
      return switch (remote) {
        DavRemoteStorage e => DavRemoteDocumentFileSystem<T>(e),
        LocalStorage e =>
          IODocumentFileSystem<T>(e.getBasePath(), remote.identifier),
        _ => IODocumentFileSystem<T>(),
      };
    }
  }

  Future<bool> moveAbsolute(String oldPath, String newPath) =>
      Future.value(false);

  Future<Uint8List?> loadAbsolute(String path) => Future.value(null);

  Future<void> saveAbsolute(String path, Uint8List bytes) => Future.value();
}

abstract class KeyFileSystem<T> extends GeneralFileSystem<T> {
  KeyFileSystem({
    required super.config,
    super.onFileDisplay,
    super.onInit,
  });

  Future<Uint8List?> getFile(String key);

  Future<Uint8List?> getDefaultFile(String key) async =>
      await getFile(key) ??
      await getFiles().then((value) => value.firstOrNull?.data);

  Future<String> findAvailableKey(String path) =>
      _findAvailableName(path, hasKey);

  Future<String> createFile(String key, Uint8List data) async {
    key = normalizePath(key);
    final name = findAvailableKey(key);
    await updateFile(key, data);
    return name;
  }

  Future<bool> hasKey(String name);
  Future<void> updateFile(String key, Uint8List data);
  Future<void> deleteFile(String key);
  Future<List<AppDocumentFile<T>>> getFiles();

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

  static KeyFileSystem<T> fromPlatform<T>(FileSystemConfig config,
      {ExternalStorage? remote}) {
    if (kIsWeb) {
      return WebTemplateFileSystem(config: config);
    } else {
      return switch (remote) {
        DavRemoteStorage storage => DavRemoteTemplateFileSystem<T>(storage),
        LocalStorage storage => IOTemplateFileSystem<T>(storage.getBasePath()),
        _ => IOTemplateFileSystem<T>(),
      };
    }
  }
}

Archive exportDirectory(AppDocumentDirectory directory) {
  final archive = Archive();
  void addToArchive(AppDocumentEntity asset) {
    if (asset is AppDocumentFile) {
      final data = asset.data;
      final size = data.length;
      final file = ArchiveFile(asset.pathWithoutLeadingSlash, size, data);
      archive.addFile(file);
    } else if (asset is AppDocumentDirectory) {
      var assets = asset.assets;
      for (var current in assets) {
        addToArchive(current);
      }
    }
  }

  addToArchive(directory);
  return archive;
}
