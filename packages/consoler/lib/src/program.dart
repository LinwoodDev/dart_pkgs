import 'dart:async';

/// Compatibility interface for class-based commands from Consoler 1.x.
abstract class ConsoleProgram {
  String? getUsage() => null;
  String? getDescription();
  FutureOr<void> run(String label, List<String> args);
  bool get isHidden => getDescription() == null;
}
