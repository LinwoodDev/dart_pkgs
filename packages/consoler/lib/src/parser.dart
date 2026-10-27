/// Splits a command line without expanding variables or executing shell code.
/// Quotes preserve whitespace and empty arguments. Backslashes escape quotes,
/// whitespace and backslashes; other backslashes (e.g. in paths) are retained.
List<String> parseCommandLine(String input) {
  final words = <String>[];
  var word = StringBuffer();
  String? quote;
  var started = false;
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char == r'\' && quote != "'") {
      final next = i + 1 < input.length ? input[i + 1] : null;
      if (next != null &&
          (next == r'\' || next == '"' || next == "'" || next.trim().isEmpty)) {
        word.write(next);
        started = true;
        i++;
        continue;
      }
    }
    if (quote != null) {
      if (char == quote) {
        quote = null;
      } else {
        word.write(char);
      }
      started = true;
    } else if (char == '"' || char == "'") {
      quote = char;
      started = true;
    } else if (char.trim().isEmpty) {
      if (started) words.add(word.toString());
      word = StringBuffer();
      started = false;
    } else {
      word.write(char);
      started = true;
    }
  }
  if (quote != null) throw const FormatException('Unclosed quote');
  if (started) words.add(word.toString());
  return words;
}
