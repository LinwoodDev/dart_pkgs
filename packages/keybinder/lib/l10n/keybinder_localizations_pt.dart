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

  @override
  String get reset => 'Redefinir';

  @override
  String get spaceKey => 'Space';

  @override
  String get mediaTrackPreviousKey => 'Media Previous';

  @override
  String get mediaTrackNextKey => 'Media Next';
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
  String get shiftKey => 'Turno';

  @override
  String get altKey => 'Alt';

  @override
  String get metaKey => 'Meta';

  @override
  String get reset => 'Redefinir';
}
