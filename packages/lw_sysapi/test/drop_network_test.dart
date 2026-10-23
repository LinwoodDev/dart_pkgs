import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lw_sysapi/src/drop/drop_http_native.dart';

void main() {
  test(
    'DNS results cannot connect to loopback, private, mapped or reserved addresses',
    () {
      for (final value in [
        '0.0.0.0',
        '10.0.0.1',
        '100.64.0.1',
        '127.0.0.1',
        '169.254.169.254',
        '172.16.0.1',
        '192.168.0.1',
        '192.0.2.1',
        '198.18.0.1',
        '224.0.0.1',
        '::1',
        'fe80::1',
        'fc00::1',
        '::ffff:127.0.0.1',
        '2001:db8::1',
        '2002:7f00:1::',
      ]) {
        expect(
          isPublicDropAddress(InternetAddress(value)),
          isFalse,
          reason: value,
        );
      }
      expect(isPublicDropAddress(InternetAddress('1.1.1.1')), isTrue);
      expect(
        isPublicDropAddress(InternetAddress('2606:4700:4700::1111')),
        isTrue,
      );
    },
  );
}
