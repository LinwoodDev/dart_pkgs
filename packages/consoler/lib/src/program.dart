abstract class ConsoleProgram {
  String? getUsage() => null;
  String? getDescription();
  void run(String? label, List<String> args);

  bool get isHidden => getDescription() == null;
}
