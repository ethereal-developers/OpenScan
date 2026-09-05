// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get open => 'Open';

  @override
  String get share => 'Share';

  @override
  String get export => 'Export';

  @override
  String get clear => 'Clear';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get crop => 'Crop';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get loading => 'Loading';

  @override
  String get home => 'Home';

  @override
  String get demo => 'Demo';

  @override
  String get quality => 'Quality';

  @override
  String get version => 'Version';

  @override
  String get select => 'Select';

  @override
  String get select_all => 'Select all';

  @override
  String get select_pages => 'Select pages';

  @override
  String get try_again => 'Try again';

  @override
  String get undo => 'UNDO';

  @override
  String get not_now => 'Not now';

  @override
  String get open_settings => 'Open Settings';

  @override
  String get more => 'More';

  @override
  String get sort => 'Sort';

  @override
  String get settings => 'Settings';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get library => 'Library';

  @override
  String get scan => 'Scan';

  @override
  String get image => 'image';

  @override
  String get images => 'images';

  @override
  String get developers => 'Developers';

  @override
  String get view_on_linkedin => 'View on LinkedIn';

  @override
  String get tutorial_title => 'How to use the app?';

  @override
  String get cant_be_undone => 'This can\'t be undone.';

  @override
  String get rotate => 'Rotate';

  @override
  String get rotate_left => 'Rotate left';

  @override
  String get rotate_right => 'Rotate right';

  @override
  String pages_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get scan_options => 'Scan Options';

  @override
  String get live_scan => 'Live Scan';

  @override
  String get import_from_gallery => 'Import from Gallery';

  @override
  String get import_from_gallery_short => 'Import from gallery';

  @override
  String get refresh => 'Drag down to refresh';

  @override
  String get last_updated => 'Last Updated';

  @override
  String get sort_order => 'Sort order';

  @override
  String get search_documents => 'Search documents';

  @override
  String get no_documents_yet => 'No documents yet';

  @override
  String get no_documents_body =>
      'Scan your first page — it takes about two seconds and stays only on this device.';

  @override
  String get start_scanning => 'Start scanning';

  @override
  String no_results_for(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get refreshing => 'Refreshing…';

  @override
  String get exporting => 'Exporting…';

  @override
  String n_selected(int count) {
    return '$count selected';
  }

  @override
  String get delete_document_q => 'Delete document?';

  @override
  String delete_n_documents_q(int count) {
    return 'Delete $count documents?';
  }

  @override
  String get document_deleted => 'Document deleted';

  @override
  String n_documents_deleted(int count) {
    return '$count documents deleted';
  }

  @override
  String saved_n_to_device(int count) {
    return 'Saved $count to device';
  }

  @override
  String couldnt_export_n(int count) {
    return 'Couldn\'t export $count';
  }

  @override
  String date_and_pages(String date, String pages) {
    return '$date · $pages';
  }

  @override
  String get sort_last_modified => 'Last modified';

  @override
  String get sort_date_created => 'Date created';

  @override
  String get sort_name => 'Name (A–Z)';

  @override
  String get sort_page_count => 'Page count';

  @override
  String get scanning => 'Scanning';

  @override
  String get auto_capture => 'Auto-capture';

  @override
  String get auto_capture_desc =>
      'Take the shot as soon as the page holds still.';

  @override
  String get capture_sound => 'Capture sound';

  @override
  String get keep_original => 'Keep original image';

  @override
  String get keep_original_desc =>
      'Keeps the uncropped photo so a page can be re-cropped from the full capture. Roughly doubles the space a document uses.';

  @override
  String get avoid_gesture_strip => 'Avoid back-gesture strip';

  @override
  String get avoid_gesture_strip_desc =>
      'Keeps the crop corners out of the edge of the screen, where a drag can trigger the system back gesture instead. Makes the page slightly narrower.';

  @override
  String get default_filter => 'Default filter';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get accent_color => 'Accent color';

  @override
  String get privacy_storage => 'Privacy & storage';

  @override
  String get privacy_body =>
      'OpenScan never sends your documents anywhere. No accounts, no cloud, no telemetry.';

  @override
  String get cache => 'Cache';

  @override
  String get clear_cache_q => 'Clear cache?';

  @override
  String clear_cache_body(String size) {
    return 'Frees $size of thumbnail data. Your documents are not affected.';
  }

  @override
  String cache_clear_action(String size) {
    return '$size · Clear';
  }

  @override
  String get cache_cleared => 'Cache cleared';

  @override
  String get couldnt_clear_cache => 'Couldn\'t clear the cache';

  @override
  String get theme_system => 'System';

  @override
  String get theme_light => 'Light';

  @override
  String get theme_dark => 'Dark';

  @override
  String get filters => 'Filters';

  @override
  String get filter_original => 'Original';

  @override
  String get filter_auto => 'Auto';

  @override
  String get filter_lighten => 'Lighten';

  @override
  String get filter_grayscale => 'Grayscale';

  @override
  String get filter_bw => 'B&W';

  @override
  String get filter_whiteboard => 'Whiteboard';

  @override
  String get filter_action => 'Filter';

  @override
  String get apply_to_all_pages => 'Apply to all pages';

  @override
  String apply_to_all_n_pages(int count) {
    return 'Apply to all $count pages';
  }

  @override
  String get adjust_edges => 'Adjust edges';

  @override
  String get automatic_crop => 'Automatic crop';

  @override
  String get no_crop => 'No crop';

  @override
  String get rescan => 'Re-scan';

  @override
  String get couldnt_crop => 'Couldn\'t crop the image — please try again.';

  @override
  String get looking_for_document => 'Looking for a document…';

  @override
  String get document_detected => 'Document detected';

  @override
  String get hold_still => 'HOLD STILL…';

  @override
  String get auto_on => 'AUTO · ON';

  @override
  String get auto_off => 'AUTO · OFF';

  @override
  String get low_light => 'Low light — hold steady or turn on flash';

  @override
  String get torch_on => 'Torch on';

  @override
  String get torch_off => 'Torch off';

  @override
  String get torch_unavailable => 'Torch isn\'t available on this device.';

  @override
  String get auto_capture_on => 'Auto-capture on';

  @override
  String get auto_capture_off => 'Auto-capture off';

  @override
  String get undo_last_capture => 'Undo last capture';

  @override
  String get composition_grid => 'Composition grid';

  @override
  String get switch_camera => 'Switch camera';

  @override
  String get couldnt_capture => 'Couldn\'t capture — please try again.';

  @override
  String get couldnt_open_gallery => 'Couldn\'t open the gallery.';

  @override
  String get couldnt_start_camera =>
      'Couldn\'t start the camera — please go back and try again.';

  @override
  String get camera_access_needed => 'Camera access needed';

  @override
  String get camera_access_body =>
      'OpenScan only uses your camera to scan pages — nothing leaves your device. Turn it on in Settings to continue.';

  @override
  String done_count(int count) {
    return 'Done · $count';
  }

  @override
  String get delete_document => 'Delete document';

  @override
  String get delete_document_body =>
      'Every page goes with it. This can\'t be undone.';

  @override
  String get delete_page_q => 'Delete page?';

  @override
  String delete_n_pages_q(int count) {
    return 'Delete $count pages?';
  }

  @override
  String get no_pages_title => 'This document has no pages';

  @override
  String get no_pages_body =>
      'Named after your first page — rename anytime by tapping the title.';

  @override
  String get continue_scanning => 'Continue scanning';

  @override
  String get add_pages => 'Add pages';

  @override
  String get export_selected => 'Export selected';

  @override
  String export_n_selected(int count) {
    return 'Export $count selected';
  }

  @override
  String skipped_files(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skipped $count files this app can\'t read.',
      one: 'Skipped 1 file this app can\'t read.',
    );
    return '$_temp0';
  }

  @override
  String hold_to_reorder(String pages) {
    return '$pages · hold a page to reorder';
  }

  @override
  String export_title(String name) {
    return 'Export · $name';
  }

  @override
  String get quality_caps => 'QUALITY';

  @override
  String get page_size => 'Page size';

  @override
  String get all_pages => 'All pages';

  @override
  String get selected_pages => 'Selected pages';

  @override
  String page_x_of_y(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get exported => 'Exported';

  @override
  String get export_failed => 'Export failed';

  @override
  String get no_pages_to_export => 'There are no pages to export.';

  @override
  String get pdf_not_written => 'PDF could not be written';

  @override
  String get not_enough_storage => 'Not enough storage space on this device.';

  @override
  String get export_went_wrong => 'Something went wrong while exporting.';

  @override
  String couldnt_open_file(String message) {
    return 'Couldn\'t open the file: $message';
  }

  @override
  String get no_app_opens_file =>
      'No app on this phone opens that kind of file';

  @override
  String get quality_ultra_low => 'Ultra low';

  @override
  String get quality_low => 'Low';

  @override
  String get quality_medium => 'Medium';

  @override
  String get quality_high => 'High';

  @override
  String result_and_more(String name, int count) {
    return '$name + $count more';
  }

  @override
  String get rename_file => 'Rename file';

  @override
  String get file_name_empty => 'File name cannot be empty';

  @override
  String get special_chars_not_allowed => 'Special characters are not allowed';

  @override
  String get save_to_device => 'Save to device';

  @override
  String get share_pdf => 'Share PDF';

  @override
  String get share_images => 'Share images';

  @override
  String get demo_scan_title => 'Point at the page';

  @override
  String get demo_scan_body =>
      'OpenScan finds the edges and takes the shot by itself when you hold still — or tap the shutter to take it yourself.';

  @override
  String get demo_pages_title => 'Keep going for more pages';

  @override
  String get demo_pages_body =>
      'Every shot joins the same document. Tap Done when you have them all.';

  @override
  String get demo_adjust_title => 'Straighten and clean up';

  @override
  String get demo_adjust_body =>
      'Drag the corners if the edges are off, then pick a filter — Auto, Grayscale or B&W.';

  @override
  String get demo_organise_title => 'Reorder and add pages';

  @override
  String get demo_organise_body =>
      'Hold a page to move it, and add more pages to a document whenever you like.';

  @override
  String get demo_export_title => 'Save or share as PDF';

  @override
  String get demo_export_body =>
      'Choose a quality and page size, then save it to your phone or send it anywhere.';

  @override
  String get demo_privacy_title => 'It never leaves your phone';

  @override
  String get demo_privacy_body =>
      'No accounts, no cloud, no ads, no tracking. The camera is used for scanning and nothing else.';

  @override
  String get allow_camera_access => 'Allow camera access';

  @override
  String get app_description =>
      'is an open-source app which enables users to scan hard copies of documents and convert it into a PDF file.';

  @override
  String get app_description_2 =>
      'No ads. We don\'t collect any data.\n We respect your privacy.';

  @override
  String get open_source_github => 'Open source on GitHub';

  @override
  String get couldnt_launch_url => 'Couldn\'t launch the url';
}
