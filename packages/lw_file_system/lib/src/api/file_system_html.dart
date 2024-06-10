// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:web/web.dart' as html;

@JS('window.launchQueue')
external LaunchQueue? get launchQueue;

@JS()
extension type LaunchQueue._(JSObject _) implements JSObject {
  external void setConsumer(JSFunction f);
}

@JS()
extension type LaunchParams._(JSObject _) implements JSObject {
  @JS('files')
  external List get files;
}

@JS()
class FileSystemHandle {
  external JSPromise<html.Blob> getFile();
}

Database? _db;
Future<Database> _getDatabase(FileSystemConfig config) async {
  if (_db != null) return _db!;
  var idbFactory = getIdbFactory()!;
  _db = await idbFactory.open(config.database,
      version: 4, onUpgradeNeeded: config.currentOnDatabaseUpgrade);
  return _db!;
}

class WebDirectoryFileSystem extends DirectoryFileSystem {
  WebDirectoryFileSystem({required super.config});

  @override
  Future<void> deleteAsset(String path) async {
    path = normalizePath(path);
    final db = await _getDatabase(config);
    final txn = db.transactionList(
        [config.storeName, config.currentDataStoreName], 'readwrite');
    final store = txn.objectStore(config.storeName);
    final data = await store.getObject(path) as Map<dynamic, dynamic>?;
    await store.delete(path);
    final dataStore = txn.objectStore(config.currentDataStoreName);
    await dataStore.delete(path);
    if (data?['type'] == 'directory') {
      // delete all where key starts with path
      final cursor = store.openCursor();
      await cursor.forEach((cursor) {
        if (cursor.key.toString().startsWith(path)) {
          deleteAsset(cursor.key.toString());
        }
      });
    }
    await txn.completed;
  }

  @override
  Future<RawFileSystemEntity?> readAsset(String path,
      {bool readData = true}) async {
    path = normalizePath(path);
    final db = await _getDatabase(config);
    final location = AssetLocation.local(path);
    final txn = db.transaction(
        [config.storeName, config.currentDataStoreName], 'readonly');

    Future<Uint8List?> getData(String path) async {
      final dataStore = txn.objectStore(config.currentDataStoreName);
      final data = await dataStore.getObject(path);
      return Uint8List.fromList(List<int>.from(data as List));
    }

    final store = txn.objectStore(config.storeName);
    var data = await store.getObject(path);
    if (path == '') {
      data = {'type': 'directory'};
    }
    if (data == null) {
      await txn.completed;
      return null;
    }
    final map = Map<String, dynamic>.from(data as Map);
    if (map['type'] == 'file') {
      final data = await getData(path);
      if (data == null) {
        return null;
      }
      final file = FileSystemFile(location, data: data);
      await txn.completed;
      return file;
    } else if (map['type'] == 'directory') {
      var cursor = store.openKeyCursor(autoAdvance: true);
      final names = await cursor.map((e) => e.key.toString()).where((e) {
        return e.startsWith(path) &&
            e != path &&
            !e.substring(path.length + 1).contains('/');
      }).toList();
      final assets = (await Future.wait(names.map((e) async {
        final store = txn.objectStore(config.storeName);
        final data = await store.getObject(path);
        if (data == null) return null;
        final map = Map<String, dynamic>.from(data as Map);
        if (map['type'] == 'file') {
          return RawFileSystemFile(AssetLocation.local(path),
              data: await getData(path));
        } else if (map['type'] == 'directory') {
          return RawFileSystemDirectory(AssetLocation.local(path));
        }
        return null;
      })))
          .whereNotNull()
          .toList();
      return RawFileSystemDirectory(
        location,
        assets: assets,
      );
    }
    return null;
  }

  @override
  Future<bool> hasAsset(String path) async {
    path = normalizePath(path);
    final db = await _getDatabase(config);
    final txn = db.transaction('documents', 'readonly');
    final store = txn.objectStore('documents');
    final doc = await store.getObject(path);
    await txn.completed;
    return doc != null;
  }

  @override
  Future<bool> updateFile(String path, List<int> data) async {
    path = normalizePath(path);
    final pathWithoutSlash = path.substring(1);
    // Create directory if it doesn't exist
    if (pathWithoutSlash.contains('/')) {
      await createDirectory(
          '/${pathWithoutSlash.substring(0, pathWithoutSlash.lastIndexOf('/'))}');
    }
    final db = await _getDatabase(config);
    final txn = db.transactionList(
        [config.storeName, config.currentDataStoreName], 'readwrite');
    final store = txn.objectStore(config.storeName);
    await store.put({'type': 'file'}, path);
    final dataStore = txn.objectStore(config.currentDataStoreName);
    await dataStore.put(data, path);
    await txn.completed;
    return true;
  }

