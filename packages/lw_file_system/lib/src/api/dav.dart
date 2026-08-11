// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

final _davStatusPattern = RegExp(r'HTTP/\S+\s+(\d{3})', caseSensitive: false);
final _davErrorElementPattern = RegExp(
  r'<(?:[A-Za-z_][\w.-]*:)?(?:error|exception)\b',
  caseSensitive: false,
);
const _successfulMoveStatuses = {HttpStatus.created, HttpStatus.noContent};
const _successfulUploadStatuses = {
  HttpStatus.ok,
  HttpStatus.created,
  HttpStatus.noContent,
};

bool _isSuccessfulStatus(int status) => status >= 200 && status < 300;

DateTime? _parseDavDate(String? value) {
  if (value == null) return null;
  try {
    return HttpDate.parse(value);
  } on HttpException {
    return DateTime.tryParse(value);
  }
}

FileSystemException _davRequestException(
  String operation,
  String path,
  HttpClientResponse response,
) => FileSystemException(
  operation,
  path,
  OSError('${response.statusCode} ${response.reasonPhrase}'),
);

Future<Never> _throwDavRequestException(
  String operation,
  String path,
  HttpClientResponse response,
) async {
  final exception = _davRequestException(operation, path, response);
  await response.drain<void>();
  throw exception;
}

bool _isNotFoundDavBody(String content) {
  final lower = content.toLowerCase();
  return lower.contains(r'exception\notfound') ||
      lower.contains('could not be located');
}

List<int> _readDavStatusCodes(XmlElement element) {
  final statusCodes = <int>[];
  for (final status in element.findElements('status', namespace: '*')) {
    for (final match in _davStatusPattern.allMatches(status.innerText)) {
      statusCodes.add(int.parse(match.group(1)!));
    }
  }
  return statusCodes;
}

class _DavResponse {
  final String? path;
  final List<XmlElement> successfulProps;
  final bool isSuccessful;
  final bool isNotFound;
  final bool hasError;

  const _DavResponse({
    required this.path,
    required this.successfulProps,
    required this.isSuccessful,
    required this.isNotFound,
    required this.hasError,
  });

  factory _DavResponse.fromXml(XmlElement response) {
    final successfulProps = <XmlElement>[];
    var hasPropstat = false;
    for (final propstat in response.findElements('propstat', namespace: '*')) {
      hasPropstat = true;
      final statusCodes = _readDavStatusCodes(propstat);
      if (statusCodes.isEmpty || statusCodes.any(_isSuccessfulStatus)) {
        successfulProps.addAll(propstat.findElements('prop', namespace: '*'));
      }
    }
    if (!hasPropstat) {
      // Tolerate older servers that put DAV:prop directly in DAV:response.
      successfulProps.addAll(response.findElements('prop', namespace: '*'));
    }

    final href = response
        .findElements('href', namespace: '*')
        .firstOrNull
        ?.innerText;
    final statusCodes = _readDavStatusCodes(response);
    final hasSuccessfulStatus = statusCodes.any(_isSuccessfulStatus);
    final hasResponseStatus = statusCodes.isNotEmpty;
    return _DavResponse(
      path: href == null ? null : Uri.tryParse(href)?.path,
      successfulProps: successfulProps,
      isSuccessful: hasResponseStatus
          ? hasSuccessfulStatus
          : successfulProps.isNotEmpty,
      isNotFound:
          statusCodes.contains(HttpStatus.notFound) && !hasSuccessfulStatus,
      hasError: hasResponseStatus && !hasSuccessfulStatus,
    );
  }
}

XmlDocument? _parseDavMultiStatus(String content, String path) {
  try {
    final xml = XmlDocument.parse(content);
    final root = xml.rootElement;
    if (root.name.local == 'error') {
      if (_isNotFoundDavBody(content)) return null;
      throw FileSystemException('WebDAV returned an error response', path);
    }
    if (root.name.local != 'multistatus') {
      throw FileSystemException(
        'WebDAV response did not contain a multistatus document',
        path,
      );
    }
    final responses = root.findElements('response', namespace: '*');
    if (responses.isEmpty &&
        root.findElements('error', namespace: '*').isNotEmpty) {
      if (_isNotFoundDavBody(content)) return null;
      throw FileSystemException('WebDAV returned an error response', path);
    }
    return xml;
  } on FileSystemException {
    rethrow;
  } on XmlParserException catch (error) {
    if (_isNotFoundDavBody(content)) return null;
    if (_davErrorElementPattern.hasMatch(content)) {
      throw FileSystemException(
        'WebDAV returned a malformed error response',
        path,
        OSError(error.message),
      );
    }
    throw FileSystemException(
      'WebDAV returned malformed XML',
      path,
      OSError(error.message),
    );
  }
}

