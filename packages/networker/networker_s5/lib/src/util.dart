// ignore_for_file: implementation_imports

import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:http/src/client.dart';
import 'package:lib5/src/stream/message.dart';
import 'package:lib5/src/node/node.dart';
import 'package:lib5/lib5.dart';
import 'package:lib5/storage_service.dart';

Future<HiveKeyValueDB> openDB(String key) async {
  return HiveKeyValueDB(await Hive.openBox('s5-node-$key'));
}

class HiveKeyValueDB extends KeyValueDB {
  final Box<Uint8List> box;
  HiveKeyValueDB(this.box);

  @override
  bool contains(Uint8List key) => box.containsKey(String.fromCharCodes(key));

  @override
  Uint8List? get(Uint8List key) => box.get(String.fromCharCodes(key));

  @override
  void set(Uint8List key, Uint8List value) => box.put(
        String.fromCharCodes(key),
        value,
      );

  @override
  void delete(Uint8List key) {
    box.delete(String.fromCharCodes(key));
  }
}

class MyS5NodeAPIProviderWithRemoteUpload
    extends S5APIProviderWithRemoteUpload {
  final S5NodeBase node;

  final Box<Uint8List> deletedCIDs;

  MyS5NodeAPIProviderWithRemoteUpload(this.node, {required this.deletedCIDs});

  @override
  Client get httpClient => node.httpClient;

  @override
  CryptoImplementation get crypto => node.crypto;

  @override
  Future<Uint8List> downloadRawFile(Multihash hash) {
    throw UnimplementedError();
  }
  //node.downloadBytesByHash(hash);

  @override
  void deleteCID(CID cid) {
    deletedCIDs.add(cid.toBytes());
  }

  @override
  Future<Metadata> getMetadataByCID(CID cid) {
    throw UnimplementedError();
  } //=> node.getMetadataByCID(cid);

  @override
  Future<SignedRegistryEntry?> registryGet(Uint8List pk) =>
      node.registry.get(pk);

  @override
  Stream<SignedRegistryEntry> registryListen(Uint8List pk) =>
      node.registry.listen(pk);

  @override
  Future<void> registrySet(SignedRegistryEntry sre) => node.registry.set(sre);

  @override
  Future<int> streamPublish(SignedStreamMessage msg,
      {List<Uint8List>? routingHints}) async {
    await node.stream.set(msg, trusted: true);
    return 0;
  }

  @override
  Stream<SignedStreamMessage> streamSubscribe(Uint8List pk,
      {int? afterTimestamp,
      int? beforeTimestamp,
      List<Uint8List>? routingHints}) {
    return node.stream.subscribe(
      pk,
      afterTimestamp: afterTimestamp,
      beforeTimestamp: beforeTimestamp,
      routingHints: routingHints,
    );
  }
}
