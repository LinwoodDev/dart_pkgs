import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:lw_file_system/src/api/io.dart';

void main() {
  test('Android wrapper detects LocalStorage content URI', () async {
    final fileSystem = AndroidSafDirectoryFileSystem(
      config: _config,
      storage: const LocalStorage(paths: {'': 'content://tree/root'}),
    );

    expect(
      AndroidSafDirectoryFileSystem.isSafStorage(
        await fileSystem.getDirectory(),
      ),
      true,
    );
    expect(fileSystem.isSaf, isTrue);
    expect(await fileSystem.getDirectory(), 'content://tree/root');
  });

  test(
    'Android wrapper delegates non-SAF LocalStorage to IO behavior',
    () async {
      final fileSystem = AndroidSafDirectoryFileSystem(
        config: _config,
        storage: const LocalStorage(paths: {'': '/tmp/lw_file_system'}),
      );

      expect(fileSystem.isSaf, isFalse);
      expect(await fileSystem.getDirectory(), '/tmp/lw_file_system');
    },
  );

  test('Android wrapper delegates null storage to IO behavior', () async {
    final fileSystem = AndroidSafDirectoryFileSystem(config: _config);

    expect(fileSystem.isSaf, isFalse);
    expect(await fileSystem.getDirectory(), '/tmp/lw_file_system');
  });

  test(
    'uses Android SAF with a variant subdirectory inside a SAF root',
    () async {
      final fileSystem = AndroidSafDirectoryFileSystem(
        config: _androidConfig,
        storage: const LocalStorage(
          paths: {'': 'content://tree/root', 'android': 'Documents'},
        ),
      );

      expect(fileSystem.isSaf, isTrue);
      expect(await fileSystem.getDirectory(), 'content://tree/root/Documents');
    },
  );

  test('uses Android SAF base path for an empty selected variant', () async {
    final fileSystem = AndroidSafDirectoryFileSystem(
      config: _androidConfig,
      storage: const LocalStorage(
        paths: {'': 'content://tree/root', 'android': ''},
      ),
    );

    expect(fileSystem.isSaf, isTrue);
    expect(await fileSystem.getDirectory(), 'content://tree/root');
  });

  test('Android SAF resolves absolute and relative paths like IO', () async {
    final fileSystem = AndroidSafDirectoryFileSystem(
      config: _androidConfig,
      storage: const LocalStorage(
        paths: {'': 'content://tree/root', 'android': 'Documents'},
      ),
    );

    expect(
      await fileSystem.getAbsolutePath('/folder/file.txt'),
      'content://tree/root/Documents/folder/file.txt',
    );
    expect(
      await fileSystem.toRelativePath(
        'content://tree/root/Documents/folder/file.txt',
      ),
      'folder/file.txt',
    );
    expect(
      await fileSystem.toRelativePath('content://tree/root/Other/file.txt'),
      isNull,
    );
  });

  test('uses Android SAF with a variant SAF root', () async {
    final fileSystem = AndroidSafDirectoryFileSystem(
      config: _androidConfig,
      storage: const LocalStorage(
        paths: {'': '/tmp/lw_file_system', 'android': 'content://tree/root'},
      ),
    );

    expect(fileSystem.isSaf, isTrue);
    expect(await fileSystem.getDirectory(), 'content://tree/root');
  });

  test('missing selected variant delegates to IO behavior', () async {
    final fileSystem = AndroidSafDirectoryFileSystem(
      config: _androidConfig,
      storage: const LocalStorage(paths: {'': 'content://tree/root'}),
    );

    expect(fileSystem.isSaf, isFalse);
    expect(await fileSystem.getDirectory(), '/tmp/lw_file_system');
    expect(await fileSystem.readAsset('missing'), isNull);
  });

  test('fromPlatform falls back to IO when Android SAF is disabled', () {
    final fileSystem = DirectoryFileSystem.fromPlatform(
      _config,
      storage: const LocalStorage(paths: {'': 'content://tree/root'}),
      useAndroidSaf: false,
    );

    expect(fileSystem, isA<IODirectoryFileSystem>());
  });

  test('fromPlatform uses Android wrapper on Android', () {
    final fileSystem = DirectoryFileSystem.fromPlatform(_config);

    if (Platform.isAndroid) {
      expect(fileSystem, isA<AndroidSafDirectoryFileSystem>());
    } else {
      expect(fileSystem, isA<IODirectoryFileSystem>());
    }
  });
}

final _config = FileSystemConfig(
  storeName: 'test',
  database: 'test',
  databaseVersion: 1,
  getDirectory: (_) async => '/tmp/lw_file_system',
);

final _androidConfig = FileSystemConfig(
  storeName: 'test',
  database: 'test',
  databaseVersion: 1,
  pathVariant: 'android',
  getDirectory: (_) async => '/tmp/lw_file_system',
);
