import 'package:consoler/consoler.dart';

/// Optional compatibility fallback. The built-in dispatcher also suggests names.
final class UnknownProgram extends ConsoleProgram {
  final Consoler? consoler;
  UnknownProgram([this.consoler]);
  @override
  void run(String label, List<String> args) {
    final console = consoler;
    if (console != null) {
      console.print(
        console.messages.unknownCommand(label),
        level: LogLevel.error,
      );
    } else {
      print('Unknown command: $label. Type help to see available commands.');
    }
  }

  @override
  String? getDescription() => null;
}
