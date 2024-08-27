import 'package:consoler/consoler.dart';

final class HelpProgram extends ConsoleProgram {
  final Consoler consoler;
  final String description;

  HelpProgram(
    this.consoler, {
    required this.description,
  });

  @override
  String getDescription() => "Show an overview about all commands";

  @override
  void run(List<String> args) {
    print("-----");
    print(description);
    for (final program in consoler.programs) {
      final usage = program.value.getUsage();
      final description = program.value.getDescription();
      if (description == null) continue;
      print("> ${program.key}${usage != null ? ' $usage' : ''} - $description");
    }
    print("-----");
  }
}
