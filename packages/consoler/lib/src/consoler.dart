import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:consoler/consoler.dart';

Stream<String> _readLine() =>
    stdin.transform(utf8.decoder).transform(const LineSplitter());

List<String> _splitBySpaces(String input) {
  final args = <String>[];
  final buffer = StringBuffer();
  bool inQuote = false;
  String? quoteChar;
  int braceCount = 0;
  bool escape = false;

  for (var i = 0; i < input.length; i++) {
    final char = input[i];

    if (escape) {
      buffer.write(char);
      escape = false;
      continue;
    }

    // handle escape
    if (char == r'\') {
      escape = true;
      continue;
    }

    // toggle quote state
    if ((char == '"' || char == '\'')) {
      if (!inQuote) {
        inQuote = true;
        quoteChar = char;
      } else if (quoteChar == char) {
        inQuote = false;
      }
      buffer.write(char);
      continue;
    }

    // track braces only when not in quotes
    if (!inQuote && char == '{') {
      braceCount++;
      buffer.write(char);
      continue;
    }
    if (!inQuote && char == '}') {
      braceCount--;
      buffer.write(char);
      continue;
    }

    // split on spaces when not in quotes or braces
    if (!inQuote && braceCount == 0 && char == ' ') {
      if (buffer.isNotEmpty) {
        args.add(buffer.toString());
        buffer.clear();
      }
      continue;
    }

    buffer.write(char);
  }

  if (buffer.isNotEmpty) {
    args.add(buffer.toString());
  }

  return args;
}

final class DefaultProgramConfiguration {
  final String description;

  const DefaultProgramConfiguration({required this.description});
}

final class Consoler<T extends ConsoleProgram> {
  StreamSubscription? _subscription;
  final Map<String?, T> _programs = {};
  final String prefix;

  LogLevel minLogLevel = LogLevel.info;

  bool _firstPrefix = true;

  Consoler({
    this.prefix = '> ',
    required DefaultProgramConfiguration? defaultProgramConfig,
  }) {
    if (defaultProgramConfig != null) {
      registerProgram(null, UnknownProgram() as T);
      registerProgram(
        'help',
        HelpProgram(this, description: defaultProgramConfig.description) as T,
      );
    }
  }

  void dispose() {
    _subscription?.cancel();
    _firstPrefix = true;
  }

  void run({bool? wasPrefixShown}) {
    _subscription?.cancel();
    _subscription = _readLine().listen(_onInput);
    _firstPrefix = wasPrefixShown ?? _firstPrefix;
    if (_firstPrefix) sendPrefix();
  }

  Iterable<MapEntry<String?, T>> get programs => _programs.entries;

  void sendPrefix() {
    _firstPrefix = false;
    stdout.write('\r\n$prefix');
  }

  R runPrintZone<R>(R Function() action) => runZoned(
    action,
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, message) {
        print(message);
      },
    ),
  );

  void print(Object? message, {LogLevel? level}) {
    if (level != null && level.index < minLogLevel.index) return;
    stdout.write('\r');
    final supportsAnsi = stdout.supportsAnsiEscapes;
    level?.toConsole(supportsAnsi, true);
    stdout.write(message);
    sendPrefix();
  }

  void registerProgram(String? name, T program) {
    _programs[name] = program;
  }

  void registerPrograms(Map<String?, T> programs) {
    _programs.addAll(programs);
  }

  bool unregisterProgram(String? name) {
    return _programs.remove(name) != null;
  }

  void resetPrograms() {
    _programs.clear();
  }

  Future<void> _onInput(String input) async {
    final splitted = _splitBySpaces(input);
    final command = splitted.firstOrNull;

    runPrintZone(
      () => (_programs[command] ?? _programs[null])?.run(
        command ?? '',
        splitted.isEmpty ? const [] : splitted.sublist(1),
      ),
    );
  }
}
