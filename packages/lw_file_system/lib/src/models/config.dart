import 'dart:async';

import 'package:idb_shim/idb.dart';
import 'package:lw_file_system/lw_file_system.dart';

typedef GetDirectoryCallback = Future<String> Function(
    ExternalStorage? storage);
typedef InitDatabaseCallback = Future<void> Function(Database database);

class FileSystemConfig<T extends GeneralFileSystem> {
  final PasswordStorage passwordStorage;
  final String storeName, variant;
  final String? cacheVariant, pathVariant, dataStoreName;
  final GetDirectoryCallback getDirectory;
  final OnUpgradeNeededFunction? onDatabaseUpgrade;
  final String database;
  final int databaseVersion;
  final bool useDefaultStoreCreation;
  final String keySuffix;

  FileSystemConfig({
    required this.passwordStorage,
    required this.storeName,
    required this.getDirectory,
    this.dataStoreName,
    this.onDatabaseUpgrade,
    this.variant = '',
    this.cacheVariant,
    this.pathVariant,
    required this.database,
    required this.databaseVersion,
    this.useDefaultStoreCreation = true,
    this.keySuffix = '',
  });

  String get currentDataStoreName => dataStoreName ?? '$storeName-data';

  String get currentCacheVariant => cacheVariant ?? variant;
  String get currentPathVariant => pathVariant ?? variant;
  Future<void> defaultOnUpgradeNeeded(VersionChangeEvent event) async {
    if (event.oldVersion < 1) {
      event.database.createObjectStore(storeName);
      event.database.createObjectStore(currentDataStoreName);
    }
  }

  Future<void> runOnUpgradeNeeded(VersionChangeEvent event) async {
    if (useDefaultStoreCreation) {
      await defaultOnUpgradeNeeded(event);
    }
    await onDatabaseUpgrade?.call(event);
  }
}
