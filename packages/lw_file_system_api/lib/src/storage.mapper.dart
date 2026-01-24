// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'storage.dart';

class ExternalStorageMapper extends ClassMapperBase<ExternalStorage> {
  ExternalStorageMapper._();

  static ExternalStorageMapper? _instance;
  static ExternalStorageMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ExternalStorageMapper._());
      RemoteStorageMapper.ensureInitialized();
      LocalStorageMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ExternalStorage';

  static String _$name(ExternalStorage v) => v.name;
  static const Field<ExternalStorage, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
    def: '',
  );
  static Map<String, String> _$paths(ExternalStorage v) => v.paths;
  static const Field<ExternalStorage, Map<String, String>> _f$paths = Field(
    'paths',
    _$paths,
    opt: true,
    def: const {},
  );
  static Map<String, dynamic> _$extra(ExternalStorage v) => v.extra;
  static const Field<ExternalStorage, Map<String, dynamic>> _f$extra = Field(
    'extra',
    _$extra,
    opt: true,
    def: const {},
  );
  static Map<String, List<String>> _$starred(ExternalStorage v) => v.starred;
  static const Field<ExternalStorage, Map<String, List<String>>> _f$starred =
      Field(
        'starred',
        _$starred,
        opt: true,
        def: const {},
        hook: EmptyMapEntryHook(),
      );
  static Map<String, String> _$defaults(ExternalStorage v) => v.defaults;
  static const Field<ExternalStorage, Map<String, String>> _f$defaults = Field(
    'defaults',
    _$defaults,
    opt: true,
    def: const {},
  );
  static Uint8List? _$icon(ExternalStorage v) => v.icon;
  static const Field<ExternalStorage, Uint8List> _f$icon = Field(
    'icon',
    _$icon,
    opt: true,
  );

  @override
  final MappableFields<ExternalStorage> fields = const {
    #name: _f$name,
    #paths: _f$paths,
    #extra: _f$extra,
    #starred: _f$starred,
    #defaults: _f$defaults,
    #icon: _f$icon,
  };

  @override
  final MappingHook hook = const ChainedHook([
    UnmappedPropertiesHook('extra'),
    PathHook(),
    TemplateHook(),
  ]);
  static ExternalStorage _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'ExternalStorage',
      'type',
      '${data.value['type']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ExternalStorage fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ExternalStorage>(map);
  }

  static ExternalStorage fromJson(String json) {
    return ensureInitialized().decodeJson<ExternalStorage>(json);
  }
}

mixin ExternalStorageMappable {
  String toJson();
  Map<String, dynamic> toMap();
  ExternalStorageCopyWith<ExternalStorage, ExternalStorage, ExternalStorage>
  get copyWith;
}