  @override
  Future<RawFileSystemDirectory> createDirectory(String path) async {
    path = normalizePath(path);
    var db = await _getDatabase(config);
    var txn = db.transaction(config.storeName, 'readwrite');
    var store = txn.objectStore(config.storeName);
    final parents = path.split('/');
    String last = '/';
    if (parents.length <= 1) return await getRootDirectory();
    for (var current in parents.sublist(1)) {
      final data = {'type': 'directory'};
      final currentPath = '$last$current';
      await store.put(data, currentPath);
      last = '$currentPath/';
    }
    await txn.completed;
    return RawFileSystemDirectory(AssetLocation.local(path), assets: const []);
  }

  FileSystemHandle? _fs;

  @override
  Future<Uint8List?> loadAbsolute(String path) async {
    try {
      final completer = Completer<Uint8List?>();
      void complete(LaunchParams launchParams) async {
        final files = launchParams.files.cast<FileSystemHandle>();
        if (files.isEmpty) {
          completer.complete(null);
          return;
        }
        _fs = files.first;
        final file = await _fs!.getFile().toDart;
        final reader = html.FileReader();
        reader.onload.add((() {
          try {
            final result = reader.result as Uint8List;
            completer.complete(Uint8List.fromList(result));
          } catch (e) {
            completer.completeError(e);
          }
        }).toJS);
        reader.onerror.add((() {
          final error = reader.error;
          if (error != null) {
            completer.completeError(error);
          } else {
            completer.complete(null);
          }
        }).toJS);
        reader.readAsArrayBuffer(file);
      }

      launchQueue?.setConsumer(complete.toJS);
      return completer.future;
    } on NoSuchMethodError catch (e) {
      if (kDebugMode) {
        print('File handling feature not supported: $e');
      }

      return null;
    }
  }

  @override
  Future<void> saveAbsolute(String path, Uint8List bytes) async {
    final a = html.document.createElement('a') as html.HTMLAnchorElement;
    // Create data URL
    final blob =
        html.Blob([bytes.toJS].toJS, html.BlobPropertyBag(type: 'text/plain'));
    final url = html.URL.createObjectURL(blob);
    a.href = url;
    a.download = path;
    a.click();
    html.URL.revokeObjectURL(url);
  }

  @override
  Future<bool> isInitialized() => Future.value(true);

  @override
  Future<void> runInitialize() => Future.value(createDefault(this));
}

class WebKeyFileSystem extends KeyFileSystem {
  WebKeyFileSystem({required super.config});

  @override
  Future<void> deleteFile(String key) async {
    var db = await _getDatabase(config);
    var txn = db.transaction(config.storeName, 'readwrite');
    var store = txn.objectStore(config.storeName);
    await store.delete(key);
    await txn.completed;
  }

  @override
  Future<Uint8List?> getFile(String key) async {
    var db = await _getDatabase(config);
    var txn = db.transaction(config.storeName, 'readonly');
    var store = txn.objectStore(config.storeName);
    var data = await store.getObject(config.storeName);
    await txn.completed;
    if (data == null) {
      return null;
    }
    return Uint8List.fromList(List<int>.from(data as List));
  }

  @override
  Future<void> updateFile(String key, Uint8List data) async {
    var db = await _getDatabase(config);
    var txn = db.transaction(config.storeName, 'readwrite');
    var store = txn.objectStore(config.storeName);
    await store.put(data, key);
  }

  @override
  Future<bool> hasKey(String key) async {
    var db = await _getDatabase(config);
    var txn = db.transaction(config.storeName, 'readonly');
    var store = txn.objectStore(config.storeName);
    var doc = await store.getObject(key);
    await txn.completed;
    return doc != null;
  }

  @override
  Future<List<String>> getKeys() async {
    var db = await _getDatabase(config);
    var txn = db.transaction(config.storeName, 'readonly');
    var store = txn.objectStore(config.storeName);
    var cursor = store.openCursor(autoAdvance: true);
    final keys = cursor.map((e) => e.key.toString()).toList();
    await txn.completed;
    return keys;
  }

  @override
  Future<bool> isInitialized() => Future.value(true);

  @override
  Future<void> runInitialize() => Future.value(createDefault(this));
}
