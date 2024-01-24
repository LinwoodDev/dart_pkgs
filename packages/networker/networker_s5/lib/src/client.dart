// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:lib5/node.dart';
import 'package:lib5/src/crypto/base.dart';
import 'package:lib5/util.dart';
import 'package:lib5/src/stream/message.dart';
import 'package:lib5/src/crypto/encryption/mutable.dart';
import 'package:lib5_crypto_implementation_dart/lib5_crypto_implementation_dart.dart';
import 'package:networker/networker.dart';
import 'package:networker_s5/src/util.dart';

class NetworkerS5 extends NetworkerClient {
  final Uint8List secret;
  final bool encrypted;
  final Map<String, dynamic> config;
  late final S5NodeBase node;
  late final MyS5NodeAPIProviderWithRemoteUpload s5;
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
    final crypto = DartCryptoImplementation();
    node = S5NodeBase(
      config: config,
      logger: SimpleLogger(
        prefix: '[Networker-S5] ',
        format: false,
      ),
      crypto: crypto,
    );
    await node.init(
      blobDB: await openDB('blob'),
      registryDB: await openDB('registry'),
      streamDB: await openDB('stream'),
      nodesDB: await openDB('nodes'),
    );

    node.start();
    s5 = MyS5NodeAPIProviderWithRemoteUpload(
      node,
      deletedCIDs: await Hive.openBox('s5-deleted-cids'),
    );
    // TODO: Derive transport and encryption secret to use for the stream
    kp = await crypto.newKeyPairEd25519(seed: secret);
    while (node.p2p.peers.isEmpty || !node.p2p.peers.values.first.isConnected) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    subscription = s5.streamSubscribe(kp.publicKey).listen((event) async {
      onMessage(encrypted
          ? await decryptMutableBytes(event.data, secret, crypto: crypto)
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
      data: await encryptMutableBytes(data, secret, crypto: node.crypto),
      ts: DateTime.now().millisecondsSinceEpoch,
      crypto: node.crypto,
    );

    await s5.streamPublish(msg);
  }
}
