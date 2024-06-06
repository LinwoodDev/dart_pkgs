part of '../file_system_base.dart';

const allListLevel = -1;
const oneListLevel = 1;
const noListLevel = 0;

mixin GeneralDirectoryFileSystem<T> on GeneralFileSystem {
  Future<FileSystemDirectory<T>> getRootDirectory(
      {int listLevel = oneListLevel, bool readData = true}) {
    return getAsset('', listLevel: listLevel)
        .then((value) => value as FileSystemDirectory<T>);
  }

  Future<FileSystemEntity<T>?> readAsset(String path, {bool readData = true});

  Stream<FileSystemEntity<T>?> fetchAsset(String path,
      {int listLevel = oneListLevel, bool readData = true}) async* {
    final nextLevel = listLevel < 0 ? listLevel : (listLevel - 1);
    final asset = await readAsset(path, readData: readData);
    if (listLevel == 0 || asset is! FileSystemDirectory<T>) {
      yield asset;
      return;
    }
    final assets = <FileSystemEntity<T>>[];
    FileSystemDirectory<T> getDir() => asset.withAssets(assets);
    yield getDir();
    for (var child in asset.assets) {
      int? index;
      await for (final file in fetchAsset(child.fileName,
          listLevel: nextLevel, readData: readData)) {
        if (file == null) continue;
        if (index == null) {
          index = assets.length;
          assets.add(file);
        } else {
          assets[index] = file;
        }
        yield getDir();
      }
    }
    yield getDir();
  }

  Stream<List<FileSystemEntity<T>>> fetchAssets(Stream<String> paths,
      [int listLevel = oneListLevel]) {
    final files = <FileSystemEntity<T>>[];
    final streams = paths.asyncExpand((e) async* {
      int? index;
      await for (final file in fetchAsset(e, listLevel: listLevel)) {
        if (file == null) continue;
        if (index == null) {
          index = files.length;
          files.add(file);
        } else {
          files[index] = file;
        }
        yield null;
      }
    });
    return streams.map((event) => files);
  }

  Stream<List<FileSystemEntity<T>>> fetchAssetsSync(Iterable<String> paths,
          [int listLevel = oneListLevel]) =>
      fetchAssets(Stream.fromIterable(paths), listLevel);

  Future<FileSystemEntity<T>?> getAsset(String path,
          {int listLevel = oneListLevel, bool readData = true}) =>
      fetchAsset(path, listLevel: listLevel, readData: readData).last;
  Future<FileSystemDirectory<T>> createDirectory(String path);
  Future<void> updateFile(String path, T data);
  Future<String> findAvailableName(String path) =>
      _findAvailableName(path, hasAsset);

  Future<FileSystemFile<T>?> createFile(String path, T data) async {
    path = normalizePath(path);
    final uniquePath = await findAvailableName(path);
    return updateFile(uniquePath, data)
        .then((_) => getAppDocumentFile(AssetLocation.local(uniquePath), data));
  }

  Future<bool> hasAsset(String path) =>
      getAsset(path).then((value) => value != null);
  Future<void> deleteAsset(String path);

  Future<FileSystemEntity<T>?> renameAsset(String path, String newName) async {
    path = normalizePath(path);
    if (newName.startsWith('/')) {
      newName = newName.substring(1);
    }
    final asset = await getAsset(path);
    if (asset == null) return null;
    final newPath = '${path.substring(0, path.lastIndexOf('/') + 1)}$newName';
    return moveAsset(path, newPath);
  }

  Future<FileSystemEntity<T>?> duplicateAsset(
      String path, String newPath) async {
    path = normalizePath(path);
    final asset = await getAsset(path);
    if (asset == null) return null;
    if (asset is FileSystemFile<T>) {
      final data = asset.data;
      if (data != null) {
        return createFile(newPath, data);
      }
    } else if (asset is FileSystemDirectory<T>) {
      var newDir = await createDirectory(newPath);
      for (var child in asset.assets) {
        await duplicateAsset(
            '$path/${child.fileName}', '$newPath/${child.fileName}');
      }
      return newDir;
    }
    return null;
  }

  static Stream<List<RawFileSystemEntity>> fetchAssetsGlobal(
      Stream<AssetLocation> locations,
      Map<String, DirectoryFileSystem> fileSystems,
      {int listLevel = oneListLevel}) {
    final files = <RawFileSystemEntity>[];
    final streams = locations.asyncExpand((e) async* {
      final fileSystem = fileSystems[e.remote];
      if (fileSystem == null) return;
      int? index;
      await for (final file in fileSystem
          .fetchAsset(e.path, listLevel: listLevel)
          .whereNotNull()) {
        if (index == null) {
          index = files.length;
          files.add(file);
        } else {
          files[index] = file;
        }
        yield null;
      }
    });
    return streams.map((event) => files);
  }

  static Stream<List<RawFileSystemEntity>> fetchAssetsGlobalSync(
          Iterable<AssetLocation> locations,
          Map<String, DirectoryFileSystem> fileSystems,
          {int listLevel = oneListLevel}) =>
      fetchAssetsGlobal(Stream.fromIterable(locations), fileSystems,
          listLevel: listLevel);

  Future<FileSystemEntity<T>?> moveAsset(String path, String newPath) async {
    var asset = await duplicateAsset(path, newPath);
    if (asset == null) return null;
    if (path != newPath) await deleteAsset(path);
    return asset;
  }
}

abstract class DirectoryFileSystem extends GeneralFileSystem
    with GeneralDirectoryFileSystem<Uint8List> {
  DirectoryFileSystem({required super.config});

  static DirectoryFileSystem fromPlatform(FileSystemConfig config,
      {final ExternalStorage? remote}) {
    if (kIsWeb) {
      return WebDocumentFileSystem(config: config);
    } else {
      return switch (remote) {
        DavRemoteStorage e =>
          DavRemoteDirectoryFileSystem(config: config, storage: e),
        LocalStorage e => IODirectoryFileSystem(config: config, storage: e),
        _ => IODirectoryFileSystem(config: config),
      };
    }
  }

  Future<bool> moveAbsolute(String oldPath, String newPath) =>
      Future.value(false);

  Future<Uint8List?> loadAbsolute(String path) => Future.value(null);

  Future<void> saveAbsolute(String path, Uint8List bytes) => Future.value();
}
