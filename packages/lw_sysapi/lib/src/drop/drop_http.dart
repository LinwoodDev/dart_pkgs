import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'drop_http_stub.dart' if (dart.library.io) 'drop_http_native.dart';

void validateDropRemoteUri(Uri uri) {
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
  if ((!uri.isScheme('http') && !uri.isScheme('https')) ||
      uri.userInfo.isNotEmpty ||
      !host.contains('.') ||
      host.contains(':') ||
      RegExp(r'^[0-9.]+$').hasMatch(host) ||
      [
        '.localhost',
        '.local',
        '.internal',
        '.lan',
        '.home.arpa',
      ].any(host.endsWith) ||
      (uri.hasPort && uri.port != (uri.isScheme('https') ? 443 : 80))) {
    throw FormatException(
      'Dropped URL must use a public HTTP(S) host and standard port',
    );
  }
}

Future<Uint8List> readBoundedDropStream(
  Stream<List<int>> stream,
  int maxBytes,
) async {
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    if (bytes.length + chunk.length > maxBytes) {
      throw FormatException('Dropped content exceeds the $maxBytes byte limit');
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}

Future<({Uint8List bytes, String? mime})> readDropRemoteUri(
  Uri uri, {
  http.Client? client,
  required int maxBytes,
  required Duration timeout,
}) async {
  validateDropRemoteUri(uri);
  final transport = client ?? createDropHttpClient();
  final abort = Completer<void>();
  final request = http.AbortableRequest('GET', uri, abortTrigger: abort.future)
    ..followRedirects = false
    ..persistentConnection = false;
  try {
    return await (() async {
      final response = await transport.send(request);
      if (response.statusCode >= 300 && response.statusCode < 400) {
        throw http.ClientException(
          'Redirects are disabled for dropped URLs',
          uri,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw http.ClientException(
          'Unable to read dropped URL (${response.statusCode})',
          uri,
        );
      }
      if ((response.contentLength ?? 0) > maxBytes) {
        throw FormatException(
          'Dropped content exceeds the $maxBytes byte limit',
        );
      }
      return (
        bytes: await readBoundedDropStream(response.stream, maxBytes),
        mime: response.headers['content-type'],
      );
    })().timeout(timeout);
  } finally {
    abort.complete();
    if (client == null) transport.close();
  }
}
