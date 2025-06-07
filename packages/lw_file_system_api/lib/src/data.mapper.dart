// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'data.dart';

class ArchiveStateMapper extends ClassMapperBase<ArchiveState> {
  ArchiveStateMapper._();

  static ArchiveStateMapper? _instance;
  static ArchiveStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ArchiveStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ArchiveState';

  static Map<String, Uint8List> _$added(ArchiveState v) => v.added;
  static const Field<ArchiveState, Map<String, Uint8List>> _f$added = Field(
    'added',
    _$added,
    opt: true,
    def: const {},
  );
  static Set<String> _$removed(ArchiveState v) => v.removed;
  static const Field<ArchiveState, Set<String>> _f$removed = Field(
    'removed',
    _$removed,
    opt: true,
    def: const {},
  );
  static String? _$password(ArchiveState v) => v.password;
  static const Field<ArchiveState, String> _f$password = Field(
    'password',
    _$password,
    opt: true,
  );

  @override
  final MappableFields<ArchiveState> fields = const {
    #added: _f$added,
    #removed: _f$removed,
    #password: _f$password,
  };

  static ArchiveState _instantiate(DecodingData data) {
    return ArchiveState(
      added: data.dec(_f$added),
      removed: data.dec(_f$removed),
      password: data.dec(_f$password),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ArchiveState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ArchiveState>(map);
  }

  static ArchiveState fromJson(String json) {
    return ensureInitialized().decodeJson<ArchiveState>(json);
  }
}

mixin ArchiveStateMappable {
  String toJson() {
    return ArchiveStateMapper.ensureInitialized().encodeJson<ArchiveState>(
      this as ArchiveState,
    );
  }

  Map<String, dynamic> toMap() {
    return ArchiveStateMapper.ensureInitialized().encodeMap<ArchiveState>(
      this as ArchiveState,
    );
  }

  ArchiveStateCopyWith<ArchiveState, ArchiveState, ArchiveState> get copyWith =>
      _ArchiveStateCopyWithImpl(this as ArchiveState, $identity, $identity);
  @override
  String toString() {
    return ArchiveStateMapper.ensureInitialized().stringifyValue(
      this as ArchiveState,
    );
  }

  @override
  bool operator ==(Object other) {
    return ArchiveStateMapper.ensureInitialized().equalsValue(
      this as ArchiveState,
      other,
    );
  }

  @override
  int get hashCode {
    return ArchiveStateMapper.ensureInitialized().hashValue(
      this as ArchiveState,
    );
  }
}

extension ArchiveStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ArchiveState, $Out> {
  ArchiveStateCopyWith<$R, ArchiveState, $Out> get $asArchiveState =>
      $base.as((v, t, t2) => _ArchiveStateCopyWithImpl(v, t, t2));
}

abstract class ArchiveStateCopyWith<$R, $In extends ArchiveState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, Uint8List, ObjectCopyWith<$R, Uint8List, Uint8List>>
  get added;
  $R call({
    Map<String, Uint8List>? added,
    Set<String>? removed,
    String? password,
  });
  ArchiveStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ArchiveStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ArchiveState, $Out>
    implements ArchiveStateCopyWith<$R, ArchiveState, $Out> {
  _ArchiveStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ArchiveState> $mapper =
      ArchiveStateMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, Uint8List, ObjectCopyWith<$R, Uint8List, Uint8List>>
  get added => MapCopyWith(
    $value.added,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(added: v),
  );
  @override
  $R call({
    Map<String, Uint8List>? added,
    Set<String>? removed,
    Object? password = $none,
  }) => $apply(
    FieldCopyWithData({
      if (added != null) #added: added,
      if (removed != null) #removed: removed,
      if (password != $none) #password: password,
    }),
  );
  @override
  ArchiveState $make(CopyWithData data) => ArchiveState(
    added: data.get(#added, or: $value.added),
    removed: data.get(#removed, or: $value.removed),
    password: data.get(#password, or: $value.password),
  );

  @override
  ArchiveStateCopyWith<$R2, ArchiveState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ArchiveStateCopyWithImpl($value, $cast, t);
}
