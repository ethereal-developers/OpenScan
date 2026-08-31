// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get about => 'பற்றி';

  @override
  String get cancel => 'ரத்து';

  @override
  String get save => 'சேமி';

  @override
  String get open => 'திற';

  @override
  String get share => 'பகிர்';

  @override
  String get export => 'ஏற்றுமதி';

  @override
  String get clear => 'அழி';

  @override
  String get delete => 'நீக்கு';

  @override
  String get rename => 'மறுபெயரிடு';

  @override
  String get crop => 'வெட்டு';

  @override
  String get done => 'முடிந்தது';

  @override
  String get next => 'அடுத்து';

  @override
  String get skip => 'தவிர்';

  @override
  String get loading => 'ஏற்றுகிறது';

  @override
  String get home => 'முகப்பு';

  @override
  String get demo => 'அறிமுகம்';

  @override
  String get quality => 'தரம்';

  @override
  String get version => 'பதிப்பு';

  @override
  String get select => 'தேர்ந்தெடு';

  @override
  String get select_all => 'அனைத்தையும் தேர்ந்தெடு';

  @override
  String get select_pages => 'பக்கங்களைத் தேர்ந்தெடு';

  @override
  String get try_again => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get undo => 'செயல்தவிர்';

  @override
  String get not_now => 'இப்போது வேண்டாம்';

  @override
  String get open_settings => 'அமைப்புகளைத் திற';

  @override
  String get more => 'மேலும்';

  @override
  String get sort => 'வரிசைப்படுத்து';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get tutorial => 'பயிற்சி';

  @override
  String get library => 'நூலகம்';

  @override
  String get scan => 'ஸ்கேன்';

  @override
  String get image => 'படம்';

  @override
  String get images => 'படங்கள்';

  @override
  String get developers => 'உருவாக்குநர்கள்';

  @override
  String get tutorial_title => 'செயலியை எப்படிப் பயன்படுத்துவது?';

  @override
  String get cant_be_undone => 'இதைத் திரும்பப் பெற முடியாது.';

  @override
  String get rotate => 'சுழற்று';

  @override
  String get rotate_left => 'இடதுபுறம் சுழற்று';

  @override
  String get rotate_right => 'வலதுபுறம் சுழற்று';

  @override
  String pages_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பக்கங்கள்',
      one: '1 பக்கம்',
    );
    return '$_temp0';
  }

  @override
  String get scan_options => 'ஸ்கேன் விருப்பங்கள்';

  @override
  String get live_scan => 'நேரடி ஸ்கேன்';

  @override
  String get import_from_gallery => 'கேலரியிலிருந்து இறக்குமதி';

  @override
  String get import_from_gallery_short => 'கேலரியிலிருந்து இறக்குமதி';

  @override
  String get refresh => 'புதுப்பிக்க கீழே இழுக்கவும்';

  @override
  String get last_updated => 'கடைசியாக புதுப்பிக்கப்பட்டது';

  @override
  String get sort_order => 'வரிசை முறை';

  @override
  String get search_documents => 'ஆவணங்களைத் தேடு';

  @override
  String get no_documents_yet => 'இதுவரை ஆவணங்கள் இல்லை';

  @override
  String get no_documents_body =>
      'உங்கள் முதல் பக்கத்தை ஸ்கேன் செய்யுங்கள் — சுமார் இரண்டு வினாடிகள் ஆகும், இது இந்தச் சாதனத்தில் மட்டுமே இருக்கும்.';

  @override
  String get start_scanning => 'ஸ்கேன் செய்யத் தொடங்கு';

  @override
  String no_results_for(String query) {
    return '“$query” க்கு முடிவுகள் இல்லை';
  }

  @override
  String get refreshing => 'புதுப்பிக்கிறது…';

  @override
  String get exporting => 'ஏற்றுமதி செய்கிறது…';

  @override
  String n_selected(int count) {
    return '$count தேர்ந்தெடுக்கப்பட்டது';
  }

  @override
  String get delete_document_q => 'ஆவணத்தை நீக்கவா?';

  @override
  String delete_n_documents_q(int count) {
    return '$count ஆவணங்களை நீக்கவா?';
  }

  @override
  String get document_deleted => 'ஆவணம் நீக்கப்பட்டது';

  @override
  String n_documents_deleted(int count) {
    return '$count ஆவணங்கள் நீக்கப்பட்டன';
  }

  @override
  String saved_n_to_device(int count) {
    return '$count சாதனத்தில் சேமிக்கப்பட்டது';
  }

  @override
  String couldnt_export_n(int count) {
    return '$count ஏற்றுமதி செய்ய முடியவில்லை';
  }

  @override
  String date_and_pages(String date, String pages) {
    return '$date · $pages';
  }

  @override
  String get sort_last_modified => 'கடைசியாக மாற்றியது';

  @override
  String get sort_date_created => 'உருவாக்கிய தேதி';

  @override
  String get sort_name => 'பெயர் (அகர வரிசை)';

  @override
  String get sort_page_count => 'பக்கங்களின் எண்ணிக்கை';

  @override
  String get scanning => 'ஸ்கேனிங்';

  @override
  String get auto_capture => 'தானியங்கு படமெடுப்பு';

  @override
  String get auto_capture_desc => 'பக்கம் நிலையானதும் உடனே படம் எடுக்கும்.';

  @override
  String get capture_sound => 'படமெடுப்பு ஒலி';

  @override
  String get keep_original => 'அசல் படத்தை வைத்திரு';

  @override
  String get keep_original_desc =>
      'வெட்டப்படாத புகைப்படத்தை வைத்திருக்கும், இதனால் முழுப் படத்திலிருந்து ஒரு பக்கத்தை மீண்டும் வெட்ட முடியும். ஆவணம் பயன்படுத்தும் இடத்தை ஏறக்குறைய இரட்டிப்பாக்கும்.';

  @override
  String get avoid_gesture_strip => 'பின்செல் சைகைப் பகுதியைத் தவிர்';

  @override
  String get avoid_gesture_strip_desc =>
      'வெட்டும் மூலைகளைத் திரையின் விளிம்பிலிருந்து விலக்கி வைக்கும், அங்கு இழுப்பது கணினியின் பின்செல் சைகையைத் தூண்டலாம். பக்கம் சற்று குறுகலாக இருக்கும்.';

  @override
  String get default_filter => 'இயல்புநிலை வடிகட்டி';

  @override
  String get appearance => 'தோற்றம்';

  @override
  String get theme => 'தீம்';

  @override
  String get language => 'மொழி';

  @override
  String get accent_color => 'முன்னிலை நிறம்';

  @override
  String get privacy_storage => 'தனியுரிமை மற்றும் சேமிப்பு';

  @override
  String get privacy_body =>
      'OpenScan உங்கள் ஆவணங்களை எங்கும் அனுப்புவதில்லை. கணக்குகள் இல்லை, கிளவுட் இல்லை, தொலைஅளவீடு இல்லை.';

  @override
  String get cache => 'தற்காலிக சேமிப்பு';

  @override
  String get clear_cache_q => 'தற்காலிக சேமிப்பை அழிக்கவா?';

  @override
  String clear_cache_body(String size) {
    return '$size சிறுபடத் தரவை விடுவிக்கும். உங்கள் ஆவணங்கள் பாதிக்கப்படாது.';
  }

  @override
  String cache_clear_action(String size) {
    return '$size · அழி';
  }

  @override
  String get cache_cleared => 'தற்காலிக சேமிப்பு அழிக்கப்பட்டது';

  @override
  String get couldnt_clear_cache => 'தற்காலிக சேமிப்பை அழிக்க முடியவில்லை';

  @override
  String get theme_system => 'கணினி';

  @override
  String get theme_light => 'வெளிர்';

  @override
  String get theme_dark => 'இருள்';

  @override
  String get filters => 'வடிகட்டிகள்';

  @override
  String get filter_original => 'அசல்';

  @override
  String get filter_auto => 'தானியங்கு';

  @override
  String get filter_lighten => 'வெளிர்வாக்கு';

  @override
  String get filter_grayscale => 'சாம்பல் நிறம்';

  @override
  String get filter_bw => 'கருப்பு-வெள்ளை';

  @override
  String get filter_whiteboard => 'வெள்ளைப் பலகை';

  @override
  String get filter_action => 'வடிகட்டி';

  @override
  String get apply_to_all_pages => 'அனைத்துப் பக்கங்களுக்கும் பயன்படுத்து';

  @override
  String apply_to_all_n_pages(int count) {
    return 'அனைத்து $count பக்கங்களுக்கும் பயன்படுத்து';
  }

  @override
  String get adjust_edges => 'விளிம்புகளைச் சரிசெய்';

  @override
  String get automatic_crop => 'தானியங்கு வெட்டு';

  @override
  String get no_crop => 'வெட்டு வேண்டாம்';

  @override
  String get rescan => 'மீண்டும் ஸ்கேன்';

  @override
  String get couldnt_crop =>
      'படத்தை வெட்ட முடியவில்லை — மீண்டும் முயற்சிக்கவும்.';

  @override
  String get looking_for_document => 'ஆவணத்தைத் தேடுகிறது…';

  @override
  String get document_detected => 'ஆவணம் கண்டறியப்பட்டது';

  @override
  String get hold_still => 'அசையாமல் இருங்கள்…';

  @override
  String get auto_on => 'தானியங்கு · இயக்கம்';

  @override
  String get auto_off => 'தானியங்கு · நிறுத்தம்';

  @override
  String get low_light =>
      'குறைந்த வெளிச்சம் — நிலையாகப் பிடியுங்கள் அல்லது ஒளியை இயக்குங்கள்';

  @override
  String get torch_on => 'ஒளி இயக்கத்தில்';

  @override
  String get torch_off => 'ஒளி நிறுத்தத்தில்';

  @override
  String get torch_unavailable => 'இந்தச் சாதனத்தில் ஒளி கிடைக்கவில்லை.';

  @override
  String get auto_capture_on => 'தானியங்கு படமெடுப்பு இயக்கத்தில்';

  @override
  String get auto_capture_off => 'தானியங்கு படமெடுப்பு நிறுத்தத்தில்';

  @override
  String get undo_last_capture => 'கடைசிப் படத்தை நீக்கு';

  @override
  String get composition_grid => 'அமைப்புக் கட்டம்';

  @override
  String get switch_camera => 'கேமராவை மாற்று';

  @override
  String get couldnt_capture =>
      'படம் எடுக்க முடியவில்லை — மீண்டும் முயற்சிக்கவும்.';

  @override
  String get couldnt_open_gallery => 'கேலரியைத் திறக்க முடியவில்லை.';

  @override
  String get couldnt_start_camera =>
      'கேமராவைத் தொடங்க முடியவில்லை — பின்சென்று மீண்டும் முயற்சிக்கவும்.';

  @override
  String get camera_access_needed => 'கேமரா அணுகல் தேவை';

  @override
  String get camera_access_body =>
      'OpenScan உங்கள் கேமராவைப் பக்கங்களை ஸ்கேன் செய்யவே பயன்படுத்துகிறது — எதுவும் உங்கள் சாதனத்தை விட்டு வெளியேறாது. தொடர அமைப்புகளில் இயக்கவும்.';

  @override
  String done_count(int count) {
    return 'முடிந்தது · $count';
  }

  @override
  String get delete_document => 'ஆவணத்தை நீக்கு';

  @override
  String get delete_document_body =>
      'ஒவ்வொரு பக்கமும் அதனுடன் நீங்கும். இதைத் திரும்பப் பெற முடியாது.';

  @override
  String get delete_page_q => 'பக்கத்தை நீக்கவா?';

  @override
  String delete_n_pages_q(int count) {
    return '$count பக்கங்களை நீக்கவா?';
  }

  @override
  String get no_pages_title => 'இந்த ஆவணத்தில் பக்கங்கள் இல்லை';

  @override
  String get no_pages_body =>
      'உங்கள் முதல் பக்கத்தின் பெயரில் உள்ளது — தலைப்பைத் தட்டி எப்போது வேண்டுமானாலும் மறுபெயரிடலாம்.';

  @override
  String get continue_scanning => 'ஸ்கேனிங்கைத் தொடர்';

  @override
  String get add_pages => 'பக்கங்களைச் சேர்';

  @override
  String get export_selected => 'தேர்ந்தெடுத்தவற்றை ஏற்றுமதி செய்';

  @override
  String export_n_selected(int count) {
    return 'தேர்ந்தெடுத்த $count ஐ ஏற்றுமதி செய்';
  }

  @override
  String skipped_files(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'செயலியால் படிக்க முடியாத $count கோப்புகள் தவிர்க்கப்பட்டன.',
      one: 'செயலியால் படிக்க முடியாத 1 கோப்பு தவிர்க்கப்பட்டது.',
    );
    return '$_temp0';
  }

  @override
  String hold_to_reorder(String pages) {
    return '$pages · வரிசை மாற்ற ஒரு பக்கத்தை அழுத்திப் பிடிக்கவும்';
  }

  @override
  String export_title(String name) {
    return 'ஏற்றுமதி · $name';
  }

  @override
  String get quality_caps => 'தரம்';

  @override
  String get page_size => 'பக்க அளவு';

  @override
  String get all_pages => 'அனைத்துப் பக்கங்களும்';

  @override
  String get selected_pages => 'தேர்ந்தெடுத்த பக்கங்கள்';

  @override
  String page_x_of_y(int current, int total) {
    return 'பக்கம் $current / $total';
  }

  @override
  String get exported => 'ஏற்றுமதி செய்யப்பட்டது';

  @override
  String get export_failed => 'ஏற்றுமதி தோல்வியடைந்தது';

  @override
  String get no_pages_to_export => 'ஏற்றுமதி செய்ய பக்கங்கள் இல்லை.';

  @override
  String get pdf_not_written => 'PDF ஐ எழுத முடியவில்லை';

  @override
  String get not_enough_storage => 'இந்தச் சாதனத்தில் போதுமான இடம் இல்லை.';

  @override
  String get export_went_wrong => 'ஏற்றுமதியின்போது ஏதோ தவறு நடந்தது.';

  @override
  String couldnt_open_file(String message) {
    return 'கோப்பைத் திறக்க முடியவில்லை: $message';
  }

  @override
  String get no_app_opens_file =>
      'இந்த வகைக் கோப்பை இந்தத் தொலைபேசியில் எந்தச் செயலியும் திறக்கவில்லை';

  @override
  String get quality_ultra_low => 'மிகக் குறைவு';

  @override
  String get quality_low => 'குறைவு';

  @override
  String get quality_medium => 'நடுத்தரம்';

  @override
  String get quality_high => 'அதிகம்';

  @override
  String result_and_more(String name, int count) {
    return '$name + மேலும் $count';
  }

  @override
  String get rename_file => 'கோப்புக்கு மறுபெயரிடு';

  @override
  String get file_name_empty => 'கோப்புப் பெயர் காலியாக இருக்கக் கூடாது';

  @override
  String get special_chars_not_allowed =>
      'சிறப்பு எழுத்துகள் அனுமதிக்கப்படவில்லை';

  @override
  String get save_to_device => 'சாதனத்தில் சேமி';

  @override
  String get share_pdf => 'PDF ஐப் பகிர்';

  @override
  String get share_images => 'படங்களைப் பகிர்';

  @override
  String get demo_detect_title => 'காட்டுங்கள், ஸ்கேன் ஆகிவிடும்';

  @override
  String get demo_detect_body =>
      'OpenScan பக்கத்தின் விளிம்புகளைக் கண்டறிந்து தானாகவே படம் எடுக்கும் — ஷட்டரைத் தட்ட வேண்டாம்.';

  @override
  String get demo_private_title => 'எல்லாம் உங்கள் தொலைபேசியிலேயே இருக்கும்';

  @override
  String get demo_private_body =>
      'கணக்குகள் இல்லை, கிளவுட் பதிவேற்றம் இல்லை, விளம்பரங்கள் இல்லை, கண்காணிப்பு இல்லை — ஒருபோதும் இல்லை.';

  @override
  String get demo_camera_title => 'கடைசியாக ஒன்று';

  @override
  String get demo_camera_body =>
      'பக்கங்களை ஸ்கேன் செய்ய OpenScan க்கு உங்கள் கேமரா தேவை. அதற்கு மட்டுமே அது பயன்படுத்தப்படுகிறது.';

  @override
  String get allow_camera_access => 'கேமரா அணுகலை அனுமதி';

  @override
  String get app_description =>
      'என்பது ஒரு திறந்த மூல செயலி, இது பயனர்கள் அச்சிடப்பட்ட ஆவணங்களை ஸ்கேன் செய்து PDF கோப்பாக மாற்ற உதவுகிறது.';

  @override
  String get app_description_2 =>
      'விளம்பரங்கள் இல்லை. நாங்கள் எந்தத் தரவையும் சேகரிப்பதில்லை.\n உங்கள் தனியுரிமையை மதிக்கிறோம்.';

  @override
  String get open_source_github => 'GitHub இல் திறந்த மூலம்';

  @override
  String get couldnt_launch_url => 'இணைப்பைத் திறக்க முடியவில்லை';
}
