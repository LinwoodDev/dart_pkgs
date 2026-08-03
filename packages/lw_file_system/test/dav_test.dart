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

  DavRemoteDirectoryFileSystem createFileSystem() {
    final storage = DavRemoteStorage(
      name: 'dav',
      username: 'test',
      url: 'http://${server.address.host}:${server.port}',
    );
    return DavRemoteDirectoryFileSystem(
      storage: storage,
      config: FileSystemConfig(
        passwordStorage: MockPasswordStorage(),
        storeName: 'test_store',
        getDirectory: (_) async => tempDir.path,
        database: 'test_db',
        databaseVersion: 1,
      ),
    );
  }

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
}
