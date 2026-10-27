import 'dart:async';

import 'command.dart';
import 'consoler.dart';

/// A reusable, independently removable collection of commands and lifecycle hooks.
abstract class ConsoleModule {
  String get id;
  String get name => id;
  String get description => name;
  List<String> get dependencies => const [];
  Iterable<ConsoleCommand> get commands;
  FutureOr<void> onLoad(Consoler console) {}
  FutureOr<void> onUnload(Consoler console) {}
}
