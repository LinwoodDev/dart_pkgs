library;

import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:networker/networker.dart';

/// A NetworkerPipe that encrypts and decrypts Uint8List data using a customizable cipher.
/// The [cipher] and [secretKey] are provided via the constructor.
/// The output format is: nonce || ciphertext || MAC.
final class E2EENetworkerPipe extends NetworkerPipe<Uint8List, List<int>> {
  final Cipher cipher;
  final SecretKey secretKey;

  E2EENetworkerPipe({required this.cipher, required this.secretKey});

  @override
  Future<Uint8List> encode(List<int> plaintext) async {
    // Generate a random nonce.
    final nonce = cipher.newNonce();

    // Encrypt the plaintext using the provided cipher.
    final secretBox = await cipher.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    return secretBox.concatenation();
  }

  @override
  Future<Uint8List> decode(Uint8List data) async {
    final secretBox = SecretBox.fromConcatenation(
      data,
      nonceLength: cipher.nonceLength,
      macLength: cipher.macAlgorithm.macLength,
    );

    // Decrypt the ciphertext.
    final plaintext = await cipher.decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(plaintext);
  }
}