List<_DavResponse> _readDavResponses(XmlDocument xml) => [
  for (final response in xml.rootElement.findElements(
    'response',
    namespace: '*',
  ))
    _DavResponse.fromXml(response),
];

_DavResponse? _matchingDavResponse(
  Iterable<_DavResponse> responses,
  String fileName,
) {
  _DavResponse? fallback;
  for (final response in responses) {
    if (response.path != fileName && response.path != '$fileName/') continue;
    fallback ??= response;
    if (!response.hasError) return response;
  }
  return fallback;
}

bool _isDirectDavChild(String? path, String collectionPath) {
  if (path == null || !path.startsWith(collectionPath)) return false;
  var relativePath = path.substring(collectionPath.length);
  if (relativePath.endsWith('/')) {
    relativePath = relativePath.substring(0, relativePath.length - 1);
  }
  return relativePath.isNotEmpty && !relativePath.contains('/');
}

class _DavMetadata {
  final bool isCollection;
  final DateTime? lastModified;
  final DateTime? creationTime;
  final int? size;

  const _DavMetadata({
    required this.isCollection,
    this.lastModified,
    this.creationTime,
    this.size,
  });

  static _DavMetadata fromProps(Iterable<XmlElement> props) {
    XmlElement? resourceType;
    String? lastModified;
    String? creationDate;
    String? contentLength;

    for (final prop in props) {
      for (final property in prop.childElements) {
        switch (property.name.local) {
          case 'resourcetype':
            resourceType ??= property;
          case 'getlastmodified':
            lastModified ??= property.innerText;
          case 'creationdate':
            creationDate ??= property.innerText;
          case 'getcontentlength':
            contentLength ??= property.innerText;
        }
      }
    }

    final isCollection =
        resourceType?.findElements('collection', namespace: '*').isNotEmpty ??
        false;

    return _DavMetadata(
      isCollection: isCollection,
      lastModified: _parseDavDate(lastModified),
      creationTime: creationDate != null
          ? DateTime.tryParse(creationDate)
          : null,
      size: contentLength != null ? int.tryParse(contentLength) : null,
    );
  }
}

bool _matchesDavMetadata(
  _DavMetadata metadata, {
  required int? size,
  required DateTime? lastModified,
}) =>
    metadata.size == size &&
    metadata.lastModified != null &&
    lastModified != null &&
    metadata.lastModified!.difference(lastModified).abs().inSeconds < 2;

class DavRemoteDirectoryFileSystem extends RemoteFileSystem {
  @override
  final DavRemoteStorage storage;

