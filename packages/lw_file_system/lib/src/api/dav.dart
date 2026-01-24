import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

class DavRemoteDirectoryFileSystem extends RemoteFileSystem {
  @override
  final DavRemoteStorage storage;

  DavRemoteDirectoryFileSystem({
    required super.config,
    required this.storage,
    super.createDefault,
  });

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
    if (response.statusCode == 201) {
      return;
    } else if (response.statusCode == 405) {
      return;
    } else if (response.statusCode == 409) {
      final parent = p.url.dirname(path);
      if (parent != '.' && parent != '/') {
        await createRemoteDirectory(parent);
        return createRemoteDirectory(path);
      }
    }

    throw FileSystemException(
      'Failed to create directory',
      path,
      OSError('${response.statusCode} ${response.reasonPhrase}'),
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

    if (destinationUri == null) return;

    var response = await createRequest(
      path.split('/'),
      method: 'MOVE',
      headers: {'Destination': destinationUri.toString(), 'Overwrite': 'T'},
    );

    if (response != null && response.statusCode == 409) {
      final parent = p.url.dirname(newPath);
      await createRemoteDirectory(parent);
      response = await createRequest(
        path.split('/'),
        method: 'MOVE',
        headers: {'Destination': destinationUri.toString(), 'Overwrite': 'T'},
      );
    }

    if (response == null) return;

    if (response.statusCode != 201 && response.statusCode != 204) {
      throw FileSystemException(
        'Failed to move asset',
        path,
        OSError('${response.statusCode} ${response.reasonPhrase}'),
      );
    }
  }

  @override
  Future<void> deleteRemoteAsset(String path) async {
    path = _normalizePath(path);
    final response = await createRequest(path.split('/'), method: 'DELETE');
    if (response == null) return;
    if (response.statusCode != 204 && response.statusCode != 404) {
      throw FileSystemException(
        'Failed to delete asset',
        path,
        OSError('${response.statusCode} ${response.reasonPhrase}'),
      );
    }
  }

