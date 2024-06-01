import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

mixin RemoteStorage on ExternalStorage {
  String get defaultTemplate;
  String get username;
  String? get certificateSha1;
  String get url;
  DateTime? get lastSynced;
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

class PathHook extends MappingHook {
  static const suffix = 'Path';
  const PathHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value is Map<String, dynamic>) {
      final paths = value.entries
          .where((e) =>
              e.key.endsWith(suffix) || e.key.endsWith(suffix.toLowerCase()))
          .map((e) => MapEntry(
              e.key.substring(0, e.key.length - suffix.length), e.value));
      return {
        ...value,
        'paths': {Map<String, dynamic>.fromEntries(paths), ...?value['paths']},
      };
    }
    return value;
  }
}

class StarredHook extends MappingHook {
  const StarredHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value is List) {
      return {
        '': value,
      };
    }
    return value;
  }
}

@MappableClass(
    hook: ChainedHook([
  UnmappedPropertiesHook('extra'),
  PathHook(),
]))
sealed class ExternalStorage with _$ExternalStorage {
  final String name;
  final Map<String, String> paths;
  final Map<String, dynamic> extra;
  @MappableField(hook: StarredHook())
  final Map<String, List<String>> starred;
  final Uint8List? icon;

  ExternalStorage({this.name = '', this.paths = const {}, this.extra = const {}, this.starred = const {}, this.icon,});

  String getBasePath() => paths[''] ?? '';

  String getFullPath(String variant) {
    final path = paths[variant];
    final basePath = getBasePath();
    return path == null
      ? ''
      : path.endsWith('/') || path.isEmpty
          ? '$basePath$path'
          : '$basePath/$path';
  }

  bool hasDocumentCached(String name) {
    if (!name.startsWith('/')) {
      name = '/$name';
    }
    if (this is! RemoteStorage) {
      return true;
    }
    return (this as RemoteStorage).cachedDocuments.any((doc) {
      if (doc == name) {
        return true;
      }
      if (name.startsWith(doc)) {
        return !name.substring(doc.length + 1).contains('/');
      }
      return false;
    });
  }

  String get identifier => name.isEmpty
      ? map(
          dav: (d) => 'dav:${d.username}@${d.url}',
          local: (l) => 'local:${l.path}',
        )
      : name;

  String get label => name.isEmpty
      ? map(
          dav: (d) => d.uri.host,
          local: (l) => l.path.split('/').last,
        )
      : name;

  String encodeIdentifier() => base64Encode(utf8.encode(identifier));
}
final class DavRemoteStorage extends ExternalStorage with RemoteStorage {
  const DavRemoteStorage({
  super.name,
    @Default('') String defaultTemplate,
    @Default('') String username,
    String? certificateSha1,
    @Default('') String url,
    @Default('') String path,
    @Default('') String documentsPath,
    @Default('') String templatesPath,
    @Default('') String packsPath,
    @Default([]) List<String> cachedDocuments,
    @Default([]) List<String> starred,
    @Uint8ListJsonConverter() Uint8List? icon,
    DateTime? lastSynced,
  });

  const factory ExternalStorage.local({
    @Default('') String name,
    @Default('') String defaultTemplate,
    @Default('') String path,
    @Default('') String documentsPath,
    @Default('') String templatesPath,
    @Default('') String packsPath,
    @Uint8ListJsonConverter() Uint8List? icon,
    @Default([]) List<String> starred,
  }) = LocalStorage;

  factory ExternalStorage.fromJson(Map<String, dynamic> json) =>
      _$ExternalStorageFromJson(json);

  const ExternalStorage._();

}

abstract class PasswordStorage {
  Future<String?> read(ExternalStorage storage);
  void write(ExternalStorage storage, String password);
}

class InMemoryPasswordStorage implements PasswordStorage {
  final Map<String, String> _passwords = {};

  @override
  Future<String?> read(ExternalStorage storage) async {
    return _passwords[storage.identifier];
  }

  @override
  void write(ExternalStorage storage, String password) {
    _passwords[storage.identifier] = password;
  }
}

class SecureStoragePasswordStorage implements PasswordStorage {
  final FlutterSecureStorage secureStorage;

  SecureStoragePasswordStorage(
      [this.secureStorage = const FlutterSecureStorage()]);

  @override
  Future<String?> read(ExternalStorage storage) async {
    return secureStorage.read(key: 'remote ${storage.encodeIdentifier()}');
  }

  @override
  void write(ExternalStorage storage, String password) {
    secureStorage.write(
        key: 'remote ${storage.encodeIdentifier()}', value: password);
  }
}
