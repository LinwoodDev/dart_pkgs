import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lw_file_system/lw_file_system.dart';

void main() {
  late Directory tempDir;
  late HttpServer server;
  late List<String> methods;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lw_file_system_dav_');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    methods = [];
  });

  tearDown(() async {
    await server.close(force: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  DavRemoteDirectoryFileSystem createFileSystem({
    String? password,
    Map<String, String> paths = const {},
    String variant = '',
  }) {
    final storage = DavRemoteStorage(
      name: 'dav',
      username: 'test',
      url: 'http://${server.address.host}:${server.port}',
      paths: paths,
    );
    final passwordStorage = InMemoryPasswordStorage();
    if (password != null) passwordStorage.write(storage, password);
    return DavRemoteDirectoryFileSystem(
      storage: storage,
      config: FileSystemConfig(
        passwordStorage: passwordStorage,
        storeName: 'test_store',
        variant: variant,
        getDirectory: (_) async => tempDir.path,
        database: 'test_db',
        databaseVersion: 1,
      ),
    );
  }

  test('creates a missing configured root and its parents', () async {
    final paths = <String>[];
    var parentExists = false;
    var directoryExists = false;
    final handling = server.forEach((request) async {
      methods.add(request.method);
      paths.add(request.uri.path);
      switch (request.method) {
        case 'PROPFIND':
          if (!directoryExists) {
            request.response.statusCode = HttpStatus.notFound;
          } else {
            request.response
              ..statusCode = HttpStatus.multiStatus
              ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>${request.uri.path}</d:href>
    <d:propstat>
      <d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''');
          }
        case 'MKCOL':
          switch (request.uri.path) {
            case '/Butterfly/Documents':
              if (parentExists) {
                directoryExists = true;
                request.response.statusCode = HttpStatus.created;
              } else {
                request.response.statusCode = HttpStatus.conflict;
              }
            case '/Butterfly':
              parentExists = true;
              request.response.statusCode = HttpStatus.created;
            default:
              request.response.statusCode = HttpStatus.notFound;
          }
      }
      await request.response.close();
    });

    final asset = await createFileSystem(
      paths: const {'': 'Butterfly', 'documents': 'Documents'},
      variant: 'documents',
    ).fetchRemoteAsset('', readData: false);

    expect(asset, isA<RawFileSystemDirectory>());
    expect(methods, ['PROPFIND', 'MKCOL', 'MKCOL', 'MKCOL', 'PROPFIND']);
    expect(paths.map((path) => path.replaceFirst(RegExp(r'/$'), '')), [
      '/Butterfly/Documents',
      '/Butterfly/Documents',
      '/Butterfly',
      '/Butterfly/Documents',
      '/Butterfly/Documents',
    ]);
    await server.close();
    await handling;
  });

  test(
    'uses PROPFIND to distinguish uncached directories from files',
    () async {
      final handling = server.forEach((request) async {
        methods.add(request.method);
        request.response
          ..statusCode = HttpStatus.multiStatus
          ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/folder/</d:href>
    <d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop></d:propstat>
  </d:response>
  <d:response>
    <d:href>/folder/note.bfly</d:href>
    <d:propstat><d:prop><d:resourcetype/><d:getcontentlength>3</d:getcontentlength></d:prop></d:propstat>
  </d:response>
</d:multistatus>''');
        await request.response.close();
      });

      final asset = await createFileSystem().fetchRemoteAsset('folder');

      expect(asset, isA<RawFileSystemDirectory>());
      expect((asset as RawFileSystemDirectory).assets, hasLength(1));
      expect(asset.assets.single, isA<RawFileSystemFile>());
      expect(asset.assets.single.path, '/folder/note.bfly');
      expect(methods, ['PROPFIND']);
      await server.close();
      await handling;
    },
  );

  test('returns null for malformed SabreDAV not-found multistatus', () async {
    final handling = server.forEach((request) async {
      methods.add(request.method);
      request.response
        ..statusCode = HttpStatus.multiStatus
        ..write(r'''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:"<?xml version="1.0" encoding="utf-8"?>
<d:error xmlns:d="DAV:" xmlns:s="http://sabredav.org/ns">
  <s:exception>Sabre\DAV\Exception\NotFound</s:exception>
</d:error>''');
      await request.response.close();
    });

    final asset = await createFileSystem().fetchRemoteAsset(
      'missing.bfly',
      readData: false,
    );

    expect(asset, isNull);
    expect(methods, ['PROPFIND']);
    await server.close();
    await handling;
  });

  test('hasAsset rejects malformed SabreDAV not-found multistatus', () async {
    final handling = server.forEach((request) async {
      request.response
        ..statusCode = HttpStatus.multiStatus
        ..write(r'''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:"
<?xml version="1.0" encoding="utf-8"?>
<d:error xmlns:d="DAV:" xmlns:s="http://sabredav.org/ns">
  <s:exception>Sabre\DAV\Exception\NotFound</s:exception>
  <s:message>File could not be located</s:message>
</d:error>''');
      await request.response.close();
    });

    expect(await createFileSystem().hasAsset('missing.bfly'), isFalse);
    await server.close();
    await handling;
  });

  test('hasAsset reads response-level status from multistatus', () async {
    String? authorization;
    final handling = server.forEach((request) async {
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      request.response
        ..statusCode = HttpStatus.multiStatus
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/missing.bfly</d:href>
    <d:status>HTTP/1.1 404 Not Found</d:status>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    expect(await createFileSystem().hasAsset('missing.bfly'), isFalse);
    expect(authorization, isNull);
    await server.close();
    await handling;
  });

  test('hasAsset accepts a successful propstat', () async {
    String? authorization;
    final handling = server.forEach((request) async {
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      request.response
        ..statusCode = HttpStatus.multiStatus
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/existing.bfly</d:href>
    <d:propstat>
      <d:prop><d:resourcetype/></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    expect(
      await createFileSystem(password: 'secret').hasAsset('existing.bfly'),
      isTrue,
    );
    expect(authorization, 'Basic ${base64Encode(utf8.encode('test:secret'))}');
    await server.close();
    await handling;
  });

  test('hasAsset accepts success when another property is missing', () async {
    final handling = server.forEach((request) async {
      request.response
        ..statusCode = HttpStatus.multiStatus
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/existing.bfly</d:href>
    <d:propstat>
      <d:prop><d:resourcetype/></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
    <d:propstat>
      <d:prop><d:displayname/></d:prop>
      <d:status>HTTP/1.1 404 Not Found</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    expect(await createFileSystem().hasAsset('existing.bfly'), isTrue);
    await server.close();
    await handling;
  });

  test(
    'hasAsset does not confuse a missing property with a missing file',
    () async {
      final handling = server.forEach((request) async {
        request.response
          ..statusCode = HttpStatus.multiStatus
          ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/existing.bfly</d:href>
    <d:propstat>
      <d:prop><d:displayname/></d:prop>
      <d:status>HTTP/1.1 404 Not Found</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''');
        await request.response.close();
      });

      expect(await createFileSystem().hasAsset('existing.bfly'), isTrue);
      await server.close();
      await handling;
    },
  );

  test('hasAsset surfaces malformed non-not-found DAV errors', () async {
    final handling = server.forEach((request) async {
      request.response
        ..statusCode = HttpStatus.multiStatus
        ..write(r'''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:"
<?xml version="1.0" encoding="utf-8"?>
<d:error xmlns:d="DAV:" xmlns:s="http://sabredav.org/ns">
  <s:exception>Sabre\DAV\Exception\Forbidden</s:exception>
</d:error>''');
      await request.response.close();
    });

    await expectLater(
      createFileSystem().hasAsset('forbidden.bfly'),
      throwsA(isA<FileSystemException>()),
    );
    await server.close();
    await handling;
  });

  test('directory listings ignore failed child propstats', () async {
    final handling = server.forEach((request) async {
      request.response
        ..statusCode = HttpStatus.multiStatus
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/folder/</d:href>
    <d:propstat>
      <d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/folder/missing.bfly</d:href>
    <d:status>HTTP/1.1 404 Not Found</d:status>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final asset = await createFileSystem().fetchRemoteAsset(
      'folder',
      readData: false,
    );

    expect(asset, isA<RawFileSystemDirectory>());
    expect((asset as RawFileSystemDirectory).assets, isEmpty);
    await server.close();
    await handling;
  });

  test(
    'directory lookup uses depth one and excludes sibling prefixes',
    () async {
      String? depth;
      final handling = server.forEach((request) async {
        depth = request.headers.value('Depth');
        request.response
          ..statusCode = HttpStatus.multiStatus
          ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/folder/</d:href>
    <d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
  </d:response>
  <d:response>
    <d:href>/folder/note.bfly</d:href>
    <d:propstat><d:prop><d:resourcetype/></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
  </d:response>
  <d:response>
    <d:href>/folder-other/wrong.bfly</d:href>
    <d:propstat><d:prop><d:resourcetype/></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
  </d:response>
  <d:response>
    <d:href>/folder/nested/wrong.bfly</d:href>
    <d:propstat><d:prop><d:resourcetype/></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
  </d:response>
</d:multistatus>''');
        await request.response.close();
      });

      final asset = await createFileSystem().fetchRemoteAsset(
        'folder',
        readData: false,
      );

      expect(depth, '1');
      expect(asset, isA<RawFileSystemDirectory>());
      expect((asset as RawFileSystemDirectory).assets, hasLength(1));
      expect(asset.assets.single.path, '/folder/note.bfly');
      await server.close();
      await handling;
    },
  );

  test('metadata can be split across successful propstats', () async {
    final handling = server.forEach((request) async {
      request.response
        ..statusCode = HttpStatus.multiStatus
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/split.bfly</d:href>
    <d:propstat>
      <d:prop><d:resourcetype/></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
    <d:propstat>
      <d:prop>
        <d:getcontentlength>42</d:getcontentlength>
        <d:getlastmodified>2026-08-11T12:00:00Z</d:getlastmodified>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final asset = await createFileSystem().fetchRemoteAsset(
      'split.bfly',
      readData: false,
    );

    expect(asset, isA<RawFileSystemFile>());
    expect((asset as RawFileSystemFile).size, 42);
    expect(asset.lastModified, DateTime.utc(2026, 8, 11, 12));
    await server.close();
    await handling;
  });

  test('conditional GET does not hide authentication errors', () async {
    final handling = server.forEach((request) async {
      methods.add(request.method);
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
    });

    await expectLater(
      createFileSystem().fetchRemoteAsset(
        'private.bfly',
        currentLastModified: DateTime.now(),
        currentSize: 10,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(methods, ['GET']);
    await server.close();
    await handling;
  });

  test('metadata lookup rejects non-not-found multistatus errors', () async {
    String? depth;
    final handling = server.forEach((request) async {
      depth = request.headers.value('Depth');
      request.response
        ..statusCode = HttpStatus.multiStatus
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/forbidden.bfly</d:href>
    <d:status>HTTP/1.1 403 Forbidden</d:status>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    await expectLater(
      createFileSystem().getRemoteFileModified('forbidden.bfly'),
      throwsA(isA<FileSystemException>()),
    );
    expect(depth, '0');
    await server.close();
    await handling;
  });
}
