// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'keybinder_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class KeybinderLocalizationsZh extends KeybinderLocalizations {
  KeybinderLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get clickToSet => '点击设置';

  @override
  String get pressAnyKey => '按下任意键...';

  @override
  String get controlKey => 'Ctrl';

  @override
  String get shiftKey => 'Shift';

  @override
  String get altKey => 'Alt';

  @override
  String get metaKey => 'Meta';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class KeybinderLocalizationsZhHant extends KeybinderLocalizationsZh {
  KeybinderLocalizationsZhHant() : super('zh_Hant');

  @override
  String get clickToSet => '點擊設定';

  @override
  String get pressAnyKey => '按下任意鍵...';

  @override
  String get controlKey => 'Ctrl';

  @override
  String get shiftKey => 'Shift';

  @override
  String get altKey => 'Alt';

  @override
  String get metaKey => 'Meta';
}