abstract class ExternalStorageCopyWith<$R, $In extends ExternalStorage, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>?>
  get paths;
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get extra;
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>?
  >
  get starred;
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>?>
  get defaults;
  $R call({
    String? name,
    Map<String, String>? paths,
    Map<String, dynamic>? extra,
    Map<String, List<String>>? starred,
    Map<String, String>? defaults,
    Uint8List? icon,
  });
  ExternalStorageCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class RemoteStorageMapper extends SubClassMapperBase<RemoteStorage> {
  RemoteStorageMapper._();

  static RemoteStorageMapper? _instance;
  static RemoteStorageMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RemoteStorageMapper._());
      ExternalStorageMapper.ensureInitialized().addSubMapper(_instance!);
      DavRemoteStorageMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'RemoteStorage';

  static String _$name(RemoteStorage v) => v.name;
  static const Field<RemoteStorage, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
    def: '',
  );
  static Map<String, String> _$paths(RemoteStorage v) => v.paths;
  static const Field<RemoteStorage, Map<String, String>> _f$paths = Field(
    'paths',
    _$paths,
    opt: true,
    def: const {},
  );
  static Map<String, dynamic> _$extra(RemoteStorage v) => v.extra;
  static const Field<RemoteStorage, Map<String, dynamic>> _f$extra = Field(
    'extra',
    _$extra,
    opt: true,
    def: const {},
  );
  static Map<String, List<String>> _$starred(RemoteStorage v) => v.starred;
  static const Field<RemoteStorage, Map<String, List<String>>> _f$starred =
      Field(
        'starred',
        _$starred,
        opt: true,
        def: const {},
        hook: EmptyMapEntryHook(),
      );
  static Map<String, String> _$defaults(RemoteStorage v) => v.defaults;
  static const Field<RemoteStorage, Map<String, String>> _f$defaults = Field(
    'defaults',
    _$defaults,
    opt: true,
    def: const {},
  );
  static Uint8List? _$icon(RemoteStorage v) => v.icon;
  static const Field<RemoteStorage, Uint8List> _f$icon = Field(
    'icon',
    _$icon,
    opt: true,
  );
  static String _$username(RemoteStorage v) => v.username;
  static const Field<RemoteStorage, String> _f$username = Field(
    'username',
    _$username,
  );
  static String? _$certificateSha1(RemoteStorage v) => v.certificateSha1;
  static const Field<RemoteStorage, String> _f$certificateSha1 = Field(
    'certificateSha1',
    _$certificateSha1,
    opt: true,
  );
  static String _$url(RemoteStorage v) => v.url;
  static const Field<RemoteStorage, String> _f$url = Field('url', _$url);
  static DateTime? _$lastSynced(RemoteStorage v) => v.lastSynced;
  static const Field<RemoteStorage, DateTime> _f$lastSynced = Field(
    'lastSynced',
    _$lastSynced,
    opt: true,
  );
  static Map<String, List<String>> _$pinnedPaths(RemoteStorage v) =>
      v.pinnedPaths;
  static const Field<RemoteStorage, Map<String, List<String>>> _f$pinnedPaths =
      Field(
        'pinnedPaths',
        _$pinnedPaths,
        opt: true,
        def: const {},
        hook: EmptyMapEntryHook(),
      );

  @override
  final MappableFields<RemoteStorage> fields = const {
    #name: _f$name,
    #paths: _f$paths,
    #extra: _f$extra,
    #starred: _f$starred,
    #defaults: _f$defaults,
    #icon: _f$icon,
    #username: _f$username,
    #certificateSha1: _f$certificateSha1,
    #url: _f$url,
    #lastSynced: _f$lastSynced,
    #pinnedPaths: _f$pinnedPaths,
  };

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'RemoteStorage';
  @override
  late final ClassMapperBase superMapper =
      ExternalStorageMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    UnmappedPropertiesHook('extra'),
    PathHook(),
    TemplateHook(),
  ]);

  static RemoteStorage _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'RemoteStorage',
      'type',
      '${data.value['type']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RemoteStorage fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RemoteStorage>(map);
  }

  static RemoteStorage fromJson(String json) {
    return ensureInitialized().decodeJson<RemoteStorage>(json);
  }
}

mixin RemoteStorageMappable {
  String toJson();
  Map<String, dynamic> toMap();
  RemoteStorageCopyWith<RemoteStorage, RemoteStorage, RemoteStorage>
  get copyWith;
}

