import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'data.mapper.dart';

@MappableClass()
class ArchiveState with ArchiveStateMappable {
  final Map<String, Uint8List> added;
  final Set<String> removed;

  const ArchiveState({this.added = const {}, this.removed = const {}});

  bool get isDirty => added.isNotEmpty || removed.isNotEmpty;
}

abstract class ArchiveData<T> {
  final Archive archive;
  final ArchiveState state;

  ArchiveData(this.archive, {this.state = const ArchiveState()});

  ArchiveData.empty()
      : archive = Archive(),
        state = ArchiveState();

  ArchiveData.fromBytes(List<int> bytes)
      : archive = ZipDecoder().decodeBytes(bytes),
        state = ArchiveState();

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

  Uint8List exportAsBytes() =>
      Uint8List.fromList(ZipEncoder().encode(export()) ?? []);

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
          .where((e) => e.startsWith(path))
          .where((e) => !state.removed.contains(e))
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
  SimpleArchiveData.empty() : super.empty();
  SimpleArchiveData.fromBytes(super.bytes);

  @override
  SimpleArchiveData updateState(ArchiveState state) =>
      SimpleArchiveData(archive, state: state);
}
