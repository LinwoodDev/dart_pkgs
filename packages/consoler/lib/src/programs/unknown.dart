import 'package:consoler/consoler.dart';

final class UnknownProgram extends ConsoleProgram {
  @override
  void run(String label, List<String> args) {
    print(
      "Command $label not found. Type `help` to see an overview about all commands",
    );
  }

  @override
  String? getDescription() => null;
}
