// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'leap_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class LeapLocalizationsPt extends LeapLocalizations {
  LeapLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get color => 'Cor';

  @override
  String get red => 'Vermelho';

  @override
  String get green => 'Verde';

  @override
  String get blue => 'azul';

  @override
  String get minimize => 'Minimizar';

  @override
  String get maximize => 'Maximizar';

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
  String get reset => 'Redefinir';

  @override
  String get shouldNotEmpty => 'Este valor não deve ser vazio';

  @override
  String get alreadyExists => 'Este elemento já existe';

  @override
  String get create => 'Criar';

  @override
  String get enterName => 'Por favor, digite um nome';

  @override
  String get name => 'Nome';

  @override
  String get invalidName => 'Nome inválido';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class LeapLocalizationsPtBr extends LeapLocalizationsPt {
  LeapLocalizationsPtBr() : super('pt_BR');

  @override
  String get color => 'Cor';

  @override
  String get red => 'Vermelho';

  @override
  String get green => 'Verde';

  @override
  String get blue => 'azul';

  @override
  String get minimize => 'Minimizar';

  @override
  String get maximize => 'Maximizar';

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
  String get reset => 'Redefinir';

  @override
  String get shouldNotEmpty => 'Este valor não deve ser vazio';

  @override
  String get alreadyExists => 'Este elemento já existe';

  @override
  String get create => 'Criar';

  @override
  String get enterName => 'Por favor, digite um nome';

  @override
  String get name => 'Nome';

  @override
  String get invalidName => 'Nome inválido';
}
