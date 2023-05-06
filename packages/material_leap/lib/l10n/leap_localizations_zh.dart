import 'leap_localizations.dart';

/// The translations for Chinese (`zh`).
class LeapLocalizationsZh extends LeapLocalizations {
  LeapLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get color => '颜色';

  @override
  String get pin => '置顶';

  @override
  String get delete => '删除';

  @override
  String get red => '红色的';

  @override
  String get green => 'Green';

  @override
  String get blue => '蓝色';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class LeapLocalizationsZhHant extends LeapLocalizationsZh {
  LeapLocalizationsZhHant() : super('zh_Hant');

  @override
  String get color => 'Color';

  @override
  String get pin => 'Pin';

  @override
  String get delete => '刪除';

  @override
  String get red => 'Red';

  @override
  String get green => 'Green';

  @override
  String get blue => 'Blue';
}
