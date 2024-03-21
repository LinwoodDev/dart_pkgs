// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:typed_data';

import 'package:networker/networker.dart';
import 'package:s5/s5.dart';
// ignore: depend_on_referenced_packages
import 'package:lib5/util.dart';
// ignore: depend_on_referenced_packages
import 'package:lib5/encryption.dart';

class NetworkerS5 extends NetworkerClient {
  final Uint8List secret;
  final bool encrypted;
  final Map<String, dynamic> config;
  late final S5 s5;
  late final KeyPairEd25519 kp;
  StreamSubscription<SignedStreamMessage>? subscription;

  @override
  Uri get address => Uri(
        scheme: 's5-stream',
        host: "encrypted",
        userInfo: base64UrlNoPaddingEncode(secret),
      );

  NetworkerS5(Map<String, dynamic> config, Uri address, [bool encrypted = true])
      : this.fromSecret(
            config, base64UrlNoPaddingDecode(address.userInfo), encrypted);

  NetworkerS5.fromSecret(this.config, this.secret, [this.encrypted = true]);

  @override
  Future<void> init() async {
    s5 = await S5.create();
    kp = await s5.crypto.newKeyPairEd25519(seed: secret);
    subscription = s5.api.streamSubscribe(kp.publicKey).listen((event) async {
      onMessage(encrypted
          ? await decryptMutableBytes(event.data, secret, crypto: s5.crypto)
          : event.data);
    });
  }

  @override
  void close() {
    subscription?.cancel();
    subscription = null;
  }

  @override
  bool get isClosed => subscription == null;

  @override
  Future<void> sendMessage(RawData data) async {
    super.sendMessage(data);
    final msg = await SignedStreamMessage.create(
      kp: kp,
      data: encrypted
          ? await encryptMutableBytes(data, secret, crypto: s5.crypto)
          : data,
      ts: DateTime.now().millisecondsSinceEpoch,
      crypto: s5.crypto,
    );

    await s5.api.streamPublish(msg);
  }
}
