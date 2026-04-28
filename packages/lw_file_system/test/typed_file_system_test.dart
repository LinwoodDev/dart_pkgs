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
}

class _RecordingDirectoryFileSystem extends DirectoryFileSystem {
  String? lastPath;
  Uint8List? lastData;
  bool? lastForceSync;

  _RecordingDirectoryFileSystem() : super(config: const MockFileSystemConfig());

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
    return null;
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
