import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../native/lw_sysapi_base.dart';
import 'drop_models.dart';
import 'drop_http.dart';

typedef NamedClipboardContent = ({String? name, ClipboardContent content});

class SystemDropReadResult {
  final List<NamedClipboardContent> contents;
  final List<Object> errors;

  const SystemDropReadResult(this.contents, this.errors);
}

extension SystemDropDetailsReader on SystemDropDetails {
  Future<SystemDropReadResult> readContents({
    bool safeMode = true,
    int maxBytes = 32 * 1024 * 1024,
    Duration timeout = const Duration(seconds: 30),
  }) => readSystemDropItems(
    items,
    safeMode: safeMode,
    maxBytes: maxBytes,
    timeout: timeout,
  );
}

/// Resolves local files, browser image fragments, URI lists and direct bytes.
/// Alternative representations of one item are consumed only once. A failed
/// file does not prevent the remaining files from being returned.
Future<SystemDropReadResult> readSystemDropItems(
  Iterable<SystemDropItem> items, {
  http.Client? client,
  Future<Uint8List> Function(Uri)? readFile,
  bool safeMode = true,
  int maxBytes = 32 * 1024 * 1024,
  Duration timeout = const Duration(seconds: 30),
}) async {
  if (maxBytes <= 0 || timeout <= Duration.zero) {
    throw ArgumentError('Drop limits must be positive');
  }
  final contents = <NamedClipboardContent>[];
  final errors = <Object>[];
  final seenUris = <Uri>{};

  String mimeType(String? name, Uint8List bytes, [String? supplied]) {
    final mime = supplied?.split(';').first.trim().toLowerCase();
    return mime != null && mime.isNotEmpty && mime != 'application/octet-stream'
        ? mime
        : lookupMimeType(name ?? '', headerBytes: bytes) ??
              'application/octet-stream';
  }

  Future<void> readUri(Uri uri, {bool embedded = false}) async {
    if (!seenUris.add(uri)) return;
    try {
      Uint8List bytes;
      String? mime;
      if (uri.isScheme('data')) {
        if (uri.toString().length > maxBytes * 3 + 256) {
          throw FormatException('Dropped data URL exceeds the byte limit');
        }
        bytes = uri.data!.contentAsBytes();
        mime = uri.data!.mimeType;
      } else if (uri.isScheme('file')) {
        if (embedded || uri.host.isNotEmpty) {
          throw FormatException(
            'Embedded or network file URLs are not allowed',
          );
        }
        bytes =
            await (readFile?.call(uri) ??
                    readBoundedDropStream(
                      XFile(uri.toFilePath()).openRead(),
                      maxBytes,
                    ))
                .timeout(timeout);
      } else if (uri.isScheme('http') || uri.isScheme('https')) {
        if (safeMode) {
          throw StateError(
            'Safe mode blocks network requests for dropped URLs',
          );
        }
        final response = await readDropRemoteUri(
          uri,
          client: client,
          maxBytes: maxBytes,
          timeout: timeout,
        );
        mime = response.mime;
        bytes = response.bytes;
      } else {
        throw FormatException('Unsupported dropped URI scheme: ${uri.scheme}');
      }
      if (bytes.length > maxBytes) {
        throw FormatException(
          'Dropped content exceeds the $maxBytes byte limit',
        );
      }
      final name = uri.isScheme('data') ? null : uri.pathSegments.lastOrNull;
      contents.add((
        name: name,
        content: (type: mimeType(name, bytes, mime), data: bytes),
      ));
    } catch (error) {
      errors.add(error);
    }
  }

  for (final item in items) {
    try {
      if (item.contents.any((content) => content.data.length > maxBytes)) {
        throw FormatException(
          'Dropped content exceeds the $maxBytes byte limit',
        );
      }
      final file = item.contents
          .where(
            (content) =>
                item.name != null ||
                (content.type != ClipboardMimeTypes.html &&
                    content.type != ClipboardMimeTypes.text &&
                    content.type != ClipboardMimeTypes.uriList),
          )
          .firstOrNull;
      if (file != null) {
        contents.add((
          name: item.name,
          content: (
            type: mimeType(item.name, file.data, file.type),
            data: file.data,
          ),
        ));
        continue;
      }

      final uris = <Uri>[
        if (item.uri != null) item.uri!,
        for (final value in item.contents.where(
          (e) => e.type == ClipboardMimeTypes.uriList,
        ))
          ...SystemDropItem.parseUriList(
            utf8.decode(value.data, allowMalformed: true),
          ),
      ];
      final htmlContent = item.contents
          .where((e) => e.type == ClipboardMimeTypes.html)
          .firstOrNull;
      if (htmlContent != null) {
        final source = utf8
            .decode(htmlContent.data, allowMalformed: true)
            .replaceAll('\u0000', '');
        final document = html.parse(source);
        final sourceUrl = RegExp(
          r'^SourceURL:(.+)$',
          multiLine: true,
        ).firstMatch(source)?.group(1)?.trim();
        final base = Uri.tryParse(
          document.querySelector('base[href]')?.attributes['href'] ??
              sourceUrl ??
              uris.firstOrNull?.toString() ??
              '',
        );
        final images = [
          for (final image in document.querySelectorAll('img[src]'))
            if (Uri.tryParse(image.attributes['src']!) case final Uri uri)
              if (uri.hasScheme || base?.hasScheme == true)
                base?.resolveUri(uri) ?? uri,
        ];
        if (images.isNotEmpty) {
          for (final uri in images) {
            await readUri(uri, embedded: true);
          }
          continue;
        }
      }
      if (uris.isNotEmpty) {
        for (final uri in uris) {
          await readUri(uri);
        }
        continue;
      }
      final text = item.contents
          .where((e) => e.type == ClipboardMimeTypes.text)
          .firstOrNull;
      if (text != null) {
        final value = utf8
            .decode(text.data, allowMalformed: true)
            .replaceAll('\u0000', '')
            .trim();
        final uri = Uri.tryParse(value);
        if (uri != null &&
            (uri.isScheme('https') ||
                uri.isScheme('http') ||
                uri.isScheme('data'))) {
          await readUri(uri);
        } else {
          contents.add((name: item.name, content: text));
        }
      } else if (htmlContent != null) {
        final value = html
            .parseFragment(utf8.decode(htmlContent.data, allowMalformed: true))
            .text;
        if (value?.isNotEmpty == true) {
          contents.add((
            name: item.name,
            content: (
              type: ClipboardMimeTypes.text,
              data: Uint8List.fromList(utf8.encode(value!)),
            ),
          ));
        }
      }
    } catch (error) {
      errors.add(error);
    }
  }
  return SystemDropReadResult(contents, errors);
}
