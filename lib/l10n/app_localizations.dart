import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ta.dart';

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
    Locale('hi'),
    Locale('hu'),
    Locale('pl'),
    Locale('ta'),
  ];

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

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

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @select_all.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get select_all;

  /// No description provided for @select_pages.
  ///
  /// In en, this message translates to:
  /// **'Select pages'**
  String get select_pages;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get try_again;

  /// Snackbar undo action, shown in caps
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get undo;

  /// No description provided for @not_now.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get not_now;

  /// No description provided for @open_settings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get open_settings;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'image'**
  String get image;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'images'**
  String get images;

  /// No description provided for @developers.
  ///
  /// In en, this message translates to:
  /// **'Developers'**
  String get developers;

  /// No description provided for @view_on_linkedin.
  ///
  /// In en, this message translates to:
  /// **'View on LinkedIn'**
  String get view_on_linkedin;

  /// No description provided for @tutorial_title.
  ///
  /// In en, this message translates to:
  /// **'How to use the app?'**
  String get tutorial_title;

  /// No description provided for @cant_be_undone.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get cant_be_undone;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @rotate_left.
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get rotate_left;

  /// No description provided for @rotate_right.
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get rotate_right;

  /// Page count for a document
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String pages_count(int count);

  /// Scan button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scan Options'**
  String get scan_options;

  /// No description provided for @live_scan.
  ///
  /// In en, this message translates to:
  /// **'Live Scan'**
  String get live_scan;

  /// No description provided for @import_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Import from Gallery'**
  String get import_from_gallery;

  /// Toolbar tooltip and menu row
  ///
  /// In en, this message translates to:
  /// **'Import from gallery'**
  String get import_from_gallery_short;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Drag down to refresh'**
  String get refresh;

  /// No description provided for @last_updated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get last_updated;

  /// No description provided for @sort_order.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get sort_order;

  /// No description provided for @search_documents.
  ///
  /// In en, this message translates to:
  /// **'Search documents'**
  String get search_documents;

  /// No description provided for @no_documents_yet.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get no_documents_yet;

  /// No description provided for @no_documents_body.
  ///
  /// In en, this message translates to:
  /// **'Scan your first page — it takes about two seconds and stays only on this device.'**
  String get no_documents_body;

  /// No description provided for @start_scanning.
  ///
  /// In en, this message translates to:
  /// **'Start scanning'**
  String get start_scanning;

  /// No description provided for @no_results_for.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String no_results_for(String query);

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get refreshing;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get exporting;

  /// No description provided for @n_selected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String n_selected(int count);

  /// No description provided for @delete_document_q.
  ///
  /// In en, this message translates to:
  /// **'Delete document?'**
  String get delete_document_q;

  /// No description provided for @delete_n_documents_q.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} documents?'**
  String delete_n_documents_q(int count);

  /// No description provided for @document_deleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted'**
  String get document_deleted;

  /// No description provided for @n_documents_deleted.
  ///
  /// In en, this message translates to:
  /// **'{count} documents deleted'**
  String n_documents_deleted(int count);

  /// No description provided for @saved_n_to_device.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} to device'**
  String saved_n_to_device(int count);

  /// No description provided for @couldnt_export_n.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export {count}'**
  String couldnt_export_n(int count);

  /// Library card subtitle: a short date and a page count
  ///
  /// In en, this message translates to:
  /// **'{date} · {pages}'**
  String date_and_pages(String date, String pages);

  /// No description provided for @sort_last_modified.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get sort_last_modified;

  /// No description provided for @sort_date_created.
  ///
  /// In en, this message translates to:
  /// **'Date created'**
  String get sort_date_created;

  /// No description provided for @sort_name.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get sort_name;

  /// No description provided for @sort_page_count.
  ///
  /// In en, this message translates to:
  /// **'Page count'**
  String get sort_page_count;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get scanning;

  /// No description provided for @auto_capture.
  ///
  /// In en, this message translates to:
  /// **'Auto-capture'**
  String get auto_capture;

  /// No description provided for @auto_capture_desc.
  ///
  /// In en, this message translates to:
  /// **'Take the shot as soon as the page holds still.'**
  String get auto_capture_desc;

  /// No description provided for @capture_sound.
  ///
  /// In en, this message translates to:
  /// **'Capture sound'**
  String get capture_sound;

  /// No description provided for @keep_original.
  ///
  /// In en, this message translates to:
  /// **'Keep original image'**
  String get keep_original;

  /// No description provided for @keep_original_desc.
  ///
  /// In en, this message translates to:
  /// **'Keeps the uncropped photo so a page can be re-cropped from the full capture. Roughly doubles the space a document uses.'**
  String get keep_original_desc;

  /// No description provided for @avoid_gesture_strip.
  ///
  /// In en, this message translates to:
  /// **'Avoid back-gesture strip'**
  String get avoid_gesture_strip;

  /// No description provided for @avoid_gesture_strip_desc.
  ///
  /// In en, this message translates to:
  /// **'Keeps the crop corners out of the edge of the screen, where a drag can trigger the system back gesture instead. Makes the page slightly narrower.'**
  String get avoid_gesture_strip_desc;

  /// No description provided for @default_filter.
  ///
  /// In en, this message translates to:
  /// **'Default filter'**
  String get default_filter;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @accent_color.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accent_color;

  /// No description provided for @privacy_storage.
  ///
  /// In en, this message translates to:
  /// **'Privacy & storage'**
  String get privacy_storage;

  /// No description provided for @privacy_body.
  ///
  /// In en, this message translates to:
  /// **'OpenScan never sends your documents anywhere. No accounts, no cloud, no telemetry.'**
  String get privacy_body;

  /// No description provided for @cache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cache;

  /// No description provided for @clear_cache_q.
  ///
  /// In en, this message translates to:
  /// **'Clear cache?'**
  String get clear_cache_q;

  /// No description provided for @clear_cache_body.
  ///
  /// In en, this message translates to:
  /// **'Frees {size} of thumbnail data. Your documents are not affected.'**
  String clear_cache_body(String size);

  /// No description provided for @cache_clear_action.
  ///
  /// In en, this message translates to:
  /// **'{size} · Clear'**
  String cache_clear_action(String size);

  /// No description provided for @cache_cleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cache_cleared;

  /// No description provided for @couldnt_clear_cache.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clear the cache'**
  String get couldnt_clear_cache;

  /// No description provided for @theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get theme_system;

  /// No description provided for @theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filter_original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get filter_original;

  /// No description provided for @filter_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get filter_auto;

  /// No description provided for @filter_lighten.
  ///
  /// In en, this message translates to:
  /// **'Lighten'**
  String get filter_lighten;

  /// No description provided for @filter_grayscale.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get filter_grayscale;

  /// No description provided for @filter_bw.
  ///
  /// In en, this message translates to:
  /// **'B&W'**
  String get filter_bw;

  /// No description provided for @filter_whiteboard.
  ///
  /// In en, this message translates to:
  /// **'Whiteboard'**
  String get filter_whiteboard;

  /// Preview toolbar button that opens the filter picker
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter_action;

  /// No description provided for @apply_to_all_pages.
  ///
  /// In en, this message translates to:
  /// **'Apply to all pages'**
  String get apply_to_all_pages;

  /// No description provided for @apply_to_all_n_pages.
  ///
  /// In en, this message translates to:
  /// **'Apply to all {count} pages'**
  String apply_to_all_n_pages(int count);

  /// No description provided for @adjust_edges.
  ///
  /// In en, this message translates to:
  /// **'Adjust edges'**
  String get adjust_edges;

  /// No description provided for @automatic_crop.
  ///
  /// In en, this message translates to:
  /// **'Automatic crop'**
  String get automatic_crop;

  /// No description provided for @no_crop.
  ///
  /// In en, this message translates to:
  /// **'No crop'**
  String get no_crop;

  /// No description provided for @rescan.
  ///
  /// In en, this message translates to:
  /// **'Re-scan'**
  String get rescan;

  /// No description provided for @couldnt_crop.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t crop the image — please try again.'**
  String get couldnt_crop;

  /// No description provided for @looking_for_document.
  ///
  /// In en, this message translates to:
  /// **'Looking for a document…'**
  String get looking_for_document;

  /// No description provided for @document_detected.
  ///
  /// In en, this message translates to:
  /// **'Document detected'**
  String get document_detected;

  /// No description provided for @hold_still.
  ///
  /// In en, this message translates to:
  /// **'HOLD STILL…'**
  String get hold_still;

  /// No description provided for @auto_on.
  ///
  /// In en, this message translates to:
  /// **'AUTO · ON'**
  String get auto_on;

  /// No description provided for @auto_off.
  ///
  /// In en, this message translates to:
  /// **'AUTO · OFF'**
  String get auto_off;

  /// No description provided for @low_light.
  ///
  /// In en, this message translates to:
  /// **'Low light — hold steady or turn on flash'**
  String get low_light;

  /// No description provided for @torch_on.
  ///
  /// In en, this message translates to:
  /// **'Torch on'**
  String get torch_on;

  /// No description provided for @torch_off.
  ///
  /// In en, this message translates to:
  /// **'Torch off'**
  String get torch_off;

  /// No description provided for @torch_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Torch isn\'t available on this device.'**
  String get torch_unavailable;

  /// No description provided for @auto_capture_on.
  ///
  /// In en, this message translates to:
  /// **'Auto-capture on'**
  String get auto_capture_on;

  /// No description provided for @auto_capture_off.
  ///
  /// In en, this message translates to:
  /// **'Auto-capture off'**
  String get auto_capture_off;

  /// No description provided for @undo_last_capture.
  ///
  /// In en, this message translates to:
  /// **'Undo last capture'**
  String get undo_last_capture;

  /// No description provided for @composition_grid.
  ///
  /// In en, this message translates to:
  /// **'Composition grid'**
  String get composition_grid;

  /// No description provided for @switch_camera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get switch_camera;

  /// No description provided for @couldnt_capture.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t capture — please try again.'**
  String get couldnt_capture;

  /// No description provided for @couldnt_open_gallery.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the gallery.'**
  String get couldnt_open_gallery;

  /// No description provided for @couldnt_start_camera.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the camera — please go back and try again.'**
  String get couldnt_start_camera;

  /// No description provided for @camera_access_needed.
  ///
  /// In en, this message translates to:
  /// **'Camera access needed'**
  String get camera_access_needed;

  /// No description provided for @camera_access_body.
  ///
  /// In en, this message translates to:
  /// **'OpenScan only uses your camera to scan pages — nothing leaves your device. Turn it on in Settings to continue.'**
  String get camera_access_body;

  /// No description provided for @done_count.
  ///
  /// In en, this message translates to:
  /// **'Done · {count}'**
  String done_count(int count);

  /// No description provided for @delete_document.
  ///
  /// In en, this message translates to:
  /// **'Delete document'**
  String get delete_document;

  /// No description provided for @delete_document_body.
  ///
  /// In en, this message translates to:
  /// **'Every page goes with it. This can\'t be undone.'**
  String get delete_document_body;

  /// No description provided for @delete_page_q.
  ///
  /// In en, this message translates to:
  /// **'Delete page?'**
  String get delete_page_q;

  /// No description provided for @delete_n_pages_q.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} pages?'**
  String delete_n_pages_q(int count);

  /// No description provided for @no_pages_title.
  ///
  /// In en, this message translates to:
  /// **'This document has no pages'**
  String get no_pages_title;

  /// No description provided for @no_pages_body.
  ///
  /// In en, this message translates to:
  /// **'Named after your first page — rename anytime by tapping the title.'**
  String get no_pages_body;

  /// No description provided for @continue_scanning.
  ///
  /// In en, this message translates to:
  /// **'Continue scanning'**
  String get continue_scanning;

  /// No description provided for @add_pages.
  ///
  /// In en, this message translates to:
  /// **'Add pages'**
  String get add_pages;

  /// No description provided for @export_selected.
  ///
  /// In en, this message translates to:
  /// **'Export selected'**
  String get export_selected;

  /// No description provided for @export_n_selected.
  ///
  /// In en, this message translates to:
  /// **'Export {count} selected'**
  String export_n_selected(int count);

  /// No description provided for @skipped_files.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Skipped 1 file this app can\'t read.} other{Skipped {count} files this app can\'t read.}}'**
  String skipped_files(int count);

  /// No description provided for @hold_to_reorder.
  ///
  /// In en, this message translates to:
  /// **'{pages} · hold a page to reorder'**
  String hold_to_reorder(String pages);

  /// No description provided for @export_title.
  ///
  /// In en, this message translates to:
  /// **'Export · {name}'**
  String export_title(String name);

  /// Section heading in the export sheet, shown in caps
  ///
  /// In en, this message translates to:
  /// **'QUALITY'**
  String get quality_caps;

  /// No description provided for @page_size.
  ///
  /// In en, this message translates to:
  /// **'Page size'**
  String get page_size;

  /// No description provided for @all_pages.
  ///
  /// In en, this message translates to:
  /// **'All pages'**
  String get all_pages;

  /// No description provided for @selected_pages.
  ///
  /// In en, this message translates to:
  /// **'Selected pages'**
  String get selected_pages;

  /// No description provided for @page_x_of_y.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String page_x_of_y(int current, int total);

  /// No description provided for @exported.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get exported;

  /// No description provided for @export_failed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get export_failed;

  /// No description provided for @no_pages_to_export.
  ///
  /// In en, this message translates to:
  /// **'There are no pages to export.'**
  String get no_pages_to_export;

  /// No description provided for @pdf_not_written.
  ///
  /// In en, this message translates to:
  /// **'PDF could not be written'**
  String get pdf_not_written;

  /// No description provided for @not_enough_storage.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage space on this device.'**
  String get not_enough_storage;

  /// No description provided for @export_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while exporting.'**
  String get export_went_wrong;

  /// No description provided for @couldnt_open_file.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the file: {message}'**
  String couldnt_open_file(String message);

  /// No description provided for @no_app_opens_file.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone opens that kind of file'**
  String get no_app_opens_file;

  /// No description provided for @quality_ultra_low.
  ///
  /// In en, this message translates to:
  /// **'Ultra low'**
  String get quality_ultra_low;

  /// No description provided for @quality_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get quality_low;

  /// No description provided for @quality_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get quality_medium;

  /// No description provided for @quality_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get quality_high;

  /// No description provided for @result_and_more.
  ///
  /// In en, this message translates to:
  /// **'{name} + {count} more'**
  String result_and_more(String name, int count);

  /// No description provided for @rename_file.
  ///
  /// In en, this message translates to:
  /// **'Rename file'**
  String get rename_file;

  /// No description provided for @file_name_empty.
  ///
  /// In en, this message translates to:
  /// **'File name cannot be empty'**
  String get file_name_empty;

  /// No description provided for @special_chars_not_allowed.
  ///
  /// In en, this message translates to:
  /// **'Special characters are not allowed'**
  String get special_chars_not_allowed;

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

  /// No description provided for @demo_scan_title.
  ///
  /// In en, this message translates to:
  /// **'Point at the page'**
  String get demo_scan_title;

  /// No description provided for @demo_scan_body.
  ///
  /// In en, this message translates to:
  /// **'OpenScan finds the edges and takes the shot by itself when you hold still — or tap the shutter to take it yourself.'**
  String get demo_scan_body;

  /// No description provided for @demo_pages_title.
  ///
  /// In en, this message translates to:
  /// **'Keep going for more pages'**
  String get demo_pages_title;

  /// No description provided for @demo_pages_body.
  ///
  /// In en, this message translates to:
  /// **'Every shot joins the same document. Tap Done when you have them all.'**
  String get demo_pages_body;

  /// No description provided for @demo_adjust_title.
  ///
  /// In en, this message translates to:
  /// **'Straighten and clean up'**
  String get demo_adjust_title;

  /// No description provided for @demo_adjust_body.
  ///
  /// In en, this message translates to:
  /// **'Drag the corners if the edges are off, then pick a filter — Auto, Grayscale or B&W.'**
  String get demo_adjust_body;

  /// No description provided for @demo_organise_title.
  ///
  /// In en, this message translates to:
  /// **'Reorder and add pages'**
  String get demo_organise_title;

  /// No description provided for @demo_organise_body.
  ///
  /// In en, this message translates to:
  /// **'Hold a page to move it, and add more pages to a document whenever you like.'**
  String get demo_organise_body;

  /// No description provided for @demo_export_title.
  ///
  /// In en, this message translates to:
  /// **'Save or share as PDF'**
  String get demo_export_title;

  /// No description provided for @demo_export_body.
  ///
  /// In en, this message translates to:
  /// **'Choose a quality and page size, then save it to your phone or send it anywhere.'**
  String get demo_export_body;

  /// No description provided for @demo_privacy_title.
  ///
  /// In en, this message translates to:
  /// **'It never leaves your phone'**
  String get demo_privacy_title;

  /// No description provided for @demo_privacy_body.
  ///
  /// In en, this message translates to:
  /// **'No accounts, no cloud, no ads, no tracking. The camera is used for scanning and nothing else.'**
  String get demo_privacy_body;

  /// No description provided for @allow_camera_access.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access'**
  String get allow_camera_access;

  /// No description provided for @app_description.
  ///
  /// In en, this message translates to:
  /// **'is an open-source app which enables users to scan hard copies of documents and convert it into a PDF file.'**
  String get app_description;

  /// No description provided for @app_description_2.
  ///
  /// In en, this message translates to:
  /// **'No ads. We don\'t collect any data.\n We respect your privacy.'**
  String get app_description_2;

  /// No description provided for @open_source_github.
  ///
  /// In en, this message translates to:
  /// **'Open source on GitHub'**
  String get open_source_github;

  /// No description provided for @couldnt_launch_url.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t launch the url'**
  String get couldnt_launch_url;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'el',
    'en',
    'hi',
    'hu',
    'pl',
    'ta',
  ].contains(locale.languageCode);

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
    case 'hi':
      return AppLocalizationsHi();
    case 'hu':
      return AppLocalizationsHu();
    case 'pl':
      return AppLocalizationsPl();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
