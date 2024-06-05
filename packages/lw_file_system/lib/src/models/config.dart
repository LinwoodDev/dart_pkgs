import 'package:lw_file_system/src/models/storage.dart';

class FileSystemConfig {
  final PasswordStorage passwordStorage;
  final String databaseName;

  FileSystemConfig({
    required this.passwordStorage,
    required this.databaseName,
  });
}
