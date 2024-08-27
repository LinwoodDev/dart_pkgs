import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:consoler/consoler.dart';

Stream<String> _readLine() =>
    stdin.transform(utf8.decoder).transform(const LineSplitter());
List<String> _splitBySpaces(String input) {
  final List<String> words = [];
  bool inQuotes = false;
  String currentWord = "";

  for (int i = 0; i < input.length; i++) {
    final char = input[i];

    if (char == '"') {
      inQuotes = !inQuotes;
    } else if (char == ' ' && !inQuotes) {
      if (currentWord.isNotEmpty) {
        words.add(currentWord);
        currentWord = "";
      }
    } else {
      currentWord += char;
    }
  }

  if (currentWord.isNotEmpty) {
    words.add(currentWord);
  }

  return words;
}

final class DefaultProgramConfiguration {
  final String description;

  const DefaultProgramConfiguration({
    required this.description,
  });
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
          HelpProgram(this, description: defaultProgramConfig.description)
              as T);
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

  bool unregisterProgram(String? name) {
    return _programs.remove(name) != null;
  }

  void _onInput(String input) {
    final splitted = _splitBySpaces(input);
    (_programs[splitted.firstOrNull] ?? _programs[null])
        ?.run(splitted.isEmpty ? const [] : splitted.sublist(1));
  }
}
