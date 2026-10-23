import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// Check the resolved address at connection time and connect to that exact IP.
// Checking DNS and then allowing HttpClient to resolve again permits rebinding.
bool isPublicDropAddress(InternetAddress address) {
  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv6) {
    return (bytes[0] & 0xe0) == 0x20 &&
        !(bytes[0] == 0x20 &&
            bytes[1] == 0x01 &&
            bytes[2] == 0x0d &&
            bytes[3] == 0xb8) &&
        !(bytes[0] == 0x20 && bytes[1] == 0x02);
  }
  final a = bytes[0], b = bytes[1], c = bytes[2];
  return a != 0 &&
      a != 10 &&
      a != 127 &&
      a < 224 &&
      !(a == 100 && b >= 64 && b <= 127) &&
      !(a == 169 && b == 254) &&
      !(a == 172 && b >= 16 && b <= 31) &&
      !(a == 192 && (b == 168 || (b == 0 && (c == 0 || c == 2)))) &&
      !(a == 198 && (b == 18 || b == 19 || (b == 51 && c == 100))) &&
      !(a == 203 && b == 0 && c == 113);
}

http.Client createDropHttpClient() {
  final client = HttpClient();
  client.findProxy = (_) => 'DIRECT';
  client.connectionTimeout = const Duration(seconds: 10);
  client.connectionFactory = (uri, proxyHost, proxyPort) async {
    final addresses = await InternetAddress.lookup(uri.host);
    if (addresses.isEmpty ||
        addresses.any((address) => !isPublicDropAddress(address))) {
      throw SocketException(
        'Dropped URL resolves to a non-public address',
        address: addresses.firstOrNull,
      );
    }
    // lookup() preserves the DNS hostname on InternetAddress. SecureSocket uses
    // it for SNI/certificate verification while connecting to the vetted IP.
    return uri.isScheme('https')
        ? SecureSocket.startConnect(addresses.first, uri.port)
        : Socket.startConnect(addresses.first, uri.port);
  };
  return IOClient(client);
}
