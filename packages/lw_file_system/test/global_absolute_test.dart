import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:lw_file_system/src/api/io.dart';

void main() {
  late io.Directory temp;
  late TypedDirectoryFileSystem<int> system;
  setUp(() async {
    temp = await io.Directory.systemTemp.createTemp('lw_global_absolute_');
    final raw = IODirectoryFileSystem(
      storage: LocalStorage(name: 'notes', paths: {'': '${temp.path}/managed'}),
      config: FileSystemConfig(
        storeName: 'documents',
        database: 'test',
        databaseVersion: 1,
        getDirectory: (_) async => '${temp.path}/default',
      ),
    );
    system = TypedDirectoryFileSystem<int>.raw(
      raw,
      onEncode: (data) => Uint8List.fromList([data]),
      onDecode: (bytes) => bytes.single,
      config: raw.config,
    );
    await system.initialize();
  });
  tearDown(() async => temp.delete(recursive: true));

  test('global fetch distinguishes device and source-relative paths', () async {
    final devicePath = '${temp.path}/outside/note.bfly';
    final absolute = AssetLocation(
      remote: 'notes',
      path: devicePath,
      absolute: true,
    );
    final relative = AssetLocation(remote: 'notes', path: devicePath);
    await system.saveAbsolute(devicePath, Uint8List.fromList([42]));
    await system.updateFile(devicePath, 7);

    final snapshots =
        await GeneralDirectoryFileSystem.fetchAssetsGlobalSync<int>(
          [
            absolute,
            AssetLocation(remote: 'missing', path: devicePath, absolute: true),
            AssetLocation(
              remote: 'notes',
              path: '${temp.path}/missing',
              absolute: true,
            ),
            relative,
          ],
          {'notes': system},
        ).toList();

    expect(snapshots.map((files) => files.length), [1, 2]);
    final files = snapshots.last.cast<FileSystemFile<int>>();
    expect(files.map((file) => file.location), [absolute, relative]);
    expect(files.map((file) => file.data), [42, 7]);
  });

  test(
    'absolute getAsset supports typed data and metadata-only reads',
    () async {
      final path = '${temp.path}/outside/note.bfly';
      await system.saveAbsolute(path, Uint8List.fromList([42]));
      final loaded = await system.getAsset(path, absolute: true);
      expect((loaded as FileSystemFile<int>).data, 42);
      expect(loaded.location.absolute, isTrue);
      expect(loaded.size, 1);

      final metadata = await system.getAsset(
        path,
        absolute: true,
        readData: false,
      );
      expect((metadata as FileSystemFile<int>).data, isNull);
      expect(metadata.location, loaded.location);
      expect(metadata.size, 1);
      expect(await system.getAsset('$path.missing', absolute: true), isNull);
    },
  );
}