  @override
  Future<RawFileSystemEntity?> fetchRemoteAsset(
    String path, {
    bool readData = true,
    DateTime? currentLastModified,
    int? currentSize,
  }) async {
    path = _normalizePath(path);

    HttpClientResponse? response;
    try {
      response = await createRequest(path.split('/'), method: 'PROPFIND');
    } catch (e) {
      rethrow;
    }

    if (response == null) {
      // If response is null here, it means createRequest returned null (invalid URL?)
      // or we caught something that wasn't a NetworkException? No we rethrow others.
      // createRequest returns null if url is null.
      throw Exception('Failed to read asset: ${storage.identifier} $path');
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

    var content = await getBodyString(response);
    if (response.statusCode == 404) {
      if (path.isEmpty) {
        await createRequest([], method: 'MKCOL');
        response = await createRequest(path.split('/'), method: 'PROPFIND');
        content = await getBodyString(response!);
      } else {
        return null;
      }
    }
    if (response.statusCode != 207 ||
        fileName == null ||
        rootDirectory == null) {
      throw Exception(
        'Failed to read asset: ${response.statusCode} ${response.reasonPhrase} $path',
      );
    }
    final xml = XmlDocument.parse(content);
    final responses = xml.findAllElements('response', namespace: '*').where((
      element,
    ) {
      final current = element
          .findElements('href', namespace: '*')
          .firstOrNull
          ?.innerText;
      return current == fileName || current == '$fileName/';
    }).toList();

    if (responses.isEmpty) {
      throw Exception(
        'Failed to read asset: No matching response found for $fileName in $path',
      );
    }

    final currentElement = responses.first;

    final prop = currentElement
        .findElements('propstat', namespace: '*')
        .first
        .findElements('prop', namespace: '*')
        .first;

    final resourceType = prop
        .findElements('resourcetype', namespace: '*')
        .first;

    final isCollection = resourceType
        .findElements('collection', namespace: '*')
        .isNotEmpty;

    if (!isCollection && currentSize != null && currentLastModified != null) {
      final contentLengthStr = prop
          .findElements('getcontentlength', namespace: '*')
          .firstOrNull
          ?.innerText;
      final lastModifiedStr = prop
          .findElements('getlastmodified', namespace: '*')
          .firstOrNull
          ?.innerText;

      if (contentLengthStr != null && lastModifiedStr != null) {
        final len = int.tryParse(contentLengthStr);
        final mod = HttpDate.parse(lastModifiedStr);

        // Allow 2 seconds of difference for modification time
        if (len == currentSize &&
            mod.difference(currentLastModified).abs().inSeconds < 2) {
          throw NotModifiedException();
        }
      }
    }

    if (isCollection) {
      final assets = await Future.wait(
        xml
            .findAllElements('response', namespace: '*')
            .where(
              (element) =>
                  element
                      .findElements('href', namespace: '*')
                      .firstOrNull
                      ?.innerText
                      .startsWith(fileName) ??
                  false,
            )
            .where((element) {
              final current = element
                  .findElements('href', namespace: '*')
                  .firstOrNull
                  ?.innerText;
              return current != fileName && current != '$fileName/';
            })
            .map((e) async {
              final currentResourceType = e
                  .findElements('propstat', namespace: '*')
                  .first
                  .findElements('prop', namespace: '*')
                  .first
                  .findElements('resourcetype', namespace: '*')
                  .first;
              var path = e
                  .findElements('href', namespace: '*')
                  .first
                  .innerText
                  .substring(rootDirectory.path.length);
              if (path.endsWith('/')) {
                path = path.substring(0, path.length - 1);
              }
              if (!path.startsWith('/')) {
                path = '/$path';
              }
              path = Uri.decodeComponent(path);
              final isDir = currentResourceType
                  .findElements('collection', namespace: '*')
                  .isNotEmpty;
              if (isDir) {
                return RawFileSystemDirectory(
                  AssetLocation(remote: storage.identifier, path: path),
                );
              } else {
                return RawFileSystemFile(
                  AssetLocation(remote: storage.identifier, path: path),
                  data: null,
                );
              }
            })
            .toList(),
      );
      return RawFileSystemDirectory(
        AssetLocation(remote: storage.identifier, path: path),
        assets: assets,
      );
    }
    if (!readData) {
      return RawFileSystemFile(
        AssetLocation(remote: storage.identifier, path: path),
        data: null,
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
    var fileContent = await getBodyBytes(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to get asset: ${response.statusCode}');
    }
    return RawFileSystemFile(
      AssetLocation(remote: storage.identifier, path: path),
      data: fileContent,
    );
  }

  @override
  Future<DateTime?> getRemoteFileModified(String path) async {
    path = _normalizePath(path);
    final response = await createRequest(path.split('/'), method: 'PROPFIND');
    if (response?.statusCode != 207) {
      return null;
    }
    final body = await getBodyString(response!);
    final xml = XmlDocument.parse(body);
    final lastModified = xml
        .findAllElements('response', namespace: '*')
        .firstOrNull
        ?.findAllElements('propstat', namespace: '*')
        .firstOrNull
        ?.findAllElements('prop', namespace: '*')
        .firstOrNull
        ?.findAllElements('getlastmodified', namespace: '*')
        .firstOrNull
        ?.innerText;
    if (lastModified == null) {
      return null;
    }
    //  Parse lastModified rfc1123-date to Iso8601

    return HttpDate.parse(lastModified);
  }

  @override
  Future<bool> hasAsset(String path) async {
    path = _normalizePath(path);
    final response = await createRequest(
      path.split('/'),
      method: 'PROPFIND',
      headers: {'Depth': '0'},
    );
    return response?.statusCode == 207 || response?.statusCode == 200;
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

    if (response != null && response.statusCode == 409) {
      final directoryPath = p.url.dirname(path);
      await createRemoteDirectory(directoryPath);
      response = await createRequest(
        path.split('/'),
        method: 'PUT',
        bodyBytes: data,
        timeout: RemoteFileSystem.transferTimeout,
      );
    }

    if (response?.statusCode == 200 ||
        response?.statusCode == 201 ||
        response?.statusCode == 204) {
      // File overwritten successfully
      return;
    } else if (response?.statusCode == 401 || response?.statusCode == 403) {
      throw NetworkException(
        'Authentication failed',
        type: NetworkErrorType.authentication,
        statusCode: response?.statusCode,
      );
    } else if (response != null && response.statusCode >= 500) {
      throw NetworkException(
        'Server error: ${response.statusCode} ${response.reasonPhrase}',
        type: NetworkErrorType.server,
        statusCode: response.statusCode,
      );
    } else {
      throw NetworkException(
        'Failed to upload document: ${response?.statusCode} ${response?.reasonPhrase}',
        type: NetworkErrorType.client,
        statusCode: response?.statusCode,
      );
    }
  }

  @override
  Future<bool> isInitialized() async {
    try {
      final response = await createRequest([]);
      return response?.statusCode == 200;
    } on NetworkException {
      return false;
    }
  }

  @override
  Future<void> runInitialize() async {
    await createDirectory('');
    await createDefault(this);
  }

  /// Check if the remote storage is reachable
  Future<bool> checkConnectivity() async {
    try {
      final response = await createRequest(
        [],
        method: 'OPTIONS',
        timeout: const Duration(seconds: 10),
      );
      return response != null && response.statusCode < 400;
    } on NetworkException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
