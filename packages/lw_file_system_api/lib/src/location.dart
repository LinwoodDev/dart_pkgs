import 'package:dart_mappable/dart_mappable.dart';

part 'location.mapper.dart';

@MappableClass()
class AssetLocation with AssetLocationMappable {
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
