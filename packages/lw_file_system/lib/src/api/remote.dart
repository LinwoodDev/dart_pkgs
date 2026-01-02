import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

mixin RemoteFileSystem on GeneralFileSystem {
  @override
  RemoteStorage get storage;

  final client = HttpClient();

  Future<HttpClientResponse?> createRequest(
    List<String> path, {
    String method = 'GET',
    List<int>? bodyBytes,
    String? body,
    Map<String, String>? headers,
  }) async {
    final url = storage.buildVariantUri(
      variant: config.currentPathVariant,
      path: path,
    );
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) =>
            String.fromCharCodes(cert.sha1) == storage.certificateSha1;
    if (url == null) return null;
    final request = await client.openUrl(method, url);
    request.headers.add(
      'Authorization',
      'Basic ${base64Encode(utf8.encode('${storage.username}:${await config.passwordStorage.read(storage)}'))}',
    );
    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
    }
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
                  AssetLocation(remote: storage.identifier, path: path),
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
        'Maximum retry limit reached, directory might still be in use.',
      );
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
      syncedLastModified: syncedLastModified,
    );
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
        files.add(
          SyncFile(
            isDirectory: false,
            location: AssetLocation(remote: storage.identifier, path: name),
            localLastModified: localLastModified,
            remoteLastModified: remoteLastModified,
            syncedLastModified: syncedLastModified,
          ),
        );
      }
    }
    return files;
  }
}

abstract class RemoteDirectoryFileSystem extends DirectoryFileSystem
    with RemoteFileSystem {
  RemoteDirectoryFileSystem({required super.config, super.createDefault}) {
    _loadQueue();
  }

  final List<SyncOperation> _syncQueue = [];
  bool _isSyncing = false;

  Future<File> get _queueFile async {
    final dir = await getDirectory();
    return File(p.join(dir, '.sync_queue.json'));
  }

  Future<void> _loadQueue() async {
    try {
      final file = await _queueFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = jsonDecode(content);
        _syncQueue.clear();
        _syncQueue.addAll(list.map((e) => SyncOperation.fromJson(e)));
        _triggerSync();
      }
    } catch (e) {
      debugPrint('Error loading sync queue: $e');
    }
  }

  Future<void> _saveQueue() async {
    try {
      final file = await _queueFile;
      await file.writeAsString(
        jsonEncode(_syncQueue.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving sync queue: $e');
    }
  }

  Future<void> _addToQueue(SyncOperation op) async {
    if (op.type == SyncOperationType.update) {
      _syncQueue.removeWhere((e) {
        if (e.type == SyncOperationType.update && e.path == op.path) {
          if (_isSyncing && _syncQueue.isNotEmpty && e == _syncQueue.first) {
            return false;
          }
          return true;
        }
        return false;
      });
    }
    _syncQueue.add(op);
    await _saveQueue();
    _triggerSync();
  }

  Future<void> _triggerSync() async {
    if (_isSyncing || _syncQueue.isEmpty) return;
    _isSyncing = true;

    try {
      while (_syncQueue.isNotEmpty) {
        final op = _syncQueue.first;
        try {
          switch (op.type) {
            case SyncOperationType.update:
              final absolutePath = await getAbsolutePath(op.path);
              final file = File(absolutePath);
              if (await file.exists()) {
                final data = await file.readAsBytes();
                await uploadFile(op.path, data);
              }
              break;
            case SyncOperationType.delete:
              await deleteRemoteAsset(op.path);
              break;
            case SyncOperationType.move:
              if (op.destination != null) {
                await moveRemoteAsset(op.path, op.destination!);
              }
              break;
            case SyncOperationType.createDir:
              await createRemoteDirectory(op.path);
              break;
          }
          _syncQueue.removeAt(0);
          await _saveQueue();
        } catch (e) {
          debugPrint('Error syncing ${op.path}: $e');
          await Future.delayed(const Duration(seconds: 5));
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> uploadFile(String path, Uint8List data);
  Future<void> deleteRemoteAsset(String path);
  Future<void> moveRemoteAsset(String path, String newPath);
  Future<void> createRemoteDirectory(String path);

  List<String> getCachedFilePaths() {
    final files = <String>[];

    for (final file
        in storage.cachedDocuments[config.currentCacheVariant] ?? []) {
      final alreadySyncedFile = files.firstWhereOrNull(
        (file) => file.startsWith(file),
      );
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
  Future<void> updateFile(
    String path,
    Uint8List data, {
    bool forceSync = false,
  }) async {
    path = normalizePath(path);
    await cacheContent(path, data);

    if (forceSync) {
      await uploadFile(path, data);
    } else {
      await _addToQueue(SyncOperation(SyncOperationType.update, path));
    }
  }

  @override
  Future<void> deleteAsset(String path) async {
    path = normalizePath(path);
    await deleteCachedContent(path);
    await _addToQueue(SyncOperation(SyncOperationType.delete, path));
  }

  @override
  Future<FileSystemEntity<Uint8List>?> moveAsset(
    String path,
    String newPath, {
    bool forceSync = false,
  }) async {
    path = normalizePath(path);
    newPath = normalizePath(newPath);

    final absolutePath = await getAbsolutePath(path);
    final absoluteNewPath = await getAbsolutePath(newPath);
    final dir = Directory(absolutePath);
    final file = File(absolutePath);
    if (await dir.exists()) {
      await dir.rename(absoluteNewPath);
    } else if (await file.exists()) {
      await file.rename(absoluteNewPath);
    }

    if (forceSync) {
      await moveRemoteAsset(path, newPath);
    } else {
      await _addToQueue(
        SyncOperation(SyncOperationType.move, path, destination: newPath),
      );
    }

    return getAsset(newPath);
  }

  @override
  Future<RawFileSystemDirectory> createDirectory(String path) async {
    path = normalizePath(path);
    final absolutePath = await getAbsolutePath(path);
    await Directory(absolutePath).create(recursive: true);

    await _addToQueue(SyncOperation(SyncOperationType.createDir, path));

    return RawFileSystemDirectory(
      AssetLocation(remote: storage.identifier, path: path),
    );
  }

  Future<void> cache(String path) async {
    final asset = await getAsset(path);
    if (asset is FileSystemDirectory) {
      var filePath = path;
      if (filePath.startsWith('/')) {
        filePath = filePath.substring(1);
      }
      filePath = universalPathContext.join(await getDirectory(), filePath);
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

enum SyncOperationType { update, delete, move, createDir }

class SyncOperation {
  final SyncOperationType type;
  final String path;
  final String? destination;

  SyncOperation(this.type, this.path, {this.destination});

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'path': path,
    if (destination != null) 'destination': destination,
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      SyncOperationType.values.firstWhere((e) => e.toString() == json['type']),
      json['path'],
      destination: json['destination'],
    );
  }
}
