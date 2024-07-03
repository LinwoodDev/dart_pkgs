import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lw_file_system/lw_file_system.dart';

class SecureStoragePasswordStorage implements PasswordStorage {
  final FlutterSecureStorage secureStorage;
  final IOSOptions? iOptions;
  final AndroidOptions? aOptions;
  final LinuxOptions? lOptions;
  final WebOptions? webOptions;
  final MacOsOptions? mOptions;
  final WindowsOptions? wOptions;

  SecureStoragePasswordStorage({
    this.secureStorage = const FlutterSecureStorage(),
    this.iOptions,
    this.aOptions,
    this.lOptions,
    this.webOptions,
    this.mOptions,
    this.wOptions,
  });

  @override
  Future<String?> read(ExternalStorage storage) async {
    return secureStorage.read(
      key: 'remote ${storage.encodeIdentifier()}',
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }

  @override
  void write(ExternalStorage storage, String password) {
    secureStorage.write(
      key: 'remote ${storage.encodeIdentifier()}',
      value: password,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }
}
