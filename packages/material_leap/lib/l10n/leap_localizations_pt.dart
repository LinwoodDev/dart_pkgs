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
  String get more => 'More';
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
