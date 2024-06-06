import 'package:idb_shim/idb.dart';
import 'package:lw_file_system/src/models/storage.dart';

typedef GetDirectoryCallback = Future<String> Function(
    ExternalStorage? storage);
typedef InitDatabaseCallback = Future<void> Function(Database database);

class FileSystemConfig {
  final PasswordStorage passwordStorage;
  final String databaseName;
  final String? dataDatabaseName;
  final GetDirectoryCallback getDirectory;
  final InitDatabaseCallback initDatabase;

  FileSystemConfig({
    required this.passwordStorage,
    required this.databaseName,
    required this.getDirectory,
    this.dataDatabaseName,
    required this.initDatabase,
  });

  String get currentDataDatabaseName =>
      dataDatabaseName ?? '$databaseName-data';
}
