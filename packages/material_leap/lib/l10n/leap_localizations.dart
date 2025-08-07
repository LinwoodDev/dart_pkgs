import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'leap_localizations_af.dart';
import 'leap_localizations_ar.dart';
import 'leap_localizations_ca.dart';
import 'leap_localizations_cs.dart';
import 'leap_localizations_da.dart';
import 'leap_localizations_de.dart';
import 'leap_localizations_el.dart';
import 'leap_localizations_en.dart';
import 'leap_localizations_es.dart';
import 'leap_localizations_fi.dart';
import 'leap_localizations_fr.dart';
import 'leap_localizations_he.dart';
import 'leap_localizations_hu.dart';
import 'leap_localizations_it.dart';
import 'leap_localizations_ja.dart';
import 'leap_localizations_ko.dart';
import 'leap_localizations_nl.dart';
import 'leap_localizations_no.dart';
import 'leap_localizations_pl.dart';
import 'leap_localizations_pt.dart';
import 'leap_localizations_ro.dart';
import 'leap_localizations_ru.dart';
import 'leap_localizations_sr.dart';
import 'leap_localizations_sv.dart';
import 'leap_localizations_tr.dart';
import 'leap_localizations_uk.dart';
import 'leap_localizations_vi.dart';
import 'leap_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of LeapLocalizations
/// returned by `LeapLocalizations.of(context)`.
///
/// Applications need to include `LeapLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/leap_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: LeapLocalizations.localizationsDelegates,
///   supportedLocales: LeapLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the LeapLocalizations.supportedLocales
/// property.
abstract class LeapLocalizations {
  LeapLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static LeapLocalizations of(BuildContext context) {
    return Localizations.of<LeapLocalizations>(context, LeapLocalizations)!;
  }

  static const LocalizationsDelegate<LeapLocalizations> delegate =
      _LeapLocalizationsDelegate();

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
    Locale('zh')
  ];

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get green;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// No description provided for @minimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimize;

  /// No description provided for @maximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get maximize;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @exitAlwaysOnTop.
  ///
  /// In en, this message translates to:
  /// **'Exit Always On Top'**
  String get exitAlwaysOnTop;

  /// No description provided for @alwaysOnTop.
  ///
  /// In en, this message translates to:
  /// **'Always On Top'**
  String get alwaysOnTop;

  /// No description provided for @exitFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Exit Full Screen'**
  String get exitFullScreen;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full Screen'**
  String get fullScreen;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copyMessage;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @shouldNotEmpty.
  ///
  /// In en, this message translates to:
  /// **'This value should not be empty'**
  String get shouldNotEmpty;

  /// No description provided for @alreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This element already exists'**
  String get alreadyExists;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get enterName;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'Invalid name'**
  String get invalidName;
}

class _LeapLocalizationsDelegate
    extends LocalizationsDelegate<LeapLocalizations> {
  const _LeapLocalizationsDelegate();

  @override
  Future<LeapLocalizations> load(Locale locale) {
    return SynchronousFuture<LeapLocalizations>(
        lookupLeapLocalizations(locale));
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
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_LeapLocalizationsDelegate old) => false;
}

LeapLocalizations lookupLeapLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return LeapLocalizationsZhHant();
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
            return LeapLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af':
      return LeapLocalizationsAf();
    case 'ar':
      return LeapLocalizationsAr();
    case 'ca':
      return LeapLocalizationsCa();
    case 'cs':
      return LeapLocalizationsCs();
    case 'da':
      return LeapLocalizationsDa();
    case 'de':
      return LeapLocalizationsDe();
    case 'el':
      return LeapLocalizationsEl();
    case 'en':
      return LeapLocalizationsEn();
    case 'es':
      return LeapLocalizationsEs();
    case 'fi':
      return LeapLocalizationsFi();
    case 'fr':
      return LeapLocalizationsFr();
    case 'he':
      return LeapLocalizationsHe();
    case 'hu':
      return LeapLocalizationsHu();
    case 'it':
      return LeapLocalizationsIt();
    case 'ja':
      return LeapLocalizationsJa();
    case 'ko':
      return LeapLocalizationsKo();
    case 'nl':
      return LeapLocalizationsNl();
    case 'no':
      return LeapLocalizationsNo();
    case 'pl':
      return LeapLocalizationsPl();
    case 'pt':
      return LeapLocalizationsPt();
    case 'ro':
      return LeapLocalizationsRo();
    case 'ru':
      return LeapLocalizationsRu();
    case 'sr':
      return LeapLocalizationsSr();
    case 'sv':
      return LeapLocalizationsSv();
    case 'tr':
      return LeapLocalizationsTr();
    case 'uk':
      return LeapLocalizationsUk();
    case 'vi':
      return LeapLocalizationsVi();
    case 'zh':
      return LeapLocalizationsZh();
  }

  throw FlutterError(
      'LeapLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
