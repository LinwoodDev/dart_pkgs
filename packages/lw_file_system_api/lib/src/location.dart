import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;

part 'location.mapper.dart';

final universalPathContext = p.Context(style: p.Style.posix, current: '/');

@MappableClass()
class AssetLocation with AssetLocationMappable {
  final String remote;
  final String path;

  const AssetLocation({this.remote = '', required this.path});

  factory AssetLocation.local(String path, [bool absolute = false]) =>
      AssetLocation(path: path);

  static const empty = AssetLocation(path: '');

  String get pathWithoutLeadingSlash =>
      path.startsWith('/') ? path.substring(1) : path;

  bool get isEmpty => path.isEmpty;

  bool get isRemote => remote.isNotEmpty;

  bool get isLocal => !isRemote;

  String get identifier => isRemote ? '$path@$remote' : path;

  String get fileExtensionWithDot => p.extension(path);

  String get fileExtension {
    final withDot = fileExtensionWithDot;
    if (withDot.startsWith('.')) {
      return withDot.substring(1);
    }
    return withDot;
  }

  String get fileName => p.basename(path);

  String get fileNameWithoutExtension =>
      universalPathContext.basenameWithoutExtension(path);

  String get parent => p.dirname(path);

  AssetLocation buildParentLocation() {
    return AssetLocation(path: parent, remote: remote);
  }

  AssetLocation buildChildLocation(String child) {
    return AssetLocation(
      path: universalPathContext.join(path, child),
      remote: remote,
    );
  }

  AssetLocation buildSiblingLocation(String sibling) {
    return AssetLocation(
      path: universalPathContext.join(parent, sibling),
      remote: remote,
    );
  }
}
