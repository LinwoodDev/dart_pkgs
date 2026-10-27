import 'package:consoler/consoler.dart';
import 'package:test/test.dart';

final class _TerminalOutput extends ConsoleOutput {
  final bool ansi;
  final bool terminal;
  _TerminalOutput({this.ansi = true, this.terminal = true});
  @override
  bool get interactive => terminal;
  @override
  bool get supportsAnsi => ansi;
  @override
  void write(String value) {}
}

void main() {
  test('bound helpers emit no ANSI into pipes or buffers', () async {
    final output = BufferConsoleOutput();
    final console = Consoler(output: output);
    addTearDown(console.dispose);
    console.print(console.colors.green('Ready'));
    console.command(
      'color',
      run: (context) {
        context.write(
          context.colors.paint(
            'Plain',
            foreground: ConsoleColor.red,
            background: ConsoleColor.blue,
            bold: true,
          ),
        );
      },
    );
    await console.execute('color');
    expect(output.toString(), 'Ready\nPlain\n');
    expect(output.toString(), isNot(contains('\x1B')));
  });

  test(
    'ANSI support alone does not enable colors for redirected output',
    () async {
      final pipe = Consoler(output: _TerminalOutput(terminal: false));
      final dumb = Consoler(output: _TerminalOutput(ansi: false));
      addTearDown(pipe.dispose);
      addTearDown(dumb.dispose);
      expect(pipe.colors.red('Alert'), 'Alert');
      expect(dumb.colors.red('Alert'), 'Alert');
    },
  );

  test('foreground, background and styles can be combined', () async {
    final console = Consoler(output: _TerminalOutput());
    addTearDown(console.dispose);
    expect(
      console.colors.paint(
        'Ready',
        foreground: ConsoleColor.brightGreen,
        background: ConsoleColor.blue,
        bold: true,
        underline: true,
      ),
      '\x1B[1;4;92;44mReady\x1B[0m',
    );
    expect(ConsoleColor.defaultColor.backgroundCode, 49);
  });

  test('nested helpers restore the outer style after an inner reset', () {
    const colors = ConsoleColors(enabled: true);
    final value = colors.red('before ${colors.bold('inside')} after');
    expect(value, contains('\x1B[0m\x1B[31m after'));
    expect(value, endsWith('\x1B[0m'));
  });

  test('multiline styles close before each following log prefix', () {
    const colors = ConsoleColors(enabled: true);
    expect(colors.green('one\ntwo'), '\x1B[32mone\x1B[0m\n\x1B[32mtwo\x1B[0m');
  });
}
