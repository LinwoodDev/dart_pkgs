import 'package:app_tools/set_version.dart';
import 'package:args/command_runner.dart';

Future<void> main(List<String> args) async {
  CommandRunner('app_tools',
      'AppTools is a collection of tools for simplifying the development of apps in Flutter.')
    ..addCommand(SetVersionCommand())
    ..run(args);
}
