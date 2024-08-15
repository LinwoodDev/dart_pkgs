import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

mixin RemoteFileSystem on GeneralFileSystem {
  @override
  RemoteStorage get storage;

  final client = HttpClient();

  Future<HttpClientResponse?> createRequest(List<String> path,
      {String method = 'GET', List<int>? bodyBytes, String? body}) async {
    final url =
        storage.buildVariantUri(variant: config.currentPathVariant, path: path);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) =>
            String.fromCharCodes(cert.sha1) == storage.certificateSha1;
    if (url == null) return null;
    final request = await client.openUrl(method, url);
    request.headers.add('Authorization',
        'Basic ${base64Encode(utf8.encode('${storage.username}:${await config.passwordStorage.read(storage)}'))}');
    if (body != null) {
      final bytes = utf8.encode(body);
      request.headers.add('Content-Length', bytes.length.toString());
      request.add(bytes);
    } else if (bodyBytes != null) {
      request.headers.add('Content-Length', bodyBytes.length.toString());
      request.add(bodyBytes);
    }
    return request.close();
  }

  Future<Uint8List> getBodyBytes(HttpClientResponse response) async {
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (var chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<String> getBodyString(HttpClientResponse response) async {
    return utf8.decode(await getBodyBytes(response));
  }

  Future<RawFileSystemEntity?> getCachedContent(String path) async {
    if (!storage.hasDocumentCached(path)) return null;
    final absolutePath = await getAbsolutePath(path);
    final file = File(absolutePath);
    if (await file.exists()) {
      return RawFileSystemFile(
        AssetLocation(remote: storage.identifier, path: path),
        data: await file.readAsBytes(),
        cached: true,
      );
    }
    final directory = Directory(absolutePath);
    if (await directory.exists()) {
      return RawFileSystemDirectory(
        AssetLocation(remote: storage.identifier, path: path),
        assets: await directory
            .list()
            .map((e) {
              if (e is File) {
                return RawFileSystemFile(
                  AssetLocation(remote: storage.identifier, path: path),
                  cached: true,
                );
              }
              if (e is Directory) {
                return RawFileSystemDirectory(
                    AssetLocation(remote: storage.identifier, path: path));
              }
              return null;
            })
            .whereNotNull()
            .toList(),
      );
    }
    return null;
  }

  Future<void> cacheContent(String path, Uint8List content) async {
    var absolutePath = await getAbsolutePath(path);
    var file = File(absolutePath);
    final directory = Directory(absolutePath);
    if (await directory.exists()) return;
    if (!(await file.exists())) {
      await file.create(recursive: true);
    }
    await file.writeAsBytes(content);
  }

  Future<void> deleteCachedContent(String path) async {
    var absolutePath = await getAbsolutePath(path);
    var file = File(absolutePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearCachedContent() async {
    var cacheDir = await getDirectory();
    var directory = Directory(cacheDir);
    final exists = await directory.exists();
    int maxRetries = 5;
    int retryCount = 0;

    while (exists && retryCount < maxRetries) {
      try {
        await directory.delete(recursive: true);
        // Directory deleted successfully, exit loop
        return;
      } on FileSystemException catch (e) {
        if (e.osError?.errorCode == 32) {
          // Directory in use, retry after a short delay
          await Future.delayed(const Duration(seconds: 5));
          retryCount++;
        } else if (e.osError?.errorCode == 2) {
          // Directory not found, exit loop
          return;
        } else {
          // Handle unexpected FileSystemException, allowing it to propagate
          rethrow;
        }
      }
    }
    if (retryCount >= maxRetries) {
      throw Exception(
          'Maximum retry limit reached, directory might still be in use.');
    }
  }

  Future<Map<String, Uint8List>> getCachedFiles() async {
    var cacheDir = await getDirectory();
    var files = <String, Uint8List>{};
    var dir = Directory(cacheDir);
    var list = await dir.list().toList();
    for (var file in list) {
      if (file is File) {
        var name = p.relative(file.path, from: cacheDir);
        var content = await file.readAsBytes();
        files[name] = content;
      }
    }
    return files;
  }

  Future<DateTime?> getCachedFileModified(String path) async {
    var absolutePath = await getAbsolutePath(path);
    final file = File(absolutePath);
    if (await file.exists()) {
      return file.lastModified();
    }
    final directory = Directory(absolutePath);
    if (await directory.exists()) {
      return storage.lastSynced;
    }
    return null;
  }

  Future<Map<String, DateTime>> getCachedFileModifieds() async {
    var cacheDir = await getDirectory();
    var files = <String, DateTime>{};
    var dir = Directory(cacheDir);
    var list = await dir.list().toList();
    for (final file in list) {
      final name = p.relative(file.path, from: cacheDir);
      final modified = await getCachedFileModified(name);
      if (modified != null) {
        files[name] = modified;
      }
    }
    return files;
  }

  Future<DateTime?> getRemoteFileModified(String path) async => null;

  Future<SyncFile> getSyncFile(String path) async {
    var localLastModified = await getCachedFileModified(path);
    var remoteLastModified = await getRemoteFileModified(path);
    var syncedLastModified = storage.lastSynced;
    final directory = Directory(await getAbsolutePath(path));

    return SyncFile(
        isDirectory: await directory.exists(),
        location: AssetLocation(remote: storage.identifier, path: path),
        localLastModified: localLastModified,
        remoteLastModified: remoteLastModified,
        syncedLastModified: syncedLastModified);
  }

  Future<List<SyncFile>> getSyncFiles() async {
    var files = <SyncFile>[];
    var cacheDir = await getDirectory();
    var dir = Directory(cacheDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    var list = await dir.list().toList();
    for (var file in list) {
      if (file is File) {
        var name = p.relative(file.path, from: cacheDir);
        var localLastModified = await file.lastModified();
        var remoteLastModified = await getRemoteFileModified(name);
        var syncedLastModified = storage.lastSynced;
        files.add(SyncFile(
            isDirectory: false,
            location: AssetLocation(remote: storage.identifier, path: name),
            localLastModified: localLastModified,
            remoteLastModified: remoteLastModified,
            syncedLastModified: syncedLastModified));
      }
    }
    return files;
  }
}

abstract class RemoteDirectoryFileSystem extends DirectoryFileSystem
    with RemoteFileSystem {
  RemoteDirectoryFileSystem({
    required super.config,
    super.createDefault,
  });

  List<String> getCachedFilePaths() {
    final files = <String>[];

    for (final file
        in storage.cachedDocuments[config.currentCacheVariant] ?? []) {
      final alreadySyncedFile =
          files.firstWhereOrNull((file) => file.startsWith(file));
      if (alreadySyncedFile == file) {
        continue;
      }
      if (alreadySyncedFile != null &&
          alreadySyncedFile.startsWith(file) &&
          !alreadySyncedFile.substring(file.length + 1).contains('/')) {
        files.remove(alreadySyncedFile);
      }
      files.add(file);
    }
    return files;
  }

  Future<List<SyncFile>> getAllSyncFiles() async {
    final paths = getCachedFilePaths();
    final files = <SyncFile>[];
    for (final path in paths) {
      final asset = await getAsset(path);
      if (asset == null) continue;
      files.add(await getSyncFile(asset.path));
      if (asset is RawFileSystemDirectory) {
        for (final file in asset.assets) {
          files.add(await getSyncFile(file.path));
        }
      }
    }
    return files;
  }

  Future<void> uploadCachedContent(String path) async {
    final content = await getCachedContent(path);
    if (content == null) {
      return;
    }
    if (content is RawFileSystemFile) {
      final data = content.data;
      if (data != null) await updateFile(path, data, forceSync: true);
    }
  }

  @override
  Future<void> updateFile(String path, Uint8List data,
      {bool forceSync = false});

  Future<void> cache(String path) async {
    final asset = await getAsset(path);
    if (asset is FileSystemDirectory) {
      var filePath = path;
      if (filePath.startsWith('/')) {
        filePath = filePath.substring(1);
      }
      filePath = p.join(await getDirectory(), filePath);
      final directory = Directory(filePath);
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }
    } else if (asset is RawFileSystemFile) {
      final data = asset.data;
      if (data != null) cacheContent(path, data);
    }
  }
}
