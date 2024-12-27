import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'data.mapper.dart';

@MappableClass()
class ArchiveState with ArchiveStateMappable {
  final Map<String, Uint8List> added;
  final Set<String> removed;
  final String? password;

  const ArchiveState({
    this.added = const {},
    this.removed = const {},
    this.password,
  });

  bool get isDirty => added.isNotEmpty || removed.isNotEmpty;
}

abstract class ArchiveData<T> {
  final Archive archive;
  final ArchiveState state;

  ArchiveData(this.archive, {this.state = const ArchiveState()});

  ArchiveData.build(this.archive,
      {Map<String, Uint8List> added = const {},
      Set<String> removed = const {},
      String? password})
      : state =
            ArchiveState(added: added, removed: removed, password: password);

  ArchiveData.empty({String? password})
      : archive = Archive(),
        state = ArchiveState(password: password);

  ArchiveData.fromBytes(List<int> bytes, {String? password})
      : archive = ZipDecoder().decodeBytes(bytes, password: password),
        state = ArchiveState(password: password);

  Archive export() {
    if (!state.isDirty) {
      return this.archive;
    }
    final archive = Archive();
    for (final entry in state.added.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    for (final file in this.archive) {
      if (state.removed.contains(file.name) ||
          state.added.containsKey(file.name)) {
        continue;
      }
      archive.addFile(file);
    }
    return archive;
  }

  void encrypt(String password) =>
      updateState(state.copyWith(password: password));

  T decrypt() => updateState(state.copyWith(password: null));

  bool get isEncrypted => state.password != null;

  String? get password => state.password;

  Uint8List exportAsBytes() =>
      Uint8List.fromList(ZipEncoder(password: state.password).encode(export()));

  Uint8List? getAsset(String name) {
    final added = state.added[name];
    if (added != null) {
      return added;
    }
    if (state.removed.contains(name)) {
      return null;
    }
    final file = archive.findFile(name);
    if (file == null) {
      return null;
    }
    return file.content;
  }

  T updateState(ArchiveState state);

  T setAsset(String name, Uint8List data) => updateState(state.copyWith(
        added: {...state.added, name: data},
        removed: Set.from(state.removed)..remove(name),
      ));
  T removeAsset(String name) => removeAssets([name]);
  T removeAssets(Iterable<String> names) =>
      updateState(state.copyWith(removed: {...state.removed, ...names}));

  Iterable<String> getAssets(String path, [bool removeExtension = false]) => {
        ...archive.files.map((e) => e.name),
        ...state.added.keys,
      }
          .where((e) =>
              e.startsWith(path) && !state.removed.contains(e) && e != path)
          .map((e) => e.substring(path.length))
          .map((e) {
        if (e.startsWith('/')) e = e.substring(1);
        if (!removeExtension) return e;
        final startExtension = e.lastIndexOf('.');
        if (startExtension == -1) return e;
        return e.substring(0, startExtension);
      });
}

class SimpleArchiveData extends ArchiveData<SimpleArchiveData> {
  SimpleArchiveData(super.archive, {super.state});
  SimpleArchiveData.build(super.archive,
      {super.added, super.password, super.removed})
      : super.build();
  SimpleArchiveData.empty({super.password}) : super.empty();
  SimpleArchiveData.fromBytes(super.bytes, {super.password})
      : super.fromBytes();

  @override
  SimpleArchiveData updateState(ArchiveState state) =>
      SimpleArchiveData(archive, state: state);
}

bool isZip(List<int> bytes) {
  final stream = InputMemoryStream(bytes);
  final signature = stream.readUint32();
  return signature == ZipFile.zipSignature;
}

bool isZipEncrypted(List<int> bytes) {
  final stream = InputMemoryStream(bytes);
  final signature = stream.readUint32();
  if (signature != ZipFile.zipSignature) {
    return false;
  }
  // Version
  stream.readUint16();
  final flags = stream.readUint16();
  return flags & 1 == 1;
}
