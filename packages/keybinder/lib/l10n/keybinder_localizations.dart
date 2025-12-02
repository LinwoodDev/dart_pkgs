import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'keybinder_localizations_af.dart';
import 'keybinder_localizations_ar.dart';
import 'keybinder_localizations_ca.dart';
import 'keybinder_localizations_cs.dart';
import 'keybinder_localizations_da.dart';
import 'keybinder_localizations_de.dart';
import 'keybinder_localizations_el.dart';
import 'keybinder_localizations_en.dart';
import 'keybinder_localizations_es.dart';
import 'keybinder_localizations_fi.dart';
import 'keybinder_localizations_fr.dart';
import 'keybinder_localizations_he.dart';
import 'keybinder_localizations_hu.dart';
import 'keybinder_localizations_it.dart';
import 'keybinder_localizations_ja.dart';
import 'keybinder_localizations_ko.dart';
import 'keybinder_localizations_nl.dart';
import 'keybinder_localizations_no.dart';
import 'keybinder_localizations_pl.dart';
import 'keybinder_localizations_pt.dart';
import 'keybinder_localizations_ro.dart';
import 'keybinder_localizations_ru.dart';
import 'keybinder_localizations_sr.dart';
import 'keybinder_localizations_sv.dart';
import 'keybinder_localizations_tr.dart';
import 'keybinder_localizations_uk.dart';
import 'keybinder_localizations_vi.dart';
import 'keybinder_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of KeybinderLocalizations
/// returned by `KeybinderLocalizations.of(context)`.
///
/// Applications need to include `KeybinderLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/keybinder_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: KeybinderLocalizations.localizationsDelegates,
///   supportedLocales: KeybinderLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the KeybinderLocalizations.supportedLocales
/// property.
abstract class KeybinderLocalizations {
  KeybinderLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static KeybinderLocalizations of(BuildContext context) {
    return Localizations.of<KeybinderLocalizations>(
      context,
      KeybinderLocalizations,
    )!;
  }

  static const LocalizationsDelegate<KeybinderLocalizations> delegate =
      _KeybinderLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('af'),
    Locale('ar'),
    Locale('ca'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('he'),
    Locale('hu'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('no'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ro'),
    Locale('ru'),
    Locale('sr'),
    Locale('sv'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('zh'),
  ];

  /// No description provided for @clickToSet.
  ///
  /// In en, this message translates to:
  /// **'Click to set'**
  String get clickToSet;

  /// No description provided for @pressAnyKey.
  ///
  /// In en, this message translates to:
  /// **'Press any key...'**
  String get pressAnyKey;

  /// No description provided for @controlKey.
  ///
  /// In en, this message translates to:
  /// **'Ctrl'**
  String get controlKey;

  /// No description provided for @shiftKey.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shiftKey;

  /// No description provided for @altKey.
  ///
  /// In en, this message translates to:
  /// **'Alt'**
  String get altKey;

  /// No description provided for @metaKey.
  ///
  /// In en, this message translates to:
  /// **'Meta'**
  String get metaKey;
}

class _KeybinderLocalizationsDelegate
    extends LocalizationsDelegate<KeybinderLocalizations> {
  const _KeybinderLocalizationsDelegate();

  @override
  Future<KeybinderLocalizations> load(Locale locale) {
    return SynchronousFuture<KeybinderLocalizations>(
      lookupKeybinderLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'af',
    'ar',
    'ca',
    'cs',
    'da',
    'de',
    'el',
    'en',
    'es',
    'fi',
    'fr',
    'he',
    'hu',
    'it',
    'ja',
    'ko',
    'nl',
    'no',
    'pl',
    'pt',
    'ro',
    'ru',
    'sr',
    'sv',
    'tr',
    'uk',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_KeybinderLocalizationsDelegate old) => false;
}

KeybinderLocalizations lookupKeybinderLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return KeybinderLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return KeybinderLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af':
      return KeybinderLocalizationsAf();
    case 'ar':
      return KeybinderLocalizationsAr();
    case 'ca':
      return KeybinderLocalizationsCa();
    case 'cs':
      return KeybinderLocalizationsCs();
    case 'da':
      return KeybinderLocalizationsDa();
    case 'de':
      return KeybinderLocalizationsDe();
    case 'el':
      return KeybinderLocalizationsEl();
    case 'en':
      return KeybinderLocalizationsEn();
    case 'es':
      return KeybinderLocalizationsEs();
    case 'fi':
      return KeybinderLocalizationsFi();
    case 'fr':
      return KeybinderLocalizationsFr();
    case 'he':
      return KeybinderLocalizationsHe();
    case 'hu':
      return KeybinderLocalizationsHu();
    case 'it':
      return KeybinderLocalizationsIt();
    case 'ja':
      return KeybinderLocalizationsJa();
    case 'ko':
      return KeybinderLocalizationsKo();
    case 'nl':
      return KeybinderLocalizationsNl();
    case 'no':
      return KeybinderLocalizationsNo();
    case 'pl':
      return KeybinderLocalizationsPl();
    case 'pt':
      return KeybinderLocalizationsPt();
    case 'ro':
      return KeybinderLocalizationsRo();
    case 'ru':
      return KeybinderLocalizationsRu();
    case 'sr':
      return KeybinderLocalizationsSr();
    case 'sv':
      return KeybinderLocalizationsSv();
    case 'tr':
      return KeybinderLocalizationsTr();
    case 'uk':
      return KeybinderLocalizationsUk();
    case 'vi':
      return KeybinderLocalizationsVi();
    case 'zh':
      return KeybinderLocalizationsZh();
  }

  throw FlutterError(
    'KeybinderLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
