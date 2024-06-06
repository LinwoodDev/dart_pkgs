import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'storage.mapper.dart';

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

class TemplateHook extends MappingHook {
  static const prefix = 'default';
  const TemplateHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value is Map<String, dynamic>) {
      final paths = value.entries.where((e) => e.key.startsWith(prefix)).map(
          (e) =>
              MapEntry(decapitalize(e.key.substring(prefix.length)), e.value));
      return {
        ...value,
        'defaults': {
          Map<String, dynamic>.fromEntries(paths),
          ...?value['defaults']
        },
      };
    }
    return value;
  }

  String decapitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toLowerCase() + value.substring(1);
  }
}

class EmptyMapEntryHook extends MappingHook {
  const EmptyMapEntryHook();

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
sealed class ExternalStorage with ExternalStorageMappable {
  final String name;
  final Map<String, String> paths;
  final Map<String, dynamic> extra;
  @MappableField(hook: EmptyMapEntryHook())
  final Map<String, List<String>> starred;
  final Map<String, String> defaults;
  final Uint8List? icon;

  const ExternalStorage({
    this.name = '',
    this.paths = const {},
    this.extra = const {},
    this.starred = const {},
    this.defaults = const {},
    this.icon,
  });

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

  bool hasDocumentCached(String name) => true;

  String get identifier;

  String get label;

  String encodeIdentifier() => base64Encode(utf8.encode(identifier));
}

@MappableClass()
sealed class RemoteStorage extends ExternalStorage with RemoteStorageMappable {
  final String username;
  final String? certificateSha1;
  final String url;
  final DateTime? lastSynced;
  @MappableField(hook: EmptyMapEntryHook())
  final Map<String, List<String>> cachedDocuments;

  const RemoteStorage({
    super.name,
    super.paths,
    super.extra,
    super.starred,
    super.defaults,
    super.icon,
    required this.username,
    this.certificateSha1,
    required this.url,
    this.lastSynced,
    this.cachedDocuments = const {},
  });

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

  Uri? buildVariantUri({
    String variant = '',
    List<String> path = const [],
    Map<String, String> query = const {},
  }) {
    final current = paths[variant];
    return current?.isEmpty ?? true
        ? null
        : buildUri(
            path: [...current!.split('/'), ...path],
            query: query,
          );
  }

  @override
  bool hasDocumentCached(String name, {String variant = ''}) {
    if (!name.startsWith('/')) {
      name = '/$name';
    }
    return cachedDocuments[variant]?.any((doc) {
          if (doc == name) {
            return true;
          }
          if (name.startsWith(doc)) {
            return !name.substring(doc.length + 1).contains('/');
          }
          return false;
        }) ??
        false;
  }
}

@MappableClass()
final class DavRemoteStorage extends RemoteStorage
    with DavRemoteStorageMappable {
  const DavRemoteStorage({
    super.name,
    super.defaults,
    super.icon,
    super.paths,
    super.starred,
    required super.username,
    super.certificateSha1,
    required super.url,
    super.cachedDocuments,
    super.lastSynced,
    super.extra,
  });

  @override
  String get identifier => name.isEmpty ? 'dav:$username@$url' : name;

  @override
  String get label => name.isEmpty ? uri.host : name;
}

@MappableClass()
final class LocalStorage extends ExternalStorage with LocalStorageMappable {
  const LocalStorage({
    super.name,
    super.defaults,
    super.paths,
    super.icon,
    super.starred,
    super.extra,
  });

  @override
  String get identifier => name.isEmpty ? 'local:${getBasePath()}' : name;
  @override
  String get label => name.isEmpty ? getBasePath().split('/').last : name;
}

abstract class PasswordStorage {
  Future<String?> read(RemoteStorage storage);
  void write(RemoteStorage storage, String password);
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
  final IOSOptions? iOptions;
  final AndroidOptions? aOptions;
  final LinuxOptions? lOptions;
  final WebOptions? webOptions;
  final MacOsOptions? mOptions;
  final WindowsOptions? wOptions;

  SecureStoragePasswordStorage({
    this.secureStorage = const FlutterSecureStorage(),
    this.iOptions,
    this.aOptions,
    this.lOptions,
    this.webOptions,
    this.mOptions,
    this.wOptions,
  });

  @override
  Future<String?> read(ExternalStorage storage) async {
    return secureStorage.read(
      key: 'remote ${storage.encodeIdentifier()}',
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }

  @override
  void write(ExternalStorage storage, String password) {
    secureStorage.write(
      key: 'remote ${storage.encodeIdentifier()}',
      value: password,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }
}
