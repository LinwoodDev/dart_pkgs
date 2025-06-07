import 'package:localizer/localizer.dart';
import 'package:sprintf/sprintf.dart';
import 'package:meta/meta.dart';

@immutable
class LocalizerLocale {
  /// The identifier of this object in [Localizer].
  final String name;
  final Map<String, String> _messages;

  /// Creates a new instance of [LocalizerLocale].
  /// [name] is the identifier of this object in [Localizer].
  /// [messages] is the map of messages.
  /// [messages] are the messages of this locale.
  ///
  /// Please use the methods in [Localizer].
  LocalizerLocale(this.name, [Map<String, String> messages = const {}])
    : _messages = messages;

  /// Returns the message of the key or the key if the message is not found.
  /// [key] is the key of the message.
  /// [args] are the arguments of the message. This method uses sprintf to format the message.
  ///
  String get(String key, [List args = const []]) =>
      getOrDefault(key, key, args);

  /// Returns the message of the key or the default value if the message is not found.
  /// [key] is the key of the message.
  /// [defaultValue] is the default value if the message is not found.
  /// [args] are the arguments of the message. This method uses sprintf to format the message.
  String getOrDefault(String key, String defaultValue, [List args = const []]) {
    var message = _messages[key];
    if (message == null) {
      return defaultValue;
    }
    return sprintf(message, args);
  }

  /// Test if a message with the key exists.
  bool contains(String key) => _messages.containsKey(key);

  /// Returns all keys of the messages.
  Iterable<String> get keys => _messages.keys;
}
