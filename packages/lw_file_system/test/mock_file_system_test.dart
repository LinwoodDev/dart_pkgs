import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lw_file_system/lw_file_system.dart';

void main() {
  group('MockFileSystem', () {
    late MockFileSystem fileSystem;
    late FileSystemConfig config;

    setUp(() {
      config = FileSystemConfig(
        passwordStorage: MockPasswordStorage(),
        storeName: 'test_store',
        getUnnamed: () => 'unnamed',
        variant: 'test',
        getDirectory: (storage) async => '/test',
        database: 'test_db',
        databaseVersion: 1,
      );
      fileSystem = MockFileSystem(config: config);
    });

    test('initializes correctly', () async {
      expect(fileSystem.isInitialized(), false);
      await fileSystem.initialize();
      expect(fileSystem.isInitialized(), true);
    });

    test('saves and loads file', () async {
      await fileSystem.initialize();
      final path = 'test.txt';
      final content = Uint8List.fromList([1, 2, 3]);

      await fileSystem.saveAbsolute(path, content);
      final loaded = await fileSystem.loadAbsolute(path);

      expect(loaded, content);
    });

    test('moves file', () async {
      await fileSystem.initialize();
      final oldPath = 'old.txt';
      final newPath = 'new.txt';
      final content = Uint8List.fromList([1, 2, 3]);

      await fileSystem.saveAbsolute(oldPath, content);
      final result = await fileSystem.moveAbsolute(oldPath, newPath);

      expect(result, true);
      expect(await fileSystem.loadAbsolute(oldPath), null);
      expect(await fileSystem.loadAbsolute(newPath), content);
    });

    test('reads asset', () async {
      await fileSystem.initialize();
      final path = 'dir/file.txt';
      final content = Uint8List.fromList([1, 2, 3]);
      fileSystem.addFile(path, content);

      final asset = await fileSystem.readAsset(path);
      expect(asset, isA<FileSystemFile<Uint8List>>());
      expect((asset as FileSystemFile<Uint8List>).data, content);
    });

    test('reads directory', () async {
      await fileSystem.initialize();
      fileSystem.addFile('dir/file1.txt', Uint8List(0));
      fileSystem.addFile('dir/file2.txt', Uint8List(0));

      final asset = await fileSystem.readAsset('dir');
      expect(asset, isA<FileSystemDirectory<Uint8List>>());
      final dir = asset as FileSystemDirectory<Uint8List>;
      expect(dir.assets.length, 2);
    });
  });

  group('MockKeyFileSystem', () {
    late MockKeyFileSystem fileSystem;
    late FileSystemConfig config;

    setUp(() {
      config = FileSystemConfig(
        passwordStorage: MockPasswordStorage(),
        storeName: 'test_store',
        getUnnamed: () => 'unnamed',
        variant: 'test',
        getDirectory: (storage) async => '/test',
        database: 'test_db',
        databaseVersion: 1,
      );
      fileSystem = MockKeyFileSystem(config: config);
    });

    test('initializes correctly', () async {
      expect(fileSystem.isInitialized(), false);
      await fileSystem.initialize();
      expect(fileSystem.isInitialized(), true);
    });

    test('saves and loads file by key', () async {
      await fileSystem.initialize();
      final key = 'test_key';
      final content = Uint8List.fromList([1, 2, 3]);

      await fileSystem.updateFile(key, content);
      final loaded = await fileSystem.getFile(key);

      expect(loaded, content);
      expect(await fileSystem.hasKey(key), true);
    });

    test('deletes file', () async {
      await fileSystem.initialize();
      final key = 'test_key';
      final content = Uint8List.fromList([1, 2, 3]);

      await fileSystem.updateFile(key, content);
      await fileSystem.deleteFile(key);

      expect(await fileSystem.hasKey(key), false);
      expect(await fileSystem.getFile(key), null);
    });

    test('lists keys', () async {
      await fileSystem.initialize();
      await fileSystem.updateFile('key1', Uint8List(0));
      await fileSystem.updateFile('key2', Uint8List(0));

      final keys = await fileSystem.getKeys();
      expect(keys.length, 2);
      expect(keys, containsAll(['/key1', '/key2']));
    });
  });
}
