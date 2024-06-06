import 'package:lw_file_system/src/models/storage.dart';

class FileSystemConfig {
  final PasswordStorage passwordStorage;
  final String databaseName;
  final String? dataDatabaseName;

  FileSystemConfig({
    required this.passwordStorage,
    required this.databaseName,
    this.dataDatabaseName,
  });

  String get currentDataDatabaseName =>
      dataDatabaseName ?? '$databaseName-data';
}
