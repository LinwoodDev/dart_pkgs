import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:lw_file_system/src/api/io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    expect(await fileSystem.isSaf(), isTrue);
    expect(await fileSystem.getDirectory(), 'content://tree/root');
  });

  test(
    'Android wrapper delegates non-SAF LocalStorage to IO behavior',
    () async {
      final fileSystem = AndroidSafDirectoryFileSystem(
        config: _config,
        storage: const LocalStorage(paths: {'': '/tmp/lw_file_system'}),
      );

      expect(await fileSystem.isSaf(), isFalse);
      expect(await fileSystem.getDirectory(), '/tmp/lw_file_system');
    },
  );

  test('Android wrapper delegates null storage to IO behavior', () async {
    final fileSystem = AndroidSafDirectoryFileSystem(config: _config);

    expect(await fileSystem.isSaf(), isFalse);
    expect(await fileSystem.getDirectory(), '/tmp/lw_file_system');
  });

  test(
    'Android SAF imports a non-SAF path when configured directory is IO',
    () async {
      const channel = MethodChannel('linwood.dev/lw_file_system/saf');
      final calls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final fileSystem = AndroidSafDirectoryFileSystem(
        config: _config,
        storage: const LocalStorage(paths: {'': '/tmp/lw_file_system'}),
      );

      final result = await fileSystem.moveAbsolute(
        '/tmp/source/file.txt',
        'content://tree/root/Documents/file.txt',
      );

      expect(result, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'importPathToSaf');
      expect(calls.single.arguments, {
        'sourcePath': '/tmp/source/file.txt',
        'rootUri': 'content://tree/root/Documents/file.txt',
      });
    },
  );

  test(
    'uses Android SAF with a variant subdirectory inside a SAF root',
    () async {
      final fileSystem = AndroidSafDirectoryFileSystem(
        config: _androidConfig,
        storage: const LocalStorage(
          paths: {'': 'content://tree/root', 'android': 'Documents'},
        ),
      );

      expect(await fileSystem.isSaf(), isTrue);
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

    expect(await fileSystem.isSaf(), isTrue);
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

    expect(await fileSystem.isSaf(), isTrue);
    expect(await fileSystem.getDirectory(), 'content://tree/root');
  });

  test('missing selected variant delegates to IO behavior', () async {
    final fileSystem = AndroidSafDirectoryFileSystem(
      config: _androidConfig,
      storage: const LocalStorage(paths: {'': 'content://tree/root'}),
    );

    expect(await fileSystem.isSaf(), isFalse);
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
