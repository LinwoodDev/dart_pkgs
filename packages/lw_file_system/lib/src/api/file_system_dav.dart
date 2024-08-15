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

  @override
  Future<RawFileSystemDirectory> createDirectory(String path) async {
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    final location = AssetLocation(
        remote: storage.identifier, path: path.substring(0, path.length - 1));
    final response = await createRequest(path.split('/'), method: 'MKCOL');
    if (response == null) return RawFileSystemDirectory(location);
    if (response.statusCode != 201) {
      throw Exception('Failed to create directory: ${response.statusCode}');
    }
    return RawFileSystemDirectory(location);
  }

  @override
  Future<void> deleteAsset(String path) async {
    final response = await createRequest(path.split('/'), method: 'DELETE');
    if (response == null) return;
    if (response.statusCode != 204) {
      throw Exception('Failed to delete asset: ${response.statusCode}');
    }
  }

  @override
  Future<RawFileSystemEntity?> readAsset(String path,
      {bool readData = true, bool forceRemote = false}) async {
    path = normalizePath(path);
    final cached = await getCachedContent(path);
    if (cached != null && !forceRemote) {
      return cached;
    }

    var response = await createRequest(path.split('/'), method: 'PROPFIND');
    final fileName = storage
        .buildVariantUri(
            path: path.split('/'), variant: config.currentPathVariant)
        ?.path;
    final rootDirectory =
        storage.buildVariantUri(variant: config.currentPathVariant);
    if (response == null) {
      return null;
    }
    var content = await getBodyString(response);
    if (response.statusCode == 404 && path.isEmpty) {
      await createRequest([], method: 'MKCOL');
      response = await createRequest(path.split('/'), method: 'PROPFIND');
    }
    if (response?.statusCode != 207 ||
        fileName == null ||
        rootDirectory == null) {
      return null;
    }
    final xml = XmlDocument.parse(content);
    final responses = xml.findAllElements('d:response').where((element) {
      final current = element.getElement('d:href')?.innerText;
      return current == fileName || current == '$fileName/';
    }).toList();

    if (responses.isEmpty) {
      return null;
    }

    final currentElement = responses.first;

    final resourceType = currentElement
        .findElements('d:propstat')
        .first
        .findElements('d:prop')
        .first
        .findElements('d:resourcetype')
        .first;
    if (resourceType.getElement('d:collection') != null) {
      final assets = await Future.wait(xml
          .findAllElements('d:response')
          .where((element) =>
              element.getElement('d:href')?.innerText.startsWith(fileName) ??
              false)
          .where((element) {
        final current = element.getElement('d:href')?.innerText;
        return current != fileName && current != '$fileName/';
      }).map((e) async {
        final currentResourceType = e
            .findElements('d:propstat')
            .first
            .findElements('d:prop')
            .first
            .findElements('d:resourcetype')
            .first;
        var path = e
            .findElements('d:href')
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
        if (currentResourceType.getElement('d:collection') != null) {
          return RawFileSystemDirectory(
            AssetLocation(remote: storage.identifier, path: path),
          );
        } else {
          final dataResponse =
              await createRequest(path.split('/'), method: 'GET');
          final fileContent =
              dataResponse == null ? null : await getBodyBytes(dataResponse);
          return RawFileSystemFile(
            AssetLocation(remote: storage.identifier, path: path),
            data: fileContent,
          );
        }
      }).toList());
      return RawFileSystemDirectory(
        AssetLocation(remote: storage.identifier, path: path),
        assets: assets,
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
    final response = await createRequest(path.split('/'), method: 'PROPFIND');
    if (response?.statusCode != 207) {
      return null;
    }
    final body = await getBodyString(response!);
    final xml = XmlDocument.parse(body);
    final lastModified = xml
        .findAllElements('d:response')
        .firstOrNull
        ?.findElements('d:propstat')
        .firstOrNull
        ?.findElements('d:prop')
        .firstOrNull
        ?.findElements('d:getlastmodified')
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
    final response = await createRequest(path.split('/'));
    return response?.statusCode == 200;
  }

  @override
  Future<void> updateFile(String path, Uint8List data,
      {bool forceSync = false}) async {
    // Create a copy of the path and remove the leading slash if it exists
    String modifiedPath = path;
    if (modifiedPath.startsWith('/')) {
      modifiedPath = modifiedPath.substring(1);
    }
    // Cache check
    if (!forceSync && storage.hasDocumentCached(path)) {
      cacheContent(path, data);
    }

    // Create directory if not exists
    final directoryPath = p.dirname(path);
    if (!await hasAsset(directoryPath)) {
      await createDirectory(directoryPath);
    }

    // Request to overwrite the file
    final response = await createRequest(p.split(modifiedPath),
        method: 'PUT', bodyBytes: data);
    if (response?.statusCode == 200 ||
        response?.statusCode == 201 ||
        response?.statusCode == 204) {
      // File overwritten successfully
      return;
    } else {
      // Management of error cases
      throw Exception(
          'Failed to update document: ${response?.statusCode} ${response?.reasonPhrase}');
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
