import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'plugin/plugin.dart';

part 'base.dart';
part 'client.dart';
part 'server.dart';

typedef Channel = int;

const kAnyChannel = 0;
const kAuthorityChannel = 1;
