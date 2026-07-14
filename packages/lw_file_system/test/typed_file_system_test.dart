import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lw_file_system/lw_file_system.dart';

void main() {
  test(
    'TypedDirectoryFileSystem forwards forceSync to wrapped file system',
    () async {
      final raw = _RecordingDirectoryFileSystem();
      final typed = TypedDirectoryFileSystem<int>.raw(
        raw,
        onEncode: (data) => Uint8List.fromList([data]),
        onDecode: (data) => data.first,
        config: const MockFileSystemConfig(),
      );

      await typed.updateFile('/note.bfly', 42, forceSync: true);

      expect(raw.lastForceSync, true);
      expect(raw.lastPath, '/note.bfly');
      expect(raw.lastData, [42]);
    },
  );

  test('TypedDirectoryFileSystem preserves raw file metadata', () async {
    final lastModified = DateTime.utc(2026, 5, 19, 10, 30);
    final creationTime = DateTime.utc(2026, 5, 18, 9, 15);
    final raw = _RecordingDirectoryFileSystem(
      asset: RawFileSystemFile(
        AssetLocation.local('/note.bfly'),
        data: Uint8List.fromList([42]),
        lastModified: lastModified,
        creationTime: creationTime,
        size: 1234,
      ),
    );
    final typed = TypedDirectoryFileSystem<int>.raw(
      raw,
      onEncode: (data) => Uint8List.fromList([data]),
      onDecode: (data) => data.first,
      config: const MockFileSystemConfig(),
    );

    final asset = await typed.readAsset('/note.bfly');

    final file = asset as FileSystemFile<int>;
    expect(file.data, 42);
    expect(file.lastModified, lastModified);
    expect(file.creationTime, creationTime);
    expect(file.size, 1234);
  });

  test('created files retain the configured storage identifier', () async {
    const storage = DavRemoteStorage(
      name: 'remote-test',
      username: 'user',
      url: 'https://example.com',
    );
    final fileSystem = _RecordingDirectoryFileSystem(storage: storage);

    final created = await fileSystem.createFile(
      '/note.bfly',
      Uint8List.fromList([42]),
    );

    expect(created.path, '/note.bfly');
    expect(created.remote, storage.identifier);
  });
}

class _RecordingDirectoryFileSystem extends DirectoryFileSystem {
  String? lastPath;
  Uint8List? lastData;
  bool? lastForceSync;
  FileSystemEntity<Uint8List>? asset;

  @override
  final ExternalStorage? storage;

  _RecordingDirectoryFileSystem({this.asset, this.storage})
    : super(config: const MockFileSystemConfig());

  @override
  Future<FileSystemDirectory<Uint8List>> createDirectory(String path) async =>
      FileSystemDirectory(AssetLocation.local(path));

  @override
  Future<void> deleteAsset(String path) async {}

  @override
  Future<bool> hasAsset(String path) async => false;

  @override
  FutureOr<bool> isInitialized() => true;

  @override
  Future<FileSystemEntity<Uint8List>?> moveAsset(
    String path,
    String newPath, {
    bool forceSync = false,
  }) async {
    return null;
  }

  @override
  Future<FileSystemEntity<Uint8List>?> readAsset(
    String path, {
    bool readData = true,
    bool forceRemote = false,
  }) async {
    return asset;
  }

  @override
  Future<void> runInitialize() async {}

  @override
  Future<void> updateFile(
    String path,
    Uint8List data, {
    bool forceSync = false,
  }) async {
    lastPath = path;
    lastData = data;
    lastForceSync = forceSync;
  }
}
