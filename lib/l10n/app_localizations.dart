import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('el'),
    Locale('en'),
    Locale('hu'),
    Locale('pl'),
  ];

  /// Scan button tool tip
  ///
  /// In en, this message translates to:
  /// **'Scan Options'**
  String get scan_options;

  /// Scan-type 1
  ///
  /// In en, this message translates to:
  /// **'Normal Scan'**
  String get normal_scan;

  /// Scan-type 2
  ///
  /// In en, this message translates to:
  /// **'Quick Scan'**
  String get quick_scan;

  /// Scan-type 3
  ///
  /// In en, this message translates to:
  /// **'Import from Gallery'**
  String get import_from_gallery;

  /// Scan-type 4
  ///
  /// In en, this message translates to:
  /// **'Live Scan'**
  String get live_scan;

  /// Refresh tool tip
  ///
  /// In en, this message translates to:
  /// **'Drag down to refresh'**
  String get refresh;

  /// File last updated
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get last_updated;

  /// Multiple Images
  ///
  /// In en, this message translates to:
  /// **'images'**
  String get images;

  /// Short app description on About-Screen
  ///
  /// In en, this message translates to:
  /// **'is an open-source app which enables users to scan hard copies of documents and convert it into a PDF file.'**
  String get app_description;

  /// Moto on About-Screen
  ///
  /// In en, this message translates to:
  /// **'No ads. We don\'t collect any data.\n We respect your privacy.'**
  String get app_description_2;

  /// Crop-Screen header
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// Rotate image right
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get rotate_right;

  /// Rotate image left
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get rotate_left;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'image'**
  String get image;

  /// No description provided for @developers.
  ///
  /// In en, this message translates to:
  /// **'Developers'**
  String get developers;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @tutorial_title.
  ///
  /// In en, this message translates to:
  /// **'How to use the app?'**
  String get tutorial_title;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @demo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demo;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @save_to_device.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get save_to_device;

  /// No description provided for @share_pdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get share_pdf;

  /// No description provided for @share_images.
  ///
  /// In en, this message translates to:
  /// **'Share images'**
  String get share_images;

  /// Filter picker screen title
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Colour mode: the capture, unchanged
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get filter_original;

  /// Colour mode: automatic colour and contrast correction
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get filter_auto;

  /// Colour mode: keeps colour, whitens the paper
  ///
  /// In en, this message translates to:
  /// **'Lighten'**
  String get filter_lighten;

  /// Colour mode: shades of grey only
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get filter_grayscale;

  /// Colour mode: pure black and white
  ///
  /// In en, this message translates to:
  /// **'B&W'**
  String get filter_bw;

  /// Colour mode: removes shadows and glare from a whiteboard
  ///
  /// In en, this message translates to:
  /// **'Whiteboard'**
  String get filter_whiteboard;

  /// Applies the selected filter to every page of the document
  ///
  /// In en, this message translates to:
  /// **'Apply to all pages'**
  String get apply_to_all_pages;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['el', 'en', 'hu', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
