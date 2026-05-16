import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lw_file_system/lw_file_system.dart';

void main() {
  group('RemoteFileSystem sync files', () {
    late Directory tempDir;
    late _FakeRemoteFileSystem fileSystem;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lw_file_system_sync_');
      final storage = DavRemoteStorage(
        name: 'dav',
        username: 'test',
        url: 'https://example.com/remote',
        lastSynced: DateTime(2026, 4, 28),
        pinnedPaths: const {
          '': ['projects'],
        },
      );
      final config = FileSystemConfig(
        passwordStorage: MockPasswordStorage(),
        storeName: 'test_store',
        getUnnamed: () => 'unnamed',
        getDirectory: (_) async => tempDir.path,
        database: 'test_db',
        databaseVersion: 1,
      );
      fileSystem = _FakeRemoteFileSystem(config: config, storage: storage)
        ..addFile('projects/archive/2026/notes.bfly', Uint8List(0));
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('includes synced files nested inside pinned subfolders', () async {
      final files = await fileSystem.getAllSyncFiles();

      expect(
        files.map((file) => file.path),
        containsAll([
          '/projects',
          '/projects/archive',
          '/projects/archive/2026',
          '/projects/archive/2026/notes.bfly',
        ]),
      );
    });
  });

  group('SyncFile status', () {
    test('treats newer local cache as localLatest even after global sync', () {
      final remoteModified = DateTime(2026, 3, 1);
      final localModified = DateTime(2026, 4, 1);
      final globalLastSynced = DateTime(2026, 4, 28);

      final syncFile = SyncFile(
        isDirectory: false,
        location: const AssetLocation(remote: 'dav', path: 'notes.bfly'),
        localLastModified: localModified,
        remoteLastModified: remoteModified,
        syncedLastModified: globalLastSynced,
      );

      expect(syncFile.status, FileSyncStatus.localLatest);
      expect(syncFile.needsSync, true);
    });

    test('treats equivalent local and remote timestamps as synced', () {
      final modified = DateTime(2026, 4, 28, 12);

      final syncFile = SyncFile(
        isDirectory: false,
        location: const AssetLocation(remote: 'dav', path: 'notes.bfly'),
        localLastModified: modified.add(const Duration(seconds: 1)),
        remoteLastModified: modified,
        syncedLastModified: DateTime(2026, 4, 27),
      );

      expect(syncFile.status, FileSyncStatus.synced);
    });

    test('detects conflict when both file copies changed after last sync', () {
      final syncFile = SyncFile(
        isDirectory: false,
        location: const AssetLocation(remote: 'dav', path: 'notes.bfly'),
        localLastModified: DateTime(2026, 4, 28, 13),
        remoteLastModified: DateTime(2026, 4, 28, 12),
        syncedLastModified: DateTime(2026, 4, 28, 11),
      );

      expect(syncFile.status, FileSyncStatus.conflict);
      expect(syncFile.hasConflict, true);
    });

    test('treats unchanged directories as synced after global sync', () {
      final syncFile = SyncFile(
        isDirectory: true,
        location: const AssetLocation(remote: 'dav', path: 'projects'),
        localLastModified: DateTime(2026, 4, 28),
        remoteLastModified: DateTime(2026, 4, 1),
        syncedLastModified: DateTime(2026, 4, 28),
      );

      expect(syncFile.status, FileSyncStatus.synced);
      expect(syncFile.needsSync, false);
    });
  });
}

class _FakeRemoteFileSystem extends RemoteFileSystem {
  final Map<String, Uint8List> _files = {};
  bool _initialized = false;

  @override
  final RemoteStorage storage;

  _FakeRemoteFileSystem({required super.config, required this.storage});

  @override
  FutureOr<bool> isInitialized() => _initialized;

  @override
  Future<void> runInitialize() async {
    _initialized = true;
  }

  @override
  Future<void> reset() async {
    _files.clear();
    _initialized = false;
  }

  @override
  Future<RawFileSystemEntity?> fetchRemoteAsset(
    String path, {
    bool readData = true,
    DateTime? currentLastModified,
    int? currentSize,
  }) async {
    path = normalizePath(path);
    if (_files.containsKey(path)) {
      return RawFileSystemFile(
        AssetLocation(remote: storage.identifier, path: path),
        data: readData ? _files[path] : null,
      );
    }

    final prefix = path.isEmpty ? '' : '$path/';
    final children = _files.keys
        .where((filePath) => filePath.startsWith(prefix) && filePath != path)
        .toList();
    if (children.isEmpty && path.isNotEmpty) return null;

    final assets = <RawFileSystemEntity>[];
    final seen = <String>{};
    for (final childPath in children) {
      final relative = childPath.substring(prefix.length);
      final name = relative.split('/').first;
      if (!seen.add(name)) continue;

      final fullChildPath = prefix + name;
      if (_files.containsKey(fullChildPath)) {
        assets.add(
          RawFileSystemFile(
            AssetLocation(remote: storage.identifier, path: fullChildPath),
            data: readData ? _files[fullChildPath] : null,
          ),
        );
      } else {
        assets.add(
          RawFileSystemDirectory(
            AssetLocation(remote: storage.identifier, path: fullChildPath),
          ),
        );
      }
    }

    return RawFileSystemDirectory(
      AssetLocation(remote: storage.identifier, path: path),
      assets: assets,
    );
  }

  @override
  Future<DateTime?> getRemoteFileModified(String path) async =>
      DateTime(2026, 4, 28);

  @override
  Future<void> uploadFile(String path, Uint8List data) async {
    addFile(path, data);
  }

  @override
  Future<void> deleteRemoteAsset(String path) async {
    path = normalizePath(path);
    _files.remove(path);
    _files.removeWhere((filePath, _) => filePath.startsWith('$path/'));
  }

  @override
  Future<void> moveRemoteAsset(String path, String newPath) async {}

  @override
  Future<void> createRemoteDirectory(String path) async {}

  void addFile(String path, Uint8List data) {
    _files[normalizePath(path)] = data;
  }
}