  DavRemoteDirectoryFileSystem({
    required super.config,
    required this.storage,
    super.createDefault,
  });
  static Future<bool> checkConnectivity({
    required DavRemoteStorage storage,
    required PasswordStorage? passwordStorage,
    String variant = '',
    String? certificateSha1,
  }) async {
    final client = HttpClient();
    try {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              String.fromCharCodes(cert.sha1) ==
              (certificateSha1 ?? storage.certificateSha1);

      final url = storage.buildVariantUri(variant: variant);
      if (url == null) return false;

      final request = await client.openUrl('PROPFIND', url);
      request.headers.add('Depth', '0');
      final password = await passwordStorage?.read(storage);
      if (password != null) {
        request.headers.add(
          HttpHeaders.authorizationHeader,
          'Basic ${base64Encode(utf8.encode('${storage.username}:$password'))}',
        );
      }

      final response = await request.close().timeout(
        RemoteFileSystem.defaultTimeout,
      );

      if (response.statusCode == HttpStatus.ok) {
        await response.drain<void>();
        return true;
      }
      if (response.statusCode != HttpStatus.multiStatus) {
        await response.drain<void>();
        return false;
      }
      final content = await utf8.decoder.bind(response).join();
      final xml = _parseDavMultiStatus(content, url.path);
      return xml != null &&
          _readDavResponses(xml).any((item) => item.isSuccessful);
    } on NetworkException {
      return false;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  String _normalizePath(String path) {
    path = normalizePath(path);
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    return path;
  }

  @override
  Future<void> createRemoteDirectory(String path) async {
    path = _normalizePath(path);
    final response = await createRequest(path.split('/'), method: 'MKCOL');
    if (response == null) {
      throw FileSystemException(
        'Failed to create directory: Request failed',
        path,
      );
    }
    final status = response.statusCode;
    await response.drain<void>();
    if (status == HttpStatus.created) {
      return;
    } else if (status == HttpStatus.methodNotAllowed) {
      // A collection at this URL already exists. MKCOL is required to fail
      // with 405 when the Request-URI is already mapped.
      return;
    } else if (status == HttpStatus.conflict) {
      final parent = p.url.dirname(path);
      if (parent != '.' && parent != '/') {
        await createRemoteDirectory(parent);
        return createRemoteDirectory(path);
      }
    }

    throw FileSystemException(
      'Failed to create directory',
      path,
      OSError('$status ${response.reasonPhrase}'),
    );
  }

  @override
  Future<void> moveRemoteAsset(String path, String newPath) async {
    path = _normalizePath(path);
    newPath = _normalizePath(newPath);
    if (path == newPath) return;

    final destinationUri = storage.buildVariantUri(
      variant: config.currentPathVariant,
      path: newPath.split('/'),
    );

    if (destinationUri == null) {
      throw FileSystemException(
        'Failed to move asset: Invalid destination',
        path,
      );
    }

    var response = await createRequest(
      path.split('/'),
      method: 'MOVE',
      headers: {'Destination': destinationUri.toString(), 'Overwrite': 'T'},
    );

    if (response != null && response.statusCode == HttpStatus.conflict) {
      await response.drain<void>();
      final parent = p.url.dirname(newPath);
      await createRemoteDirectory(parent);
      response = await createRequest(
        path.split('/'),
        method: 'MOVE',
        headers: {'Destination': destinationUri.toString(), 'Overwrite': 'T'},
      );
    }

    if (response == null) {
      throw FileSystemException('Failed to move asset: Request failed', path);
    }

    if (!_successfulMoveStatuses.contains(response.statusCode)) {
      await _throwDavRequestException('Failed to move asset', path, response);
    }
    await response.drain<void>();
  }

  @override
  Future<void> deleteRemoteAsset(String path) async {
    path = _normalizePath(path);
    final response = await createRequest(path.split('/'), method: 'DELETE');
    if (response == null) {
      throw FileSystemException('Failed to delete asset: Request failed', path);
    }
    if (response.statusCode != HttpStatus.noContent &&
        response.statusCode != HttpStatus.notFound) {
      await _throwDavRequestException('Failed to delete asset', path, response);
    }
    await response.drain<void>();
  }

  @override
  Future<RawFileSystemEntity?> fetchRemoteAsset(
    String path, {
    bool readData = true,
    DateTime? currentLastModified,
    int? currentSize,
  }) async {
    path = _normalizePath(path);

    if (readData && currentLastModified != null && currentSize != null) {
      final response = await createRequest(
        path.split('/'),
        method: 'GET',
        headers: {'If-Modified-Since': HttpDate.format(currentLastModified)},
        timeout: RemoteFileSystem.transferTimeout,
      );

      if (response != null) {
        switch (response.statusCode) {
          case HttpStatus.notModified:
            await response.drain<void>();
            throw NotModifiedException();
          case HttpStatus.notFound:
            await response.drain<void>();
            return null;
          case HttpStatus.ok:
            final fileContent = await getBodyBytes(response);
            final lastModified = _parseDavDate(
              response.headers.value('last-modified'),
            );
            final size = int.tryParse(
              response.headers.value('content-length') ?? '',
            );

            return RawFileSystemFile(
              AssetLocation(remote: storage.identifier, path: path),
              data: fileContent,
              lastModified: lastModified,
              size: size,
            );
          case HttpStatus.methodNotAllowed || HttpStatus.notImplemented:
            await response.drain<void>();
            break;
          default:
            await _throwDavRequestException(
              'Failed to get asset',
              path,
              response,
            );
        }
      }
    }
    var response = await createRequest(
      path.split('/'),
      method: 'PROPFIND',
      headers: {'Depth': '1'},
    );

    if (response == null) {
      throw FileSystemException('Failed to read asset: Request failed', path);
    }

    final fileName = storage
        .buildVariantUri(
          path: path.split('/'),
          variant: config.currentPathVariant,
        )
        ?.path;
    final rootDirectory = storage.buildVariantUri(
      variant: config.currentPathVariant,
    );

    if (response.statusCode == HttpStatus.notFound) {
      if (path.isEmpty) {
        await response.drain<void>();
        await createRemoteDirectory(path);
        response = await createRequest(
          path.split('/'),
          method: 'PROPFIND',
          headers: {'Depth': '1'},
        );
        if (response == null) {
          throw FileSystemException(
            'Failed to read asset after creating it',
            path,
          );
        }
      } else {
        await response.drain<void>();
        return null;
      }
    }
    if (response.statusCode != HttpStatus.multiStatus ||
        fileName == null ||
        rootDirectory == null) {
      await _throwDavRequestException('Failed to read asset', path, response);
    }
    final content = await getBodyString(response);
    // Some SabreDAV servers start a 207 response before discovering an error,
    // then append a second XML document. The status alone is therefore not
    // enough to establish success.
    final xml = _parseDavMultiStatus(content, path);
    if (xml == null) return null;
    final davResponses = _readDavResponses(xml);
    final currentResponse = _matchingDavResponse(davResponses, fileName);

    if (currentResponse == null) {
      throw FileSystemException(
        'WebDAV response did not contain the requested asset',
        path,
      );
    }

    if (currentResponse.isNotFound) return null;
    if (!currentResponse.isSuccessful) {
      throw FileSystemException('WebDAV returned an error response', path);
    }

    if (currentResponse.successfulProps.isEmpty) {
      throw FileSystemException(
        'WebDAV response did not contain successful properties',
        path,
      );
    }

    final currentMeta = _DavMetadata.fromProps(currentResponse.successfulProps);

    if (!currentMeta.isCollection &&
        _matchesDavMetadata(
          currentMeta,
          size: currentSize,
          lastModified: currentLastModified,
        )) {
      throw NotModifiedException();
    }

    if (currentMeta.isCollection) {
      final collectionPath = fileName.endsWith('/') ? fileName : '$fileName/';
      final assets = await Future.wait(
        davResponses
            .where(
              (item) =>
                  item.isSuccessful &&
                  _isDirectDavChild(item.path, collectionPath),
            )
            .map((item) async {
              if (item.successfulProps.isEmpty) return null;
              final meta = _DavMetadata.fromProps(item.successfulProps);

              final hrefPath = item.path;
              if (hrefPath == null ||
                  !hrefPath.startsWith(rootDirectory.path)) {
                return null;
              }
              var childPath = hrefPath.substring(rootDirectory.path.length);
              childPath = normalizePath(Uri.decodeComponent(childPath));

              if (meta.isCollection) {
                return RawFileSystemDirectory(
                  AssetLocation(remote: storage.identifier, path: childPath),
                  lastModified: meta.lastModified,
                  creationTime: meta.creationTime,
                  size: meta.size,
                );
              } else {
                final cached = await getCachedContent(
                  childPath,
                  readData: readData,
                );
                final isUpToDate =
                    cached is RawFileSystemFile &&
                    (cached.data != null || !readData) &&
                    _matchesDavMetadata(
                      meta,
                      size: cached.size,
                      lastModified: cached.lastModified,
                    );
                return RawFileSystemFile(
                  AssetLocation(remote: storage.identifier, path: childPath),
                  data: isUpToDate && readData ? cached.data : null,
                  cached: isUpToDate,
                  lastModified: meta.lastModified,
                  creationTime: meta.creationTime,
                  size: meta.size,
                );
              }
            }),
      );
      return RawFileSystemDirectory(
        AssetLocation(remote: storage.identifier, path: path),
        assets: assets.nonNulls.toList(),
        lastModified: currentMeta.lastModified,
        creationTime: currentMeta.creationTime,
        size: currentMeta.size,
      );
    }
    if (!readData) {
      return RawFileSystemFile(
        AssetLocation(remote: storage.identifier, path: path),
        data: null,
        lastModified: currentMeta.lastModified,
        creationTime: currentMeta.creationTime,
        size: currentMeta.size,
      );
    }
    response = await createRequest(
      path.split('/'),
      method: 'GET',
      timeout: RemoteFileSystem.transferTimeout,
    );
    if (response == null) {
      return null;
    }
    if (response.statusCode == HttpStatus.notFound) {
      await response.drain<void>();
      return null;
    }
    if (response.statusCode != HttpStatus.ok) {
      await _throwDavRequestException('Failed to get asset', path, response);
    }
    final fileContent = await getBodyBytes(response);
    return RawFileSystemFile(
      AssetLocation(remote: storage.identifier, path: path),
      data: fileContent,
      lastModified: currentMeta.lastModified,
      creationTime: currentMeta.creationTime,
      size: currentMeta.size,
    );
  }

  @override
  Future<DateTime?> getRemoteFileModified(String path) async {
    path = _normalizePath(path);
    final response = await createRequest(
      path.split('/'),
      method: 'PROPFIND',
      headers: {'Depth': '0'},
    );
    if (response == null) return null;
    if (response.statusCode == HttpStatus.notFound) {
      await response.drain<void>();
      return null;
    }
    if (response.statusCode != HttpStatus.multiStatus) {
      await _throwDavRequestException(
        'Failed to read asset metadata',
        path,
        response,
      );
    }
    final body = await getBodyString(response);
    final xml = _parseDavMultiStatus(body, path);
    if (xml == null) return null;
    final fileName = storage
        .buildVariantUri(
          path: path.split('/'),
          variant: config.currentPathVariant,
        )
        ?.path;
    if (fileName == null) return null;
    final current = _matchingDavResponse(_readDavResponses(xml), fileName);
    if (current == null) {
      throw FileSystemException(
        'WebDAV response did not contain the requested asset',
        path,
      );
    }
    if (current.isNotFound) return null;
    if (!current.isSuccessful) {
      throw FileSystemException('WebDAV returned an error response', path);
    }
    return _DavMetadata.fromProps(current.successfulProps).lastModified;
  }

  @override
  Future<bool> hasAsset(String path) async {
    path = _normalizePath(path);
    final response = await createRequest(
      path.split('/'),
      method: 'PROPFIND',
      headers: {'Depth': '0'},
    );
    if (response == null) {
      return false;
    }
    if (response.statusCode == HttpStatus.notFound) {
      await response.drain<void>();
      return false;
    }
    if (response.statusCode == HttpStatus.ok) {
      await response.drain<void>();
      return true;
    }
    if (response.statusCode != HttpStatus.multiStatus) {
      await _throwDavRequestException('Failed to check asset', path, response);
    }
    final body = await getBodyString(response);
    final xml = _parseDavMultiStatus(body, path);
    if (xml == null) return false;
    final fileName = storage
        .buildVariantUri(
          path: path.split('/'),
          variant: config.currentPathVariant,
        )
        ?.path;
    if (fileName == null) return false;
    final current = _matchingDavResponse(_readDavResponses(xml), fileName);
    if (current == null || current.isNotFound) return false;
    if (current.hasError) {
      throw FileSystemException('WebDAV returned an error response', path);
    }
    // A matching response identifies the resource. Failed propstats only mean
    // individual requested properties are unavailable, not that the resource
    // itself is missing.
    return true;
  }

  @override
  Future<void> uploadFile(String path, Uint8List data) async {
    path = _normalizePath(path);

    var response = await createRequest(
      path.split('/'),
      method: 'PUT',
      bodyBytes: data,
      timeout: RemoteFileSystem.transferTimeout,
    );

    if (response != null && response.statusCode == HttpStatus.conflict) {
      await response.drain<void>();
      final directoryPath = p.url.dirname(path);
      await createRemoteDirectory(directoryPath);
      response = await createRequest(
        path.split('/'),
        method: 'PUT',
        bodyBytes: data,
        timeout: RemoteFileSystem.transferTimeout,
      );
    }

    final status = response?.statusCode;
    final reason = response?.reasonPhrase;
    await response?.drain<void>();
    if (status != null && _successfulUploadStatuses.contains(status)) {
      // File overwritten successfully
      return;
    } else if (status == HttpStatus.unauthorized ||
        status == HttpStatus.forbidden) {
      throw NetworkException(
        'Authentication failed',
        type: NetworkErrorType.authentication,
        statusCode: status,
      );
    } else if (status != null && status >= 500) {
      throw NetworkException(
        'Server error: $status $reason',
        type: NetworkErrorType.server,
        statusCode: status,
      );
    } else {
      throw NetworkException(
        'Failed to upload document: $status $reason',
        type: NetworkErrorType.client,
        statusCode: status,
      );
    }
  }

  @override
  Future<bool> isInitialized() async {
    try {
      final response = await createRequest([]);
      if (response == null) return false;
      final initialized = response.statusCode == HttpStatus.ok;
      await response.drain<void>();
      return initialized;
    } on NetworkException {
      return false;
    }
  }

  @override
  Future<void> runInitialize() async {
    await createDirectory('');
    await createDefault(this);
  }
}
