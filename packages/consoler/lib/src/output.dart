import 'dart:io';

abstract class ConsoleOutput {
  bool get interactive => false;
  bool get supportsAnsi => false;
  int get columns => 80;
  void write(String text);
}

final class TerminalConsoleOutput extends ConsoleOutput {
  final Stdout sink;
  TerminalConsoleOutput([Stdout? sink]) : sink = sink ?? stdout;
  @override
  bool get interactive => sink.hasTerminal;
  @override
  bool get supportsAnsi => sink.supportsAnsiEscapes;
  @override
  int get columns => sink.hasTerminal ? sink.terminalColumns : 80;
  @override
  void write(String text) => sink.write(text);
}

final class BufferConsoleOutput extends ConsoleOutput {
  final StringBuffer buffer = StringBuffer();
  @override
  void write(String text) => buffer.write(text);
  @override
  String toString() => buffer.toString();
  void clear() => buffer.clear();
}
