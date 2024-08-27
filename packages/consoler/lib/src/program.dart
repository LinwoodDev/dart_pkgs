abstract class ConsoleProgram {
  String? getUsage() => null;
  String? getDescription();
  void run(List<String> args);

  bool get isHidden => getDescription() == null;
}