abstract class RemoteStorageCopyWith<$R, $In extends RemoteStorage, $Out>
    implements ExternalStorageCopyWith<$R, $In, $Out> {
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>?>
  get paths;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get extra;
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>?
  >
  get starred;
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>?>
  get defaults;
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>?
  >
  get pinnedPaths;
  @override
  $R call({
    String? name,
    Map<String, String>? paths,
    Map<String, dynamic>? extra,
    Map<String, List<String>>? starred,
    Map<String, String>? defaults,
    Uint8List? icon,
    String? username,
    String? certificateSha1,
    String? url,
    DateTime? lastSynced,
    Map<String, List<String>>? pinnedPaths,
  });
  RemoteStorageCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class DavRemoteStorageMapper extends SubClassMapperBase<DavRemoteStorage> {
  DavRemoteStorageMapper._();

  static DavRemoteStorageMapper? _instance;
  static DavRemoteStorageMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DavRemoteStorageMapper._());
      RemoteStorageMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'DavRemoteStorage';

  static String _$name(DavRemoteStorage v) => v.name;
  static const Field<DavRemoteStorage, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
    def: '',
  );
  static Map<String, String> _$defaults(DavRemoteStorage v) => v.defaults;
  static const Field<DavRemoteStorage, Map<String, String>> _f$defaults = Field(
    'defaults',
    _$defaults,
    opt: true,
    def: const {},
  );
  static Uint8List? _$icon(DavRemoteStorage v) => v.icon;
  static const Field<DavRemoteStorage, Uint8List> _f$icon = Field(
    'icon',
    _$icon,
    opt: true,
  );
  static Map<String, String> _$paths(DavRemoteStorage v) => v.paths;
  static const Field<DavRemoteStorage, Map<String, String>> _f$paths = Field(
    'paths',
    _$paths,
    opt: true,
    def: const {},
  );
  static Map<String, List<String>> _$starred(DavRemoteStorage v) => v.starred;
  static const Field<DavRemoteStorage, Map<String, List<String>>> _f$starred =
      Field(
        'starred',
        _$starred,
        opt: true,
        def: const {},
        hook: EmptyMapEntryHook(),
      );
  static String _$username(DavRemoteStorage v) => v.username;
  static const Field<DavRemoteStorage, String> _f$username = Field(
    'username',
    _$username,
  );
  static String? _$certificateSha1(DavRemoteStorage v) => v.certificateSha1;
  static const Field<DavRemoteStorage, String> _f$certificateSha1 = Field(
    'certificateSha1',
    _$certificateSha1,
    opt: true,
  );
  static String _$url(DavRemoteStorage v) => v.url;
  static const Field<DavRemoteStorage, String> _f$url = Field('url', _$url);
  static Map<String, List<String>> _$pinnedPaths(DavRemoteStorage v) =>
      v.pinnedPaths;
  static const Field<DavRemoteStorage, Map<String, List<String>>>
  _f$pinnedPaths = Field(
    'pinnedPaths',
    _$pinnedPaths,
    opt: true,
    def: const {},
    hook: EmptyMapEntryHook(),
  );
  static DateTime? _$lastSynced(DavRemoteStorage v) => v.lastSynced;
  static const Field<DavRemoteStorage, DateTime> _f$lastSynced = Field(
    'lastSynced',
    _$lastSynced,
    opt: true,
  );
  static Map<String, dynamic> _$extra(DavRemoteStorage v) => v.extra;
  static const Field<DavRemoteStorage, Map<String, dynamic>> _f$extra = Field(
    'extra',
    _$extra,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<DavRemoteStorage> fields = const {
    #name: _f$name,
    #defaults: _f$defaults,
    #icon: _f$icon,
    #paths: _f$paths,
    #starred: _f$starred,
    #username: _f$username,
    #certificateSha1: _f$certificateSha1,
    #url: _f$url,
    #pinnedPaths: _f$pinnedPaths,
    #lastSynced: _f$lastSynced,
    #extra: _f$extra,
  };

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'dav';
  @override
  late final ClassMapperBase superMapper =
      RemoteStorageMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    UnmappedPropertiesHook('extra'),
    PathHook(),
    TemplateHook(),
  ]);

  static DavRemoteStorage _instantiate(DecodingData data) {
    return DavRemoteStorage(
      name: data.dec(_f$name),
      defaults: data.dec(_f$defaults),
      icon: data.dec(_f$icon),
      paths: data.dec(_f$paths),
      starred: data.dec(_f$starred),
      username: data.dec(_f$username),
      certificateSha1: data.dec(_f$certificateSha1),
      url: data.dec(_f$url),
      pinnedPaths: data.dec(_f$pinnedPaths),
      lastSynced: data.dec(_f$lastSynced),
      extra: data.dec(_f$extra),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DavRemoteStorage fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DavRemoteStorage>(map);
  }

  static DavRemoteStorage fromJson(String json) {
    return ensureInitialized().decodeJson<DavRemoteStorage>(json);
  }
}

mixin DavRemoteStorageMappable {
  String toJson() {
    return DavRemoteStorageMapper.ensureInitialized()
        .encodeJson<DavRemoteStorage>(this as DavRemoteStorage);
  }

  Map<String, dynamic> toMap() {
    return DavRemoteStorageMapper.ensureInitialized()
        .encodeMap<DavRemoteStorage>(this as DavRemoteStorage);
  }

  DavRemoteStorageCopyWith<DavRemoteStorage, DavRemoteStorage, DavRemoteStorage>
  get copyWith =>
      _DavRemoteStorageCopyWithImpl<DavRemoteStorage, DavRemoteStorage>(
        this as DavRemoteStorage,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return DavRemoteStorageMapper.ensureInitialized().stringifyValue(
      this as DavRemoteStorage,
    );
  }

  @override
  bool operator ==(Object other) {
    return DavRemoteStorageMapper.ensureInitialized().equalsValue(
      this as DavRemoteStorage,
      other,
    );
  }

  @override
  int get hashCode {
    return DavRemoteStorageMapper.ensureInitialized().hashValue(
      this as DavRemoteStorage,
    );
  }
}

