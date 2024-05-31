import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

part 'models.mapper.dart';

mixin RemoteStorage {
  String get defaultTemplate;
  String get username;
  String? get certificateSha1;
  String get url;
  String get path;
  String get documentsPath;
  String get templatesPath;
  String get packsPath;
  String get fullDocumentsPath;
  String get fullTemplatesPath;
  String get fullPacksPath;
  DateTime? get lastSynced;
  String get identifier;
  List<String> get cachedDocuments;

  Uri get uri => Uri.parse(url);
  String get displayName => '$username@${uri.host}';

  Uri buildUri({
    List<String> path = const [],
    Map<String, String> query = const {},
  }) {
    final currentUri = uri;
    final paths = List<String>.from(currentUri.pathSegments);
    if (paths.lastOrNull == '') {
      paths.removeLast();
    }
    return Uri(
      scheme: currentUri.scheme,
      port: currentUri.port,
      host: currentUri.host,
      queryParameters: {
        ...currentUri.queryParameters,
        ...query,
      },
      pathSegments: {
        ...paths,
        ...path,
      },
    );
  }

  Uri? buildDocumentsUri({
    List<String> path = const [],
    Map<String, String> query = const {},
  }) {
    return fullDocumentsPath.isEmpty
        ? null
        : buildUri(
            path: [...fullDocumentsPath.split('/'), ...path],
            query: query,
          );
  }

  Uri? buildTemplatesUri({
    List<String> path = const [],
    Map<String, String> query = const {},
  }) {
    return fullTemplatesPath.isEmpty
        ? null
        : buildUri(
            path: [...fullTemplatesPath.split('/'), ...path],
            query: query,
          );
  }

  Uri? buildPacksUri({
    List<String> path = const [],
    Map<String, String> query = const {},
  }) {
    return fullPacksPath.isEmpty
        ? null
        : buildUri(
            path: [...fullPacksPath.split('/'), ...path],
            query: query,
          );
  }

  bool hasDocumentCached(String name);

  Future<String?> getRemotePassword();
}

class AssetLocation {
  final String remote;
  final String path;
  final bool absolute;

  const AssetLocation({
    this.remote = '',
    required this.path,
    this.absolute = false,
  });

  factory AssetLocation.local(String path, [bool absolute = false]) =>
      AssetLocation(path: path, absolute: absolute);

  static const empty = AssetLocation(path: '');

  bool get isRemote => remote.isNotEmpty;

  String get identifier =>
      isRemote ? '$pathWithLeadingSlash@$remote' : pathWithLeadingSlash;

  String get pathWithLeadingSlash => path.startsWith('/') ? path : '/$path';

  String get pathWithoutLeadingSlash =>
      path.startsWith('/') ? path.substring(1) : path;

  String get fileExtension =>
      fileName.contains('.') ? fileName.split('.').last : '';

  String get fileName => path.split('/').last;
  String get parent {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash < 0) return '';
    return path.substring(0, lastSlash);
  }

  bool isSame(AssetLocation other) =>
      pathWithLeadingSlash == other.pathWithLeadingSlash &&
      remote == other.remote;
}

sealed class AppDocumentEntity {
  final AssetLocation location;

  AppDocumentEntity(this.location);

  String get fileName => location.fileName;

  String get fileExtension => location.fileExtension;

  String get fileNameWithoutExtension => fileName.substring(0,
      fileName.contains('.') ? fileName.lastIndexOf('.') : fileName.length - 1);

  String get pathWithLeadingSlash => location.pathWithLeadingSlash;

  String get pathWithoutLeadingSlash => location.pathWithoutLeadingSlash;

  String get parent => pathWithLeadingSlash
      .split('/')
      .sublist(0, pathWithLeadingSlash.split('/').length - 1)
      .join('/');
}

class AppDocumentFile extends AppDocumentEntity {
  final List<int> data;
  final bool cached;
  final Uint8List? thumbnail;

  AppDocumentFile(
    super.location, {
    this.data = const [],
    this.cached = false,
    this.thumbnail,
  });
}

class AppDocumentDirectory extends AppDocumentEntity {
  final List<AppDocumentEntity> assets;

  AppDocumentDirectory(super.location, {this.assets = const []});
}
