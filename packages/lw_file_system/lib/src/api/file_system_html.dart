import 'dart:async';
import 'dart:js_interop';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
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
  external JSArray<FileSystemHandle> get files;
}

@JS()
extension type FileSystemHandle._(JSObject _) implements JSObject {
  external JSPromise<html.Blob> getFile();
}

mixin WebFileSystem on GeneralFileSystem {
  Database? _db;

  Future<Database> _getDatabase() async {
    var db = _db;
    if (db != null) return db;
    final idbFactory = getIdbFactory()!;
    db = await idbFactory.open(
      config.database,
      version: config.databaseVersion,
      onUpgradeNeeded: config.runOnUpgradeNeeded,
    );
    _db = db;
    if (hasDefault() && !isInitialized()) {
      await runDefault();
      html.window.localStorage
          .setItem(config.currentDefaultStorageName, 'true');
    }
    return db;
  }

  @override
  Future<void> reset() async {
    final db = await _getDatabase();
    final txn = db.transactionList([
      config.storeName,
      if (this is DirectoryFileSystem) config.currentDataStoreName
    ], 'readwrite');
    final store = txn.objectStore(config.storeName);
    await store.clear();
    if (this is DirectoryFileSystem) {
      final dataStore = txn.objectStore(config.currentDataStoreName);
      await dataStore.clear();
    }
    await txn.completed;
    html.window.localStorage.removeItem(config.currentDefaultStorageName);
    _db?.close();
    _db = null;
  }

  @override
  Future<void> runInitialize() async {
    await _getDatabase();
  }

  @override
  bool isInitialized() {
    if (!hasDefault()) return true;
    final value =
        html.window.localStorage.getItem(config.currentDefaultStorageName);
    return value == 'true';
  }
}

class WebDirectoryFileSystem extends DirectoryFileSystem with WebFileSystem {
  WebDirectoryFileSystem({required super.config, super.createDefault});

  @override
  Future<void> deleteAsset(String path) async {
    path = normalizePath(path);
    final db = await _getDatabase();
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
      {bool readData = true, bool forceRemote = false}) async {
    path = normalizePath(path);
    final db = await _getDatabase();
    final location = AssetLocation.local(path);
    final txn = db.transaction(
        [config.storeName, config.currentDataStoreName], 'readonly');

    Future<Uint8List?> getData(String path) async {
      final dataStore = txn.objectStore(config.currentDataStoreName);
      final data = await dataStore.getObject(path);
      if (data is! List) return null;
      return Uint8List.fromList(List<int>.from(data));
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
        final data = await store.getObject(e);
        if (data == null) return null;
        final map = Map<String, dynamic>.from(data as Map);
        if (map['type'] == 'file') {
          return RawFileSystemFile(AssetLocation.local(e),
              data: await getData(e));
        } else if (map['type'] == 'directory') {
          return RawFileSystemDirectory(AssetLocation.local(e));
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
    final db = await _getDatabase();
    final txn = db.transaction('documents', 'readonly');
    final store = txn.objectStore('documents');
    final doc = await store.getObject(path);
    await txn.completed;
    return doc != null;
  }

  @override
  Future<bool> updateFile(String path, List<int> data,
      {bool forceSync = false}) async {
    path = normalizePath(path);
    final pathWithoutSlash = path.substring(1);
    // Create directory if it doesn't exist
    if (pathWithoutSlash.contains('/')) {
      await createDirectory(
          '/${pathWithoutSlash.substring(0, pathWithoutSlash.lastIndexOf('/'))}');
    }
    final db = await _getDatabase();
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
    var db = await _getDatabase();
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
        final files = launchParams.files.toDart;
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
}

class WebKeyFileSystem extends KeyFileSystem with WebFileSystem {
  WebKeyFileSystem({required super.config, super.createDefault});

  @override
  Future<void> deleteFile(String key) async {
    key = normalizePath(key);
    final db = await _getDatabase();
    final txn = db.transaction(config.storeName, 'readwrite');
    final store = txn.objectStore(config.storeName);
    await store.delete(key);
    await txn.completed;
  }

  @override
  Future<Uint8List?> getFile(String key) async {
    key = normalizePath(key);
    final db = await _getDatabase();
    final txn = db.transaction(config.storeName, 'readonly');
    final store = txn.objectStore(config.storeName);
    final data = await store.getObject(key);
    await txn.completed;
    if (data == null) {
      return null;
    }
    return Uint8List.fromList(List<int>.from(data as List));
  }

  @override
  Future<void> updateFile(String key, Uint8List data) async {
    key = normalizePath(key);
    final db = await _getDatabase();
    final txn = db.transaction(config.storeName, 'readwrite');
    final store = txn.objectStore(config.storeName);
    await store.put(data, key);
    await txn.completed;
  }

  @override
  Future<bool> hasKey(String key) async {
    key = normalizePath(key);
    final db = await _getDatabase();
    final txn = db.transaction(config.storeName, 'readonly');
    final store = txn.objectStore(config.storeName);
    final doc = await store.getObject(key);
    await txn.completed;
    return doc != null;
  }

  @override
  Future<List<String>> getKeys() async {
    final db = await _getDatabase();
    final txn = db.transaction(config.storeName, 'readonly');
    final store = txn.objectStore(config.storeName);
    final cursor = store.openCursor(autoAdvance: true);
    final keys = cursor.map((e) => e.key.toString()).toList();
    await txn.completed;
    return keys;
  }
}
