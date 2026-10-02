import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:lw_file_system/src/api/io.dart';

void main() {
  late io.Directory temp;
  late IODirectoryFileSystem system;
  setUp(() async {
    temp = await io.Directory.systemTemp.createTemp('lw_storage_');
    system = IODirectoryFileSystem(
      config: FileSystemConfig(
        storeName: 'documents',
        database: 'test',
        databaseVersion: 1,
        getDirectory: (_) async => '${temp.path}/documents',
      ),
    );
    await system.initialize();
  });
  tearDown(() async => temp.delete(recursive: true));

  test('local directory overrides and base directory itself', () async {
    for (final entry in {
      'Documents': '${temp.path}/Documents',
      'myfolder': '${temp.path}/myfolder',
      '.': temp.path,
      '${temp.path}/other': '${temp.path}/other',
    }.entries) {
      final storage = LocalStorage(
        paths: {'': temp.path, 'documents': entry.key},
      );
      final local = IODirectoryFileSystem(
        storage: storage,
        config: FileSystemConfig(
          storeName: 'documents',
          variant: 'documents',
          database: 'test',
          databaseVersion: 1,
          getDirectory: (_) async => 'unused',
        ),
      );
      expect(
        io.Directory(await local.getDirectory()).absolute.path,
        io.Directory(entry.value).absolute.path,
      );
      await local.updateFile('/note.bfly', Uint8List.fromList([42]));
      expect(await io.File('${entry.value}/note.bfly').readAsBytes(), [42]);
    }
  });

  test('absolute saves write to the opened file', () async {
    final source = '${temp.path}/outside/note.bfly';
    await system.saveAbsolute(source, Uint8List.fromList([1, 2]));
    await system.saveAbsolute(source, Uint8List.fromList([3]));
    expect(await system.loadAbsolute(source), [3]);
    expect(await io.Directory('${temp.path}/documents').list().length, 0);
  });

  test(
    'relative traversal cannot read, write, or delete outside the root',
    () async {
      final source = io.File('${temp.path}/keep.bfly');
      await source.writeAsBytes([42]);
      for (final path in [
        '../keep.bfly',
        '/../../keep.bfly',
        r'..\keep.bfly',
      ]) {
        await expectLater(system.getAsset(path), throwsArgumentError);
        await expectLater(
          system.updateFile(path, Uint8List(0)),
          throwsArgumentError,
        );
        await expectLater(system.deleteAsset(path), throwsArgumentError);
      }
      expect(await source.readAsBytes(), [42]);
    },
  );

  test(
    'moves create destination parents and preserve existing files',
    () async {
      await system.updateFile('/note.bfly', Uint8List.fromList([42]));
      final moved = await system.moveAsset('/note.bfly', '/new/sub/note.bfly');
      expect(moved?.path, '/new/sub/note.bfly');
      await system.updateFile('/keep.bfly', Uint8List.fromList([7]));
      await expectLater(
        system.moveAsset('/new/sub/note.bfly', '/keep.bfly'),
        throwsA(isA<io.FileSystemException>()),
      );
      expect(await system.loadAbsolute('${temp.path}/documents/keep.bfly'), [
        7,
      ]);
      expect(await system.hasAsset('/new/sub/note.bfly'), isTrue);
    },
  );

  test('data directory moves may target an existing empty directory', () async {
    await system.updateFile('/note.bfly', Uint8List.fromList([42]));
    final target = io.Directory('${temp.path}/selected')..createSync();
    expect(
      await system.moveAbsolute('${temp.path}/documents', target.path),
      isTrue,
    );
    expect(await io.File('${target.path}/note.bfly').readAsBytes(), [42]);
  });

  test('moving a directory into itself leaves the source intact', () async {
    await system.createDirectory('/folder');
    await system.updateFile('/folder/keep.bfly', Uint8List.fromList([42]));
    await expectLater(
      system.moveAsset('/folder', '/folder/child'),
      throwsA(isA<io.FileSystemException>()),
    );
    expect(await system.hasAsset('/folder/keep.bfly'), isTrue);
  });
}
