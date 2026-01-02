import 'storage.dart';

class MockPasswordStorage implements PasswordStorage {
  @override
  Future<String?> read(ExternalStorage storage) async => null;

  @override
  void write(ExternalStorage storage, String password) {}
}
