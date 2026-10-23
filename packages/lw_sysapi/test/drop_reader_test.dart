import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lw_sysapi/lw_sysapi.dart';

ClipboardContent content(String type, String value) =>
    (type: type, data: Uint8List.fromList(utf8.encode(value)));

void main() {
  test(
    'safe mode blocks network reads by default while retaining supplied bytes',
    () async {
      var requests = 0;
      final result = await readSystemDropItems(
        [
          SystemDropItem(uri: Uri.parse('https://example.test/image.png')),
          SystemDropItem(contents: [content(ClipboardMimeTypes.png, 'image')]),
        ],
        client: MockClient((_) async {
          requests++;
          return http.Response('', 200);
        }),
      );
      expect(requests, 0);
      expect(result.errors, hasLength(1));
      expect(result.contents.single.content.type, ClipboardMimeTypes.png);
    },
  );

  test(
    'remote opt-in rejects private hosts, credentials, IP literals and custom ports',
    () async {
      var requests = 0;
      final result = await readSystemDropItems(
        [
          for (final url in [
            'http://localhost/a.png',
            'http://127.0.0.1/a.png',
            'http://[::1]/a.png',
            'https://host.local/a.png',
            'https://example.test:9000/a.png',
            'https://user:pass@example.test/a.png',
          ])
            SystemDropItem(uri: Uri.parse(url)),
        ],
        safeMode: false,
        client: MockClient((_) async {
          requests++;
          return http.Response('', 200);
        }),
      );
      expect(requests, 0);
      expect(result.errors, hasLength(6));
    },
  );

  test(
    'HTML cannot read a hidden local file and network file shares are rejected',
    () async {
      var fileReads = 0;
      final result = await readSystemDropItems(
        [
          SystemDropItem(
            contents: [
              content(
                ClipboardMimeTypes.html,
                '<img src="file:///private/image.png">',
              ),
            ],
          ),
          SystemDropItem(uri: Uri.parse('file://server/share/image.png')),
        ],
        safeMode: false,
        readFile: (_) async {
          fileReads++;
          return Uint8List(0);
        },
      );
      expect(fileReads, 0);
      expect(result.errors, hasLength(2));
    },
  );

  test('redirects do not trigger automatic secondary requests', () async {
    var requests = 0;
    final result = await readSystemDropItems(
      [SystemDropItem(uri: Uri.parse('https://example.test/image.png'))],
      safeMode: false,
      client: MockClient.streaming((request, _) async {
        requests++;
        expect(request.followRedirects, isFalse);
        return http.StreamedResponse(
          const Stream.empty(),
          302,
          headers: {'location': 'http://127.0.0.1/private'},
        );
      }),
    );
    expect(requests, 1);
    expect(result.errors, hasLength(1));
  });

  test('declared and chunked responses respect the byte limit', () async {
    for (final declaredLength in [100, null]) {
      final result = await readSystemDropItems(
        [SystemDropItem(uri: Uri.parse('https://example.test/image.png'))],
        safeMode: false,
        maxBytes: 3,
        client: MockClient.streaming(
          (_, _) async => http.StreamedResponse(
            Stream.fromIterable([
              [1, 2],
              [3, 4],
            ]),
            200,
            contentLength: declaredLength,
          ),
        ),
      );
      expect(result.contents, isEmpty);
      expect(result.errors, hasLength(1));
    }
  });

  test('timeouts abort remote requests', () async {
    var aborted = false;
    final result = await readSystemDropItems(
      [SystemDropItem(uri: Uri.parse('https://example.test/image.png'))],
      safeMode: false,
      timeout: const Duration(milliseconds: 10),
      client: MockClient.streaming((request, _) async {
        await (request as http.Abortable).abortTrigger;
        aborted = true;
        throw http.RequestAbortedException(request.url);
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(aborted, isTrue);
    expect(result.errors.single, isA<TimeoutException>());
  });

  test('supplied bytes preserve names, order, and MIME types', () async {
    final result = await readSystemDropItems([
      SystemDropItem(
        name: 'drawing.SVG',
        contents: [content('application/octet-stream', '<svg/>')],
      ),
      SystemDropItem(
        name: 'photo.png',
        contents: [content(ClipboardMimeTypes.png, 'image')],
      ),
      SystemDropItem(
        contents: [content(ClipboardMimeTypes.text, 'Reference notes')],
      ),
      SystemDropItem(contents: [content('application/x-butterfly-page', '{}')]),
    ]);
    expect(result.errors, isEmpty);
    expect(result.contents.map((e) => e.content.type), [
      'image/svg+xml',
      'image/png',
      ClipboardMimeTypes.text,
      'application/x-butterfly-page',
    ]);
    expect(result.contents.map((e) => e.name), [
      'drawing.SVG',
      'photo.png',
      null,
      null,
    ]);
  });

  test('a local URI reads file bytes and decodes the filename', () async {
    final uri = Uri.file('/tmp/reference image.png');
    final result = await readSystemDropItems(
      [SystemDropItem(uri: uri)],
      readFile: (value) async {
        expect(value, uri);
        return Uint8List.fromList([1, 2, 3]);
      },
    );
    expect(result.errors, isEmpty);
    expect(result.contents.single.name, 'reference image.png');
    expect(result.contents.single.content.type, ClipboardMimeTypes.png);
    expect(result.contents.single.content.data, [1, 2, 3]);
  });

  test('image bytes take priority over browser HTML and links', () async {
    final result = await readSystemDropItems(
      [
        SystemDropItem(
          contents: [
            content(ClipboardMimeTypes.png, 'image'),
            content(
              ClipboardMimeTypes.html,
              '<img src="https://example.test/photo.png">',
            ),
            content(ClipboardMimeTypes.uriList, 'https://example.test/page'),
          ],
        ),
      ],
      safeMode: false,
      client: MockClient((_) async => throw StateError('Must not download')),
    );
    expect(result.errors, isEmpty);
    expect(result.contents.single.content.type, ClipboardMimeTypes.png);
    expect(utf8.decode(result.contents.single.content.data), 'image');
  });

  test(
    'browser image drops resolve img src instead of the enclosing link',
    () async {
      final requests = <Uri>[];
      final result = await readSystemDropItems(
        [
          SystemDropItem(
            contents: [
              content(
                ClipboardMimeTypes.html,
                '<a href="https://example.test/page"><img src="https://cdn.test/image?id=42&amp;size=large"></a>',
              ),
              content(ClipboardMimeTypes.uriList, 'https://example.test/page'),
            ],
          ),
        ],
        safeMode: false,
        client: MockClient((request) async {
          requests.add(request.url);
          return http.Response.bytes(
            [1, 2, 3],
            200,
            headers: {'content-type': 'image/jpeg; charset=binary'},
          );
        }),
      );
      expect(result.errors, isEmpty);
      expect(requests, [Uri.parse('https://cdn.test/image?id=42&size=large')]);
      expect(result.contents.single.content.type, ClipboardMimeTypes.jpeg);
    },
  );

  test('Windows HTML SourceURL resolves relative image sources', () async {
    final result = await readSystemDropItems(
      [
        SystemDropItem(
          contents: [
            content(
              ClipboardMimeTypes.html,
              'Version:1.0\r\nSourceURL:https://example.test/references/page\r\n<html><img src="../photo.png"></html>\u0000',
            ),
          ],
        ),
      ],
      safeMode: false,
      client: MockClient((request) async {
        expect(request.url, Uri.parse('https://example.test/photo.png'));
        return http.Response.bytes(
          [1],
          200,
          headers: {'content-type': 'image/png'},
        );
      }),
    );
    expect(result.errors, isEmpty);
    expect(result.contents.single.content.type, ClipboardMimeTypes.png);
  });

  test('URI lists preserve batch order despite a failed download', () async {
    final result = await readSystemDropItems(
      [
        SystemDropItem(
          contents: [
            content(
              ClipboardMimeTypes.uriList,
              '# references\r\nhttps://example.test/one.png\r\nhttps://example.test/missing.png\r\nhttps://example.test/two.svg\r\nhttps://example.test/one.png\u0000',
            ),
          ],
        ),
      ],
      safeMode: false,
      client: MockClient((request) async {
        if (request.url.path == '/missing.png') {
          return http.Response('missing', 404);
        }
        return http.Response.bytes([1], 200);
      }),
    );
    expect(result.errors, hasLength(1));
    expect(result.contents.map((e) => e.content.type), [
      ClipboardMimeTypes.png,
      ClipboardMimeTypes.svg,
    ]);
    expect(result.contents.map((e) => e.name), ['one.png', 'two.svg']);
  });

  test('HTML data images are read once without a download', () async {
    final uri = Uri.dataFromBytes([1, 2, 3], mimeType: 'image/png');
    final result = await readSystemDropItems([
      SystemDropItem(
        contents: [
          content(ClipboardMimeTypes.html, '<img src="$uri"><img src="$uri">'),
        ],
      ),
    ]);
    expect(result.errors, isEmpty);
    expect(result.contents.single.content.data, [1, 2, 3]);
  });

  test(
    'plain browser URLs fetch bytes and preserve the response MIME type',
    () async {
      final result = await readSystemDropItems(
        [
          SystemDropItem(
            contents: [
              content(
                ClipboardMimeTypes.text,
                'https://example.test/photo.png',
              ),
            ],
          ),
        ],
        safeMode: false,
        client: MockClient(
          (_) async => http.Response(
            '<html>Page</html>',
            200,
            headers: {'content-type': 'text/html'},
          ),
        ),
      );
      expect(result.errors, isEmpty);
      expect(result.contents.single.content.type, ClipboardMimeTypes.html);
    },
  );
}
