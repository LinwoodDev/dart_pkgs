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

  @override
  String get minimize => 'Minimize';

  @override
  String get maximize => 'Maximize';

  @override
  String get close => '关闭';

  @override
  String get exitAlwaysOnTop => '总是在顶部退出';

  @override
  String get alwaysOnTop => '总是在顶端';

  @override
  String get exitFullScreen => '退出全屏';

  @override
  String get fullScreen => '全屏';

  @override
  String get restore => '恢复';

  @override
  String get copyMessage => '复制到剪贴板';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class LeapLocalizationsZhHant extends LeapLocalizationsZh {
  LeapLocalizationsZhHant() : super('zh_Hant');

  @override
  String get color => '顏色';

  @override
  String get pin => '釘選';

  @override
  String get delete => '刪除';

  @override
  String get red => '紅';

  @override
  String get green => '綠';

  @override
  String get blue => '藍';

  @override
  String get minimize => '最小化';

  @override
  String get maximize => '最大化';

  @override
  String get close => '關閉';

  @override
  String get exitAlwaysOnTop => 'Exit Always On Top';

  @override
  String get alwaysOnTop => 'Always On Top';

  @override
  String get exitFullScreen => 'Exit Full Screen';

  @override
  String get fullScreen => 'Full Screen';

  @override
  String get restore => '恢復';

  @override
  String get copyMessage => '已複製到剪貼簿';
}
