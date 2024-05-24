import 'leap_localizations.dart';

/// The translations for Portuguese (`pt`).
class LeapLocalizationsPt extends LeapLocalizations {
  LeapLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get color => 'Cor';

  @override
  String get pin => 'PIN';

  @override
  String get delete => 'excluir';

  @override
  String get red => 'Vermelho';

  @override
  String get green => 'Verde';

  @override
  String get blue => 'azul';

  @override
  String get minimize => 'Minimize';

  @override
  String get maximize => 'Maximize';

  @override
  String get close => 'Close';

  @override
  String get exitAlwaysOnTop => 'Exit Always On Top';

  @override
  String get alwaysOnTop => 'Always On Top';

  @override
  String get exitFullScreen => 'Exit Full Screen';

  @override
  String get fullScreen => 'Full Screen';

  @override
  String get restore => 'Restore';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class LeapLocalizationsPtBr extends LeapLocalizationsPt {
  LeapLocalizationsPtBr() : super('pt_BR');

  @override
  String get color => 'Cor';

  @override
  String get pin => 'PIN';

  @override
  String get delete => 'excluir';

  @override
  String get red => 'Vermelho';

  @override
  String get green => 'Verde';

  @override
  String get blue => 'azul';
}
