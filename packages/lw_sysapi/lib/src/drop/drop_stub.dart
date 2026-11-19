import 'drop_models.dart';

Stream<SystemDropEvent> createDropEvents() => const Stream.empty();

void Function() listenForBrowserPaste({
  required Iterable<String> types,
  required bool Function() canPaste,
  required void Function(Future<List<SystemDropItem>>) onPaste,
}) => () {};
