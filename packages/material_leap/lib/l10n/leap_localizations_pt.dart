import 'leap_localizations.dart';

// ignore_for_file: type=lint

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
  String get close => 'FECHAR';

  @override
  String get exitAlwaysOnTop => 'Sair Sempre no Topo';

  @override
  String get alwaysOnTop => 'Sempre no Topo';

  @override
  String get exitFullScreen => 'Sair de Tela Cheia';

  @override
  String get fullScreen => 'Tela Cheia';

  @override
  String get restore => 'RESTAURAR';

  @override
  String get copyMessage => 'Copiado para o clipboard';

  @override
  String get reset => 'Reset';

  @override
  String get shouldNotEmpty => 'This value should not be empty';

  @override
  String get alreadyExists => 'This element already exists';

  @override
  String get create => 'Create';

  @override
  String get enterName => 'Please enter a name';

  @override
  String get name => 'Name';

  @override
  String get invalidName => 'Invalid name';
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

  @override
  String get minimize => 'Minimize';

  @override
  String get maximize => 'Maximize';

  @override
  String get close => 'Fechar';

  @override
  String get exitAlwaysOnTop => 'Sair Sempre no Topo';

  @override
  String get alwaysOnTop => 'Sempre no Topo';

  @override
  String get exitFullScreen => 'Sair de Tela Cheia';

  @override
  String get fullScreen => 'Tela Cheia';

  @override
  String get restore => 'Restaurar';

  @override
  String get copyMessage => 'Copiado para área de transferência';

  @override
  String get reset => 'Reset';
}
