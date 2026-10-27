import 'output.dart';

/// Stateful single-line editor; input can be fed in arbitrary stream chunks.
/// Keeps a bounded, in-memory history. No command history is written to disk.
final class ConsoleLineEditor {
  final ConsoleOutput output;
  final String prefix;
  final List<String> history;
  final int historyLimit;
  final List<String> Function(String line) complete;
  final void Function(String line) onLine;
  final void Function() onClose;
  final List<int> _buffer = [];
  int _cursor = 0;
  int? _historyIndex;
  String _draft = '';
  String _escape = '';
  bool _lastWasCr = false;

  ConsoleLineEditor({
    required this.output,
    required this.prefix,
    required this.history,
    required this.historyLimit,
    required this.complete,
    required this.onLine,
    required this.onClose,
  });
  String get line => String.fromCharCodes(_buffer);

  void _set(String value) {
    _buffer
      ..clear()
      ..addAll(value.runes);
    _cursor = _buffer.length;
  }

  void add(String chunk) {
    for (final rune in chunk.runes) {
      if (_escape.isNotEmpty) {
        _escape += String.fromCharCode(rune);
        if (_escape == '\x1B[' || _escape == '\x1BO') continue;
        if (_escape.length > 2 && rune >= 0x40 && rune <= 0x7e) {
          _key(_escape.substring(1));
          _escape = '';
        } else if (_escape.length > 16 ||
            (_escape.length == 2 && rune != 0x5b && rune != 0x4f)) {
          _escape = '';
        }
        continue;
      }
      if (rune == 27) {
        _escape = '\x1B';
        continue;
      }
      if (rune == 10 && _lastWasCr) {
        _lastWasCr = false;
        continue;
      }
      _lastWasCr = rune == 13;
      switch (rune) {
        case 10 || 13:
          final value = line;
          output.write('\r\x1B[2K$prefix$value\n');
          if (value.trim().isNotEmpty &&
              historyLimit > 0 &&
              history.lastOrNull != value) {
            history.add(value);
            if (history.length > historyLimit) history.removeAt(0);
          }
          _set('');
          _historyIndex = null;
          _draft = '';
          onLine(value);
        case 127 || 8:
          if (_cursor > 0) _buffer.removeAt(--_cursor);
        case 1:
          _cursor = 0;
        case 5:
          _cursor = _buffer.length;
        case 21:
          _set('');
        case 3:
          _set('');
          output.write('^C\n');
          _historyIndex = null;
        case 4:
          if (_buffer.isEmpty) {
            onClose();
            return;
          }
          if (_cursor < _buffer.length) _buffer.removeAt(_cursor);
        case 9:
          _complete();
        default:
          if (rune >= 32) _buffer.insert(_cursor++, rune);
      }
    }
    redraw();
  }

  void _key(String key) {
    switch (key) {
      case '[A':
        if (history.isEmpty) return;
        if (_historyIndex == null) _draft = line;
        final index = ((_historyIndex ?? history.length) - 1).clamp(
          0,
          history.length - 1,
        );
        _historyIndex = index;
        _set(history[index]);
      case '[B':
        if (_historyIndex == null) return;
        final index = _historyIndex! + 1;
        if (index >= history.length) {
          _historyIndex = null;
          _set(_draft);
        } else {
          _historyIndex = index;
          _set(history[index]);
        }
      case '[C':
        if (_cursor < _buffer.length) _cursor++;
      case '[D':
        if (_cursor > 0) _cursor--;
      case '[H' || 'OH' || '[1~':
        _cursor = 0;
      case '[F' || 'OF' || '[4~':
        _cursor = _buffer.length;
      case '[3~':
        if (_cursor < _buffer.length) _buffer.removeAt(_cursor);
    }
  }

  void _complete() {
    final before = String.fromCharCodes(_buffer.take(_cursor));
    final options = complete(before);
    if (options.isEmpty) return;
    final textStart = before.lastIndexOf(RegExp(r'\s')) + 1;
    final start = before.substring(0, textStart).runes.length;
    var common = options.first;
    for (final option in options.skip(1)) {
      while (!option.startsWith(common)) {
        common = common.substring(0, common.length - 1);
      }
    }
    if (common.length >= before.runes.length - start) {
      final replacement = common + (options.length == 1 ? ' ' : '');
      final tail = _buffer.skip(_cursor).toList();
      _buffer
        ..removeRange(start, _buffer.length)
        ..addAll(replacement.runes)
        ..addAll(tail);
      _cursor = start + replacement.runes.length;
    }
    if (options.length > 1) log(options.join('  '));
  }

  void log(String message) {
    output.write('\r\x1B[2K$message\n');
    redraw();
  }

  void redraw() {
    final available = (output.columns - prefix.runes.length - 1).clamp(
      1,
      10000,
    );
    final offset = _cursor >= available ? _cursor - available + 1 : 0;
    final visible = String.fromCharCodes(_buffer.skip(offset).take(available));
    final cursor = _cursor - offset;
    output.write('\r\x1B[2K$prefix$visible\r');
    final column = prefix.runes.length + cursor;
    if (column > 0) output.write('\x1B[${column}C');
  }
}
