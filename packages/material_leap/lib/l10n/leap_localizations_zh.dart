// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'leap_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class LeapLocalizationsZh extends LeapLocalizations {
  LeapLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get color => '颜色';

  @override
  String get red => '红色的';

  @override
  String get green => '绿色';

  @override
  String get blue => '蓝色';

  @override
  String get minimize => '最小化';

  @override
  String get maximize => '最大化';

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

  @override
  String get reset => '重置';

  @override
  String get shouldNotEmpty => '此值不应为空';

  @override
  String get alreadyExists => '此元素已存在';

  @override
  String get create => '创建';

  @override
  String get enterName => '请输入一个名称';

  @override
  String get name => '名称';

  @override
  String get invalidName => '无效的名称';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class LeapLocalizationsZhHant extends LeapLocalizationsZh {
  LeapLocalizationsZhHant() : super('zh_Hant');

  @override
  String get color => '顏色';

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
  String get exitAlwaysOnTop => '退出置頂';

  @override
  String get alwaysOnTop => '置頂';

  @override
  String get exitFullScreen => '退出全螢幕';

  @override
  String get fullScreen => '全螢幕';

  @override
  String get restore => '恢復';

  @override
  String get copyMessage => '已複製到剪貼簿';

  @override
  String get reset => '重設';

  @override
  String get shouldNotEmpty => '此欄位必填';

  @override
  String get alreadyExists => '此元素已存在';

  @override
  String get create => '建立';

  @override
  String get enterName => '請輸入名稱';

  @override
  String get name => '名稱';

  @override
  String get invalidName => '名稱無效';
}
