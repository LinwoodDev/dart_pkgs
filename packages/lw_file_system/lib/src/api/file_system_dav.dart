import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:lw_file_system/lw_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

class DavRemoteDirectoryFileSystem extends RemoteDirectoryFileSystem {
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
  Future<RawFileSystemDirectory> createDirectory(String path) async {
    path = _normalizePath(path);
    final location = AssetLocation(remote: storage.identifier, path: path);
    final response = await createRequest(path.split('/'), method: 'MKCOL');
    if (response == null) {
      throw FileSystemException(
        'Failed to create directory: Request failed',
        path,
      );
    }
    if (response.statusCode == 201) {
      return RawFileSystemDirectory(location);
    } else if (response.statusCode == 405) {
      return RawFileSystemDirectory(location);
    } else if (response.statusCode == 409) {
      final parent = p.url.dirname(path);
      if (parent != '.' && parent != '/') {
        await createDirectory(parent);
        return createDirectory(path);
      }
    }

    throw FileSystemException(
      'Failed to create directory',
      path,
      OSError('${response.statusCode} ${response.reasonPhrase}'),
    );
  }

  @override
  Future<FileSystemEntity<Uint8List>?> moveAsset(
    String path,
    String newPath, {
    bool forceSync = false,
  }) async {
    path = _normalizePath(path);
    newPath = _normalizePath(newPath);
    if (path == newPath) return getAsset(path);

    final destinationUri = storage.buildVariantUri(
      variant: config.currentPathVariant,
      path: newPath.split('/'),
    );

    if (destinationUri == null) return null;

    var response = await createRequest(
      path.split('/'),
      method: 'MOVE',
      headers: {'Destination': destinationUri.toString(), 'Overwrite': 'T'},
    );

    if (response != null && response.statusCode == 409) {
      final parent = p.url.dirname(newPath);
      await createDirectory(parent);
      response = await createRequest(
        path.split('/'),
        method: 'MOVE',
        headers: {'Destination': destinationUri.toString(), 'Overwrite': 'T'},
      );
    }

    if (response == null) return null;

    if (response.statusCode != 201 && response.statusCode != 204) {
      throw FileSystemException(
        'Failed to move asset',
        path,
        OSError('${response.statusCode} ${response.reasonPhrase}'),
      );
    }

    return getAsset(newPath);
  }

  @override
  Future<void> deleteAsset(String path) async {
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
  Future<RawFileSystemEntity?> readAsset(
    String path, {
    bool readData = true,
    bool forceRemote = false,
  }) async {
    path = _normalizePath(path);
    final cached = await getCachedContent(path);
    if (cached != null && !forceRemote) {
      return cached;
    }

    var response = await createRequest(path.split('/'), method: 'PROPFIND');
    final fileName = storage
        .buildVariantUri(
          path: path.split('/'),
          variant: config.currentPathVariant,
        )
        ?.path;
    final rootDirectory = storage.buildVariantUri(
      variant: config.currentPathVariant,
    );
    if (response == null) {
      throw Exception('Failed to read asset: ${storage.identifier} $path');
    }
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

    final resourceType = currentElement
        .findElements('propstat', namespace: '*')
        .first
        .findElements('prop', namespace: '*')
        .first
        .findElements('resourcetype', namespace: '*')
        .first;

    final isCollection = resourceType
        .findElements('collection', namespace: '*')
        .isNotEmpty;

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
    response = await createRequest(path.split('/'), method: 'GET');
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
  Future<void> updateFile(
    String path,
    Uint8List data, {
    bool forceSync = false,
  }) async {
    path = _normalizePath(path);
    if (!forceSync && storage.hasDocumentCached(path)) {
      cacheContent(path, data);
    }

    var response = await createRequest(
      path.split('/'),
      method: 'PUT',
      bodyBytes: data,
    );

    if (response != null && response.statusCode == 409) {
      final directoryPath = p.url.dirname(path);
      await createDirectory(directoryPath);
      response = await createRequest(
        path.split('/'),
        method: 'PUT',
        bodyBytes: data,
      );
    }

    if (response?.statusCode == 200 ||
        response?.statusCode == 201 ||
        response?.statusCode == 204) {
      // File overwritten successfully
      return;
    } else {
      // Management of error cases
      throw Exception(
        'Failed to update document: ${response?.statusCode} ${response?.reasonPhrase}',
      );
    }
  }

  @override
  Future<bool> isInitialized() async {
    final response = await createRequest([]);
    return response?.statusCode == 200;
  }

  @override
  Future<void> runInitialize() async {
    await createDirectory('');
    await createDefault(this);
  }
}
