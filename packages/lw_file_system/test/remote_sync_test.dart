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
        getDirectory: (_) async => '${tempDir.path}/cache',
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

    test(
      'reports nested progress without additional filesystem requests',
      () async {
        final updates = <SyncProgress>[];
        final subscription = fileSystem.progressStream.listen(updates.add);
        addTearDown(subscription.cancel);
        final atFile = Completer<void>();
        final resume = Completer<void>();
        addTearDown(() {
          if (!resume.isCompleted) resume.complete();
        });
        fileSystem.beforeSyncFile = (path) async {
          if (path != '/projects/archive/2026/notes.bfly') return;
          if (!atFile.isCompleted) atFile.complete();
          await resume.future;
        };

        final syncing = fileSystem.fullSync(
          paths: [
            'projects',
            '/projects/archive',
            'projects/archive/2026/notes.bfly',
          ],
        );
        await atFile.future;
        expect(fileSystem.currentProgress.isRunning, true);
        expect(
          fileSystem.currentProgress.currentFile,
          '/projects/archive/2026/notes.bfly',
        );
        expect(fileSystem.currentProgress.totalFiles, 4);
        resume.complete();
        final result = await syncing;
        await Future<void>.delayed(Duration.zero);
        final fetches = fileSystem.fetchCount;
        final metadataReads = fileSystem.metadataReadCount;

        expect(result.results, hasLength(4));
        expect(fileSystem.currentProgress.processedFiles, 4);
        expect(fileSystem.currentProgress.currentFile, isNull);
        expect(fileSystem.currentProgress.isRunning, false);
        expect(
          updates.any(
            (p) =>
                p.isRunning &&
                p.processedFiles > 0 &&
                p.processedFiles < p.totalFiles,
          ),
          true,
        );

        // Compare with the existing recursive traversal from the same empty cache.
        await fileSystem.clearCachedContent();
        fileSystem.beforeSyncFile = null;
        fileSystem.fetchCount = 0;
        fileSystem.metadataReadCount = 0;
        await fileSystem.syncPath('/projects');
        expect(fetches, fileSystem.fetchCount);
        expect(metadataReads, fileSystem.metadataReadCount);
      },
    );

    test('reports a failed nested transfer and continues syncing', () async {
      const failedPath = '/projects/archive/2026/notes.bfly';
      await fileSystem.cacheContent(failedPath, Uint8List.fromList([1]));
      fileSystem.addFile('projects/next.bfly', Uint8List.fromList([2]));
      fileSystem.uploadErrorPaths.add(failedPath);

      final result = await fileSystem.fullSync();

      expect(result.failureCount, 1);
      expect(
        result.results.any((r) => r.path == '/projects/next.bfly' && r.success),
        true,
      );
      expect(fileSystem.currentProgress.errors, 1);
      expect(fileSystem.currentProgress.processedFiles, 5);
      expect(fileSystem.currentProgress.totalFiles, 5);
      expect(fileSystem.currentProgress.isRunning, false);
    });

    test('uses cached directories immediately after going offline', () async {
      await fileSystem.cacheContent(
        'projects/cached.bfly',
        Uint8List.fromList([1, 2, 3]),
      );
      fileSystem.fetchError = const NetworkException(
        'Offline',
        type: NetworkErrorType.connection,
      );

      final first = await fileSystem.readAsset('projects');
      final second = await fileSystem.readAsset('projects');

      expect(first, isA<RawFileSystemDirectory>());
      expect(second, isA<RawFileSystemDirectory>());
      expect(fileSystem.isOnline, false);
      expect(fileSystem.fetchCount, 1);
    });

    test('forced reads probe the remote after going offline', () async {
      await fileSystem.cacheContent(
        'projects/cached.bfly',
        Uint8List.fromList([1, 2, 3]),
      );
      fileSystem.fetchError = const NetworkException(
        'Offline',
        type: NetworkErrorType.connection,
      );
      await fileSystem.readAsset('projects');
      fileSystem.fetchError = null;

      final refreshed = await fileSystem.readAsset(
        'projects',
        forceRemote: true,
      );

      expect(refreshed, isA<RawFileSystemDirectory>());
      expect(fileSystem.isOnline, true);
      expect(fileSystem.fetchCount, 2);
    });

    test('repairs a file occupying the cache root before creating', () async {
      final cacheRoot = await fileSystem.getDirectory();
      await File(cacheRoot).create(recursive: true);
      await File(cacheRoot).writeAsString('invalid directory response');

      await fileSystem.createDirectory('projects');
      await fileSystem.cacheContent(
        'projects/cached.bfly',
        Uint8List.fromList([1, 2, 3]),
      );

      expect(await Directory(cacheRoot).exists(), true);
      expect(await File('$cacheRoot/projects/cached.bfly').readAsBytes(), [
        1,
        2,
        3,
      ]);
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
  NetworkException? fetchError;
  int fetchCount = 0;
  int metadataReadCount = 0;
  final uploadErrorPaths = <String>{};
  Future<void> Function(String path)? beforeSyncFile;

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
    fetchCount++;
    if (fetchError case final error?) throw error;
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
  Future<DateTime?> getRemoteFileModified(String path) async {
    metadataReadCount++;
    return DateTime(2026, 4, 28);
  }

  @override
  Future<SyncFile> getSyncFile(String path) async {
    await beforeSyncFile?.call(normalizePath(path));
    return super.getSyncFile(path);
  }

  @override
  Future<void> uploadFile(String path, Uint8List data) async {
    if (uploadErrorPaths.contains(normalizePath(path))) {
      throw StateError('Upload failed');
    }
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