extension DavRemoteStorageValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DavRemoteStorage, $Out> {
  DavRemoteStorageCopyWith<$R, DavRemoteStorage, $Out>
  get $asDavRemoteStorage =>
      $base.as((v, t, t2) => _DavRemoteStorageCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DavRemoteStorageCopyWith<$R, $In extends DavRemoteStorage, $Out>
    implements RemoteStorageCopyWith<$R, $In, $Out> {
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
  get defaults;
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>> get paths;
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get starred;
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get pinnedPaths;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>
  get extra;
  @override
  $R call({
    String? name,
    Map<String, String>? defaults,
    Uint8List? icon,
    Map<String, String>? paths,
    Map<String, List<String>>? starred,
    String? username,
    String? certificateSha1,
    String? url,
    Map<String, List<String>>? pinnedPaths,
    DateTime? lastSynced,
    Map<String, dynamic>? extra,
  });
  DavRemoteStorageCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DavRemoteStorageCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DavRemoteStorage, $Out>
    implements DavRemoteStorageCopyWith<$R, DavRemoteStorage, $Out> {
  _DavRemoteStorageCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DavRemoteStorage> $mapper =
      DavRemoteStorageMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
  get defaults => MapCopyWith(
    $value.defaults,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(defaults: v),
  );
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
  get paths => MapCopyWith(
    $value.paths,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(paths: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get starred => MapCopyWith(
    $value.starred,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(starred: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get pinnedPaths => MapCopyWith(
    $value.pinnedPaths,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(pinnedPaths: v),
  );
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>
  get extra => MapCopyWith(
    $value.extra,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(extra: v),
  );
  @override
  $R call({
    String? name,
    Map<String, String>? defaults,
    Object? icon = $none,
    Map<String, String>? paths,
    Map<String, List<String>>? starred,
    String? username,
    Object? certificateSha1 = $none,
    String? url,
    Map<String, List<String>>? pinnedPaths,
    Object? lastSynced = $none,
    Map<String, dynamic>? extra,
  }) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (defaults != null) #defaults: defaults,
      if (icon != $none) #icon: icon,
      if (paths != null) #paths: paths,
      if (starred != null) #starred: starred,
      if (username != null) #username: username,
      if (certificateSha1 != $none) #certificateSha1: certificateSha1,
      if (url != null) #url: url,
      if (pinnedPaths != null) #pinnedPaths: pinnedPaths,
      if (lastSynced != $none) #lastSynced: lastSynced,
      if (extra != null) #extra: extra,
    }),
  );
  @override
  DavRemoteStorage $make(CopyWithData data) => DavRemoteStorage(
    name: data.get(#name, or: $value.name),
    defaults: data.get(#defaults, or: $value.defaults),
    icon: data.get(#icon, or: $value.icon),
    paths: data.get(#paths, or: $value.paths),
    starred: data.get(#starred, or: $value.starred),
    username: data.get(#username, or: $value.username),
    certificateSha1: data.get(#certificateSha1, or: $value.certificateSha1),
    url: data.get(#url, or: $value.url),
    pinnedPaths: data.get(#pinnedPaths, or: $value.pinnedPaths),
    lastSynced: data.get(#lastSynced, or: $value.lastSynced),
    extra: data.get(#extra, or: $value.extra),
  );

  @override
  DavRemoteStorageCopyWith<$R2, DavRemoteStorage, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DavRemoteStorageCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class LocalStorageMapper extends SubClassMapperBase<LocalStorage> {
  LocalStorageMapper._();

  static LocalStorageMapper? _instance;
  static LocalStorageMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LocalStorageMapper._());
      ExternalStorageMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'LocalStorage';

  static String _$name(LocalStorage v) => v.name;
  static const Field<LocalStorage, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
    def: '',
  );
  static Map<String, String> _$defaults(LocalStorage v) => v.defaults;
  static const Field<LocalStorage, Map<String, String>> _f$defaults = Field(
    'defaults',
    _$defaults,
    opt: true,
    def: const {},
  );
  static Map<String, String> _$paths(LocalStorage v) => v.paths;
  static const Field<LocalStorage, Map<String, String>> _f$paths = Field(
    'paths',
    _$paths,
    opt: true,
    def: const {},
  );
  static Uint8List? _$icon(LocalStorage v) => v.icon;
  static const Field<LocalStorage, Uint8List> _f$icon = Field(
    'icon',
    _$icon,
    opt: true,
  );
  static Map<String, List<String>> _$starred(LocalStorage v) => v.starred;
  static const Field<LocalStorage, Map<String, List<String>>> _f$starred =
      Field(
        'starred',
        _$starred,
        opt: true,
        def: const {},
        hook: EmptyMapEntryHook(),
      );
  static Map<String, dynamic> _$extra(LocalStorage v) => v.extra;
  static const Field<LocalStorage, Map<String, dynamic>> _f$extra = Field(
    'extra',
    _$extra,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<LocalStorage> fields = const {
    #name: _f$name,
    #defaults: _f$defaults,
    #paths: _f$paths,
    #icon: _f$icon,
    #starred: _f$starred,
    #extra: _f$extra,
  };

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'local';
  @override
  late final ClassMapperBase superMapper =
      ExternalStorageMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    UnmappedPropertiesHook('extra'),
    PathHook(),
    TemplateHook(),
  ]);

  static LocalStorage _instantiate(DecodingData data) {
    return LocalStorage(
      name: data.dec(_f$name),
      defaults: data.dec(_f$defaults),
      paths: data.dec(_f$paths),
      icon: data.dec(_f$icon),
      starred: data.dec(_f$starred),
      extra: data.dec(_f$extra),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LocalStorage fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LocalStorage>(map);
  }

  static LocalStorage fromJson(String json) {
    return ensureInitialized().decodeJson<LocalStorage>(json);
  }
}

mixin LocalStorageMappable {
  String toJson() {
    return LocalStorageMapper.ensureInitialized().encodeJson<LocalStorage>(
      this as LocalStorage,
    );
  }

  Map<String, dynamic> toMap() {
    return LocalStorageMapper.ensureInitialized().encodeMap<LocalStorage>(
      this as LocalStorage,
    );
  }

  LocalStorageCopyWith<LocalStorage, LocalStorage, LocalStorage> get copyWith =>
      _LocalStorageCopyWithImpl<LocalStorage, LocalStorage>(
        this as LocalStorage,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return LocalStorageMapper.ensureInitialized().stringifyValue(
      this as LocalStorage,
    );
  }

  @override
  bool operator ==(Object other) {
    return LocalStorageMapper.ensureInitialized().equalsValue(
      this as LocalStorage,
      other,
    );
  }

  @override
  int get hashCode {
    return LocalStorageMapper.ensureInitialized().hashValue(
      this as LocalStorage,
    );
  }
}

extension LocalStorageValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LocalStorage, $Out> {
  LocalStorageCopyWith<$R, LocalStorage, $Out> get $asLocalStorage =>
      $base.as((v, t, t2) => _LocalStorageCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LocalStorageCopyWith<$R, $In extends LocalStorage, $Out>
    implements ExternalStorageCopyWith<$R, $In, $Out> {
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
  get defaults;
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>> get paths;
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get starred;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>
  get extra;
  @override
  $R call({
    String? name,
    Map<String, String>? defaults,
    Map<String, String>? paths,
    Uint8List? icon,
    Map<String, List<String>>? starred,
    Map<String, dynamic>? extra,
  });
  LocalStorageCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LocalStorageCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LocalStorage, $Out>
    implements LocalStorageCopyWith<$R, LocalStorage, $Out> {
  _LocalStorageCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LocalStorage> $mapper =
      LocalStorageMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
  get defaults => MapCopyWith(
    $value.defaults,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(defaults: v),
  );
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
  get paths => MapCopyWith(
    $value.paths,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(paths: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get starred => MapCopyWith(
    $value.starred,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(starred: v),
  );
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>>
  get extra => MapCopyWith(
    $value.extra,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(extra: v),
  );
  @override
  $R call({
    String? name,
    Map<String, String>? defaults,
    Map<String, String>? paths,
    Object? icon = $none,
    Map<String, List<String>>? starred,
    Map<String, dynamic>? extra,
  }) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (defaults != null) #defaults: defaults,
      if (paths != null) #paths: paths,
      if (icon != $none) #icon: icon,
      if (starred != null) #starred: starred,
      if (extra != null) #extra: extra,
    }),
  );
  @override
  LocalStorage $make(CopyWithData data) => LocalStorage(
    name: data.get(#name, or: $value.name),
    defaults: data.get(#defaults, or: $value.defaults),
    paths: data.get(#paths, or: $value.paths),
    icon: data.get(#icon, or: $value.icon),
    starred: data.get(#starred, or: $value.starred),
    extra: data.get(#extra, or: $value.extra),
  );

  @override
  LocalStorageCopyWith<$R2, LocalStorage, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _LocalStorageCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

