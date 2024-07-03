// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'location.dart';

class AssetLocationMapper extends ClassMapperBase<AssetLocation> {
  AssetLocationMapper._();

  static AssetLocationMapper? _instance;
  static AssetLocationMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AssetLocationMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'AssetLocation';

  static String _$remote(AssetLocation v) => v.remote;
  static const Field<AssetLocation, String> _f$remote =
      Field('remote', _$remote, opt: true, def: '');
  static String _$path(AssetLocation v) => v.path;
  static const Field<AssetLocation, String> _f$path = Field('path', _$path);
  static bool _$absolute(AssetLocation v) => v.absolute;
  static const Field<AssetLocation, bool> _f$absolute =
      Field('absolute', _$absolute, opt: true, def: false);

  @override
  final MappableFields<AssetLocation> fields = const {
    #remote: _f$remote,
    #path: _f$path,
    #absolute: _f$absolute,
  };

  static AssetLocation _instantiate(DecodingData data) {
    return AssetLocation(
        remote: data.dec(_f$remote),
        path: data.dec(_f$path),
        absolute: data.dec(_f$absolute));
  }

  @override
  final Function instantiate = _instantiate;

  static AssetLocation fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AssetLocation>(map);
  }

  static AssetLocation fromJson(String json) {
    return ensureInitialized().decodeJson<AssetLocation>(json);
  }
}

mixin AssetLocationMappable {
  String toJson() {
    return AssetLocationMapper.ensureInitialized()
        .encodeJson<AssetLocation>(this as AssetLocation);
  }

  Map<String, dynamic> toMap() {
    return AssetLocationMapper.ensureInitialized()
        .encodeMap<AssetLocation>(this as AssetLocation);
  }

  AssetLocationCopyWith<AssetLocation, AssetLocation, AssetLocation>
      get copyWith => _AssetLocationCopyWithImpl(
          this as AssetLocation, $identity, $identity);
  @override
  String toString() {
    return AssetLocationMapper.ensureInitialized()
        .stringifyValue(this as AssetLocation);
  }

  @override
  bool operator ==(Object other) {
    return AssetLocationMapper.ensureInitialized()
        .equalsValue(this as AssetLocation, other);
  }

  @override
  int get hashCode {
    return AssetLocationMapper.ensureInitialized()
        .hashValue(this as AssetLocation);
  }
}

extension AssetLocationValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AssetLocation, $Out> {
  AssetLocationCopyWith<$R, AssetLocation, $Out> get $asAssetLocation =>
      $base.as((v, t, t2) => _AssetLocationCopyWithImpl(v, t, t2));
}

abstract class AssetLocationCopyWith<$R, $In extends AssetLocation, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? remote, String? path, bool? absolute});
  AssetLocationCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AssetLocationCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AssetLocation, $Out>
    implements AssetLocationCopyWith<$R, AssetLocation, $Out> {
  _AssetLocationCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AssetLocation> $mapper =
      AssetLocationMapper.ensureInitialized();
  @override
  $R call({String? remote, String? path, bool? absolute}) =>
      $apply(FieldCopyWithData({
        if (remote != null) #remote: remote,
        if (path != null) #path: path,
        if (absolute != null) #absolute: absolute
      }));
  @override
  AssetLocation $make(CopyWithData data) => AssetLocation(
      remote: data.get(#remote, or: $value.remote),
      path: data.get(#path, or: $value.path),
      absolute: data.get(#absolute, or: $value.absolute));

  @override
  AssetLocationCopyWith<$R2, AssetLocation, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _AssetLocationCopyWithImpl($value, $cast, t);
}
