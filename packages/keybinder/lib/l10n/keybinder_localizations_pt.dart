// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'keybinder_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class KeybinderLocalizationsPt extends KeybinderLocalizations {
  KeybinderLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get clickToSet => 'Clique para definir';

  @override
  String get pressAnyKey => 'Pressione qualquer tecla...';

  @override
  String get controlKey => 'Ctrl';

  @override
  String get shiftKey => 'Shift';

  @override
  String get altKey => 'Alt';

  @override
  String get metaKey => 'Meta';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class KeybinderLocalizationsPtBr extends KeybinderLocalizationsPt {
  KeybinderLocalizationsPtBr() : super('pt_BR');

  @override
  String get clickToSet => 'Clique para definir';

  @override
  String get pressAnyKey => 'Pressione qualquer tecla...';

  @override
  String get controlKey => 'Ctrl';

  @override
  String get shiftKey => 'Shift';

  @override
  String get altKey => 'Alt';

  @override
  String get metaKey => 'Meta';
}
