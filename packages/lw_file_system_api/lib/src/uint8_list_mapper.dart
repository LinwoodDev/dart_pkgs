import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

class Uint8ListMapper extends SimpleMapper<Uint8List> {
  const Uint8ListMapper();

  @override
  Uint8List decode(dynamic value) {
    if (value is Uint8List) {
      return value;
    }
    if (value is List) {
      try {
        return Uint8List.fromList(value.cast<int>());
      } catch (_) {
        return Uint8List(0);
      }
    }
    if (value is String) {
      try {
        return Uint8List.fromList(base64Decode(value));
      } catch (_) {
        return Uint8List(0);
      }
    }
    return Uint8List(0);
  }

  @override
  dynamic encode(Uint8List self) => base64Encode(self);

  @override
  bool equals(Uint8List value, Uint8List other, MappingContext context) {
    if (identical(value, other)) {
      return true;
    }
    if (value.length != other.length) {
      return false;
    }
    for (var index = 0; index < value.length; index++) {
      if (value[index] != other[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  int hash(Uint8List value, MappingContext context) => Object.hashAll(value);

  @override
  String stringify(Uint8List value, MappingContext context) =>
      base64Encode(value);
}
