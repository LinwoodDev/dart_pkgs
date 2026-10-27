import 'package:consoler/consoler.dart';
import 'package:test/test.dart';

void main() {
  test('metadata callbacks are evaluated when rendering help', () async {
    var description = 'First description';
    var category = 'First category';
    final output = BufferConsoleOutput();
    final console = Consoler(output: output);
    addTearDown(console.dispose);
    console.command(
      'echo',
      descriptionBuilder: () => description,
      categoryBuilder: () => category,
      usageBuilder: () => '<message>',
      run: (_) {},
    );
    await console.execute('help');
    expect(output.toString(), contains(description));
    expect(output.toString(), contains(category));
    description = 'Updated description';
    category = 'Updated category';
    output.clear();
    await console.execute('help');
    expect(output.toString(), contains(description));
    expect(output.toString(), contains(category));
    output.clear();
    await console.execute('help echo');
    expect(output.toString(), contains('echo <message>'));
  });

  test(
    'all built-in text can be supplied as plain values and callbacks',
    () async {
      final output = BufferConsoleOutput();
      final console = Consoler(
        output: output,
        messages: ConsoleMessages(
          helpDescription: 'Custom help',
          helpUsage: '[custom-command]',
          subcommandUsage: '<custom-child>',
          helpHint: 'Custom hint',
          generalCategory: 'Custom group',
          unclosedQuote: 'Custom quote error',
          commandsTitle: 'Custom commands',
          optionsTitle: 'Custom options',
          examplesTitle: 'Custom examples',
          usage: (value) => 'Custom usage: $value',
          aliases: (values) => 'Custom aliases: ${values.join('/')}',
          unknownCommand: (name) => 'Custom unknown: $name',
          suggestion: (names) => 'Custom suggestion: ${names.join('/')}',
          commandFailed: (name, error) => 'Custom failure: $name',
          invalidArguments: (error) => 'Custom arguments: $error',
        ),
      );
      addTearDown(console.dispose);
      await console.execute('help');
      expect(output.toString(), contains('Custom help'));
      expect(output.toString(), contains('Custom hint'));
      expect(output.toString(), contains('Custom group'));
      output.clear();
      await console.execute('help help');
      expect(
        output.toString(),
        contains('Custom usage: help [custom-command]'),
      );
      expect(output.toString(), contains('Custom aliases: ?'));
      output.clear();
      console.addCommand(
        ConsoleCommand(
          name: 'group',
          subcommands: [ConsoleCommand(name: 'child')],
        ),
      );
      await console.execute('help group');
      expect(output.toString(), contains('<custom-child>'));
      expect(output.toString(), contains('Custom commands'));
      output.clear();
      console.command(
        'demo',
        parser: ArgParser()..addFlag('flag'),
        examples: ['demo'],
        run: (_) {
          throw StateError('failure');
        },
      );
      await console.execute('help demo');
      expect(output.toString(), contains('Custom options'));
      expect(output.toString(), contains('Custom examples'));
      output.clear();
      await console.execute('demo --unknown');
      expect(output.toString(), contains('Custom arguments'));
      output.clear();
      await console.execute('demo');
      expect(output.toString(), contains('Custom failure: demo'));
      output.clear();
      await console.execute('dem');
      expect(output.toString(), contains('Custom unknown: dem'));
      expect(output.toString(), contains('Custom suggestion: demo'));
      output.clear();
      await console.execute('demo "');
      expect(output.toString(), contains('Custom quote error'));
    },
  );

  test(
    'replacing messages at runtime updates the built-in help command',
    () async {
      final output = BufferConsoleOutput();
      final console = Consoler(output: output);
      addTearDown(console.dispose);
      await console.execute('help');
      expect(output.toString(), contains('Show commands'));
      console.messages = const ConsoleMessages(
        helpDescription: 'Replacement help',
        helpUsage: '[replacement]',
      );
      output.clear();
      await console.execute('help');
      expect(output.toString(), contains('Replacement help'));
      output.clear();
      await console.execute('help help');
      expect(output.toString(), contains('help [replacement]'));
    },
  );

  test('pipe tables retain complete identifiers', () async {
    final output = BufferConsoleOutput();
    final console = Consoler(output: output);
    addTearDown(console.dispose);
    final fingerprint = 'abcdef' * 30;
    console.table(
      ['User', 'Fingerprint'],
      [
        ['Ada', fingerprint],
      ],
    );
    expect(output.toString(), contains(fingerprint));
  });
}
