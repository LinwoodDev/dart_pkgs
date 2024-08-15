import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;

part 'location.mapper.dart';

@MappableClass()
class AssetLocation with AssetLocationMappable {
  final String remote;
  final String path;

  const AssetLocation({
    this.remote = '',
    required this.path,
  });

  factory AssetLocation.local(String path, [bool absolute = false]) =>
      AssetLocation(path: path);

  static const empty = AssetLocation(path: '');

  bool get isEmpty => path.isEmpty;

  bool get isRemote => remote.isNotEmpty;

  String get identifier => isRemote ? '$path@$remote' : path;

  String get fileExtension => p.extension(path);

  String get fileName => p.basename(path);

  String get fileNameWithoutExtension => p.basenameWithoutExtension(path);

  String get parent => p.dirname(path);

  AssetLocation buildParentLocation() {
    return AssetLocation(path: parent, remote: remote);
  }

  AssetLocation buildChildLocation(String child) {
    return AssetLocation(path: p.join(path, child), remote: remote);
  }

  AssetLocation buildSiblingLocation(String sibling) {
    return AssetLocation(path: p.join(parent, sibling), remote: remote);
  }
}
