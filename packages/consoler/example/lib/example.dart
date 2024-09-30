import 'package:consoler/consoler.dart';

class NothingProgram extends ConsoleProgram {
  @override
  void run(String label, List<String> args) {}

  @override
  String? getDescription() => null;
}

class WarningProgram extends ConsoleProgram {
  final Consoler consoler;

  WarningProgram(this.consoler);
  @override
  void run(String label, List<String> args) {
    consoler.print('Warning: This is a warning!', level: LogLevel.warning);
  }

  @override
  String? getDescription() => null;
}
