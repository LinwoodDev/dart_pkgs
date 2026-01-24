import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:lw_file_system_api/lw_file_system_api.dart';

part 'storage.mapper.dart';

class PathHook extends MappingHook {
  static const suffix = 'Path';
  const PathHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value is Map<String, dynamic>) {
      final paths = value.entries
          .where(
            (e) =>
                e.key.endsWith(suffix) || e.key.endsWith(suffix.toLowerCase()),
          )
          .map(
            (e) => MapEntry(
              e.key.substring(0, e.key.length - suffix.length),
              e.value,
            ),
          );
      final Map? remaining = value['paths'];
      return {
        ...value,
        'paths': {...Map<String, dynamic>.fromEntries(paths), ...?remaining},
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
      final paths = value.entries
          .where((e) => e.key.startsWith(prefix) && e.key != prefix)
          .map(
            (e) =>
                MapEntry(decapitalize(e.key.substring(prefix.length)), e.value),
          );
      final Map? remaining = value['defaults'];
      return {
        ...value,
        'defaults': {...Map<String, dynamic>.fromEntries(paths), ...?remaining},
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
      return {'': value};
    }
    return value;
  }
}

@MappableClass(
  hook: ChainedHook([
    UnmappedPropertiesHook('extra'),
    PathHook(),
    TemplateHook(),
  ]),
  discriminatorKey: 'type',
)
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
    return path == null ? '' : universalPathContext.join(basePath, path);
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
  final Map<String, List<String>> pinnedPaths;

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
    this.pinnedPaths = const {},
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
      queryParameters: {...currentUri.queryParameters, ...query},
      pathSegments: {...paths, ...path},
    );
  }

  String buildVariantPath({String variant = '', List<String> path = const []}) {
    var currentPath = universalPathContext.joinAll([
      getBasePath(),
      if (variant.isNotEmpty) paths[variant] ?? '',
      ...path,
    ]);
    if (currentPath.startsWith('/')) {
      currentPath = currentPath.substring(1);
    }
    return currentPath;
  }

  Uri? buildVariantUri({
    String variant = '',
    List<String> path = const [],
    Map<String, String> query = const {},
  }) {
    final current = buildVariantPath(variant: variant, path: path);
    return buildUri(path: current.split('/'), query: query);
  }

  /// Check if a path is pinned for offline caching
  bool isPathPinned(String name, {String variant = ''}) {
    if (name.startsWith('/')) {
      name = name.substring(1);
    }
    return pinnedPaths[variant]?.any((pinnedPath) {
          if (pinnedPath.startsWith('/')) {
            pinnedPath = pinnedPath.substring(1);
          }

          if (pinnedPath == name) {
            return true;
          }
          // Check if name is inside a pinned folder (recursive)
          if (name.startsWith(pinnedPath)) {
            if (pinnedPath.isEmpty) return true;
            if (name.length > pinnedPath.length &&
                name[pinnedPath.length] == '/') {
              return true;
            }
          }
          return false;
        }) ??
        false;
  }

  /// Get all pinned paths for a variant
  List<String> getPinnedPaths({String variant = ''}) {
    return pinnedPaths[variant] ?? [];
  }
}

@MappableClass(discriminatorValue: 'dav')
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
    super.pinnedPaths,
    super.lastSynced,
    super.extra,
  });

  @override
  String get identifier => name.isEmpty ? 'dav:$username@$url' : name;

  @override
  String get label => name.isEmpty ? uri.host : name;
}

@MappableClass(discriminatorValue: 'local')
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
