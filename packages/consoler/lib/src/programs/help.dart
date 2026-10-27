import 'package:consoler/consoler.dart';

/// Compatibility wrapper around the metadata-driven help renderer.
final class HelpProgram extends ConsoleProgram {
  final Consoler consoler;
  final String description;
  HelpProgram(this.consoler, {this.description = ''});
  @override
  String getDescription() => consoler.messages.helpDescription;
  @override
  String getUsage() => consoler.messages.helpUsage;
  @override
  void run(String label, List<String> args) => consoler.showHelp(args);
}
