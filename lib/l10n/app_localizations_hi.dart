// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get about => 'परिचय';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get open => 'खोलें';

  @override
  String get share => 'साझा करें';

  @override
  String get export => 'निर्यात';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get crop => 'काटें';

  @override
  String get done => 'पूर्ण';

  @override
  String get next => 'आगे';

  @override
  String get skip => 'छोड़ें';

  @override
  String get loading => 'लोड हो रहा है';

  @override
  String get home => 'होम';

  @override
  String get demo => 'डेमो';

  @override
  String get quality => 'गुणवत्ता';

  @override
  String get version => 'संस्करण';

  @override
  String get select => 'चुनें';

  @override
  String get select_all => 'सभी चुनें';

  @override
  String get select_pages => 'पृष्ठ चुनें';

  @override
  String get try_again => 'पुनः प्रयास करें';

  @override
  String get undo => 'पूर्ववत करें';

  @override
  String get not_now => 'अभी नहीं';

  @override
  String get open_settings => 'सेटिंग्स खोलें';

  @override
  String get more => 'और';

  @override
  String get sort => 'क्रमबद्ध करें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get tutorial => 'ट्यूटोरियल';

  @override
  String get library => 'लाइब्रेरी';

  @override
  String get scan => 'स्कैन';

  @override
  String get image => 'छवि';

  @override
  String get images => 'छवियाँ';

  @override
  String get developers => 'डेवलपर';

  @override
  String get tutorial_title => 'ऐप का उपयोग कैसे करें?';

  @override
  String get cant_be_undone => 'इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get rotate => 'घुमाएँ';

  @override
  String get rotate_left => 'बाएँ घुमाएँ';

  @override
  String get rotate_right => 'दाएँ घुमाएँ';

  @override
  String pages_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पृष्ठ',
      one: '1 पृष्ठ',
    );
    return '$_temp0';
  }

  @override
  String get scan_options => 'स्कैन विकल्प';

  @override
  String get live_scan => 'लाइव स्कैन';

  @override
  String get import_from_gallery => 'गैलरी से आयात करें';

  @override
  String get import_from_gallery_short => 'गैलरी से आयात करें';

  @override
  String get refresh => 'ताज़ा करने के लिए नीचे खींचें';

  @override
  String get last_updated => 'अंतिम बार अपडेट किया गया';

  @override
  String get sort_order => 'क्रम';

  @override
  String get search_documents => 'दस्तावेज़ खोजें';

  @override
  String get no_documents_yet => 'अभी कोई दस्तावेज़ नहीं';

  @override
  String get no_documents_body =>
      'अपना पहला पृष्ठ स्कैन करें — इसमें लगभग दो सेकंड लगते हैं और यह केवल इसी डिवाइस पर रहता है।';

  @override
  String get start_scanning => 'स्कैन करना शुरू करें';

  @override
  String no_results_for(String query) {
    return '“$query” के लिए कोई परिणाम नहीं';
  }

  @override
  String get refreshing => 'ताज़ा हो रहा है…';

  @override
  String get exporting => 'निर्यात हो रहा है…';

  @override
  String n_selected(int count) {
    return '$count चुने गए';
  }

  @override
  String get delete_document_q => 'दस्तावेज़ हटाएँ?';

  @override
  String delete_n_documents_q(int count) {
    return '$count दस्तावेज़ हटाएँ?';
  }

  @override
  String get document_deleted => 'दस्तावेज़ हटाया गया';

  @override
  String n_documents_deleted(int count) {
    return '$count दस्तावेज़ हटाए गए';
  }

  @override
  String saved_n_to_device(int count) {
    return '$count डिवाइस पर सहेजे गए';
  }

  @override
  String couldnt_export_n(int count) {
    return '$count निर्यात नहीं हो सके';
  }

  @override
  String date_and_pages(String date, String pages) {
    return '$date · $pages';
  }

  @override
  String get sort_last_modified => 'अंतिम बार संशोधित';

  @override
  String get sort_date_created => 'बनाने की तिथि';

  @override
  String get sort_name => 'नाम (अ–ज्ञ)';

  @override
  String get sort_page_count => 'पृष्ठ संख्या';

  @override
  String get scanning => 'स्कैनिंग';

  @override
  String get auto_capture => 'स्वतः कैप्चर';

  @override
  String get auto_capture_desc => 'पृष्ठ स्थिर होते ही तस्वीर ले लें।';

  @override
  String get capture_sound => 'कैप्चर ध्वनि';

  @override
  String get keep_original => 'मूल छवि रखें';

  @override
  String get keep_original_desc =>
      'बिना काटी गई तस्वीर रखता है ताकि पूरे कैप्चर से पृष्ठ को दोबारा काटा जा सके। दस्तावेज़ द्वारा उपयोग की जाने वाली जगह लगभग दोगुनी हो जाती है।';

  @override
  String get avoid_gesture_strip => 'बैक-जेस्चर पट्टी से बचें';

  @override
  String get avoid_gesture_strip_desc =>
      'कटाई के कोनों को स्क्रीन के किनारे से दूर रखता है, जहाँ खींचने पर सिस्टम का बैक जेस्चर चल सकता है। पृष्ठ थोड़ा सँकरा हो जाता है।';

  @override
  String get default_filter => 'डिफ़ॉल्ट फ़िल्टर';

  @override
  String get appearance => 'रूप';

  @override
  String get theme => 'थीम';

  @override
  String get language => 'भाषा';

  @override
  String get accent_color => 'एक्सेंट रंग';

  @override
  String get privacy_storage => 'गोपनीयता और संग्रहण';

  @override
  String get privacy_body =>
      'OpenScan आपके दस्तावेज़ कहीं नहीं भेजता। कोई खाता नहीं, कोई क्लाउड नहीं, कोई टेलीमेट्री नहीं।';

  @override
  String get cache => 'कैश';

  @override
  String get clear_cache_q => 'कैश साफ़ करें?';

  @override
  String clear_cache_body(String size) {
    return '$size थंबनेल डेटा खाली करता है। आपके दस्तावेज़ प्रभावित नहीं होंगे।';
  }

  @override
  String cache_clear_action(String size) {
    return '$size · साफ़ करें';
  }

  @override
  String get cache_cleared => 'कैश साफ़ हो गया';

  @override
  String get couldnt_clear_cache => 'कैश साफ़ नहीं हो सका';

  @override
  String get theme_system => 'सिस्टम';

  @override
  String get theme_light => 'हल्का';

  @override
  String get theme_dark => 'गहरा';

  @override
  String get filters => 'फ़िल्टर';

  @override
  String get filter_original => 'मूल';

  @override
  String get filter_auto => 'स्वतः';

  @override
  String get filter_lighten => 'हल्का करें';

  @override
  String get filter_grayscale => 'ग्रेस्केल';

  @override
  String get filter_bw => 'श्वेत-श्याम';

  @override
  String get filter_whiteboard => 'व्हाइटबोर्ड';

  @override
  String get filter_action => 'फ़िल्टर';

  @override
  String get apply_to_all_pages => 'सभी पृष्ठों पर लागू करें';

  @override
  String apply_to_all_n_pages(int count) {
    return 'सभी $count पृष्ठों पर लागू करें';
  }

  @override
  String get adjust_edges => 'किनारे समायोजित करें';

  @override
  String get automatic_crop => 'स्वतः कटाई';

  @override
  String get no_crop => 'कटाई नहीं';

  @override
  String get rescan => 'फिर से स्कैन करें';

  @override
  String get couldnt_crop => 'छवि नहीं काटी जा सकी — पुनः प्रयास करें।';

  @override
  String get looking_for_document => 'दस्तावेज़ खोजा जा रहा है…';

  @override
  String get document_detected => 'दस्तावेज़ मिला';

  @override
  String get hold_still => 'स्थिर रखें…';

  @override
  String get auto_on => 'स्वतः · चालू';

  @override
  String get auto_off => 'स्वतः · बंद';

  @override
  String get low_light => 'कम रोशनी — स्थिर रखें या फ़्लैश चालू करें';

  @override
  String get torch_on => 'टॉर्च चालू';

  @override
  String get torch_off => 'टॉर्च बंद';

  @override
  String get torch_unavailable => 'इस डिवाइस पर टॉर्च उपलब्ध नहीं है।';

  @override
  String get auto_capture_on => 'स्वतः कैप्चर चालू';

  @override
  String get auto_capture_off => 'स्वतः कैप्चर बंद';

  @override
  String get undo_last_capture => 'अंतिम कैप्चर पूर्ववत करें';

  @override
  String get composition_grid => 'संयोजन ग्रिड';

  @override
  String get switch_camera => 'कैमरा बदलें';

  @override
  String get couldnt_capture => 'कैप्चर नहीं हो सका — पुनः प्रयास करें।';

  @override
  String get couldnt_open_gallery => 'गैलरी नहीं खुल सकी।';

  @override
  String get couldnt_start_camera =>
      'कैमरा शुरू नहीं हो सका — वापस जाकर पुनः प्रयास करें।';

  @override
  String get camera_access_needed => 'कैमरा एक्सेस आवश्यक';

  @override
  String get camera_access_body =>
      'OpenScan आपके कैमरे का उपयोग केवल पृष्ठ स्कैन करने के लिए करता है — कुछ भी आपके डिवाइस से बाहर नहीं जाता। जारी रखने के लिए इसे सेटिंग्स में चालू करें।';

  @override
  String done_count(int count) {
    return 'पूर्ण · $count';
  }

  @override
  String get delete_document => 'दस्तावेज़ हटाएँ';

  @override
  String get delete_document_body =>
      'इसके साथ हर पृष्ठ हट जाएगा। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get delete_page_q => 'पृष्ठ हटाएँ?';

  @override
  String delete_n_pages_q(int count) {
    return '$count पृष्ठ हटाएँ?';
  }

  @override
  String get no_pages_title => 'इस दस्तावेज़ में कोई पृष्ठ नहीं है';

  @override
  String get no_pages_body =>
      'आपके पहले पृष्ठ के नाम पर रखा गया — शीर्षक पर टैप करके कभी भी नाम बदलें।';

  @override
  String get continue_scanning => 'स्कैन करना जारी रखें';

  @override
  String get add_pages => 'पृष्ठ जोड़ें';

  @override
  String get export_selected => 'चयनित निर्यात करें';

  @override
  String export_n_selected(int count) {
    return '$count चयनित निर्यात करें';
  }

  @override
  String skipped_files(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ाइलें छोड़ी गईं जिन्हें यह ऐप नहीं पढ़ सकता।',
      one: '1 फ़ाइल छोड़ी गई जिसे यह ऐप नहीं पढ़ सकता।',
    );
    return '$_temp0';
  }

  @override
  String hold_to_reorder(String pages) {
    return '$pages · क्रम बदलने के लिए किसी पृष्ठ को दबाए रखें';
  }

  @override
  String export_title(String name) {
    return 'निर्यात · $name';
  }

  @override
  String get quality_caps => 'गुणवत्ता';

  @override
  String get page_size => 'पृष्ठ आकार';

  @override
  String get all_pages => 'सभी पृष्ठ';

  @override
  String get selected_pages => 'चयनित पृष्ठ';

  @override
  String page_x_of_y(int current, int total) {
    return 'पृष्ठ $current / $total';
  }

  @override
  String get exported => 'निर्यात हो गया';

  @override
  String get export_failed => 'निर्यात विफल';

  @override
  String get no_pages_to_export => 'निर्यात के लिए कोई पृष्ठ नहीं है।';

  @override
  String get pdf_not_written => 'PDF नहीं लिखी जा सकी';

  @override
  String get not_enough_storage =>
      'इस डिवाइस पर पर्याप्त संग्रहण स्थान नहीं है।';

  @override
  String get export_went_wrong => 'निर्यात के दौरान कुछ गड़बड़ हो गई।';

  @override
  String couldnt_open_file(String message) {
    return 'फ़ाइल नहीं खुल सकी: $message';
  }

  @override
  String get no_app_opens_file =>
      'इस फ़ोन पर कोई ऐप इस प्रकार की फ़ाइल नहीं खोलता';

  @override
  String get quality_ultra_low => 'अति निम्न';

  @override
  String get quality_low => 'निम्न';

  @override
  String get quality_medium => 'मध्यम';

  @override
  String get quality_high => 'उच्च';

  @override
  String result_and_more(String name, int count) {
    return '$name + $count और';
  }

  @override
  String get rename_file => 'फ़ाइल का नाम बदलें';

  @override
  String get file_name_empty => 'फ़ाइल का नाम खाली नहीं हो सकता';

  @override
  String get special_chars_not_allowed => 'विशेष वर्ण अनुमत नहीं हैं';

  @override
  String get save_to_device => 'डिवाइस पर सहेजें';

  @override
  String get share_pdf => 'PDF साझा करें';

  @override
  String get share_images => 'छवियाँ साझा करें';

  @override
  String get demo_scan_title => 'पृष्ठ की ओर कैमरा करें';

  @override
  String get demo_scan_body =>
      'फ़ोन स्थिर रखें तो OpenScan किनारे ढूँढ़कर खुद ही तस्वीर ले लेता है — या शटर दबाकर खुद तस्वीर लें।';

  @override
  String get demo_pages_title => 'और पृष्ठों के लिए जारी रखें';

  @override
  String get demo_pages_body =>
      'हर तस्वीर उसी दस्तावेज़ में जुड़ती है। सब हो जाएँ तो \'पूर्ण\' दबाएँ।';

  @override
  String get demo_adjust_title => 'सीधा करें और साफ़ करें';

  @override
  String get demo_adjust_body =>
      'किनारे ठीक न हों तो कोनों को खींचें, फिर फ़िल्टर चुनें — स्वतः, ग्रेस्केल या श्वेत-श्याम।';

  @override
  String get demo_organise_title => 'क्रम बदलें और पृष्ठ जोड़ें';

  @override
  String get demo_organise_body =>
      'पृष्ठ को दबाकर रखें और खिसकाएँ, और जब चाहें दस्तावेज़ में नए पृष्ठ जोड़ें।';

  @override
  String get demo_export_title => 'PDF के रूप में सहेजें या साझा करें';

  @override
  String get demo_export_body =>
      'गुणवत्ता और पृष्ठ आकार चुनें, फिर फ़ोन में सहेजें या कहीं भी भेजें।';

  @override
  String get demo_privacy_title => 'यह कभी आपका फ़ोन नहीं छोड़ता';

  @override
  String get demo_privacy_body =>
      'कोई खाता नहीं, कोई क्लाउड नहीं, कोई विज्ञापन नहीं, कोई ट्रैकिंग नहीं। कैमरा सिर्फ़ स्कैन करने के लिए इस्तेमाल होता है।';

  @override
  String get allow_camera_access => 'कैमरा एक्सेस की अनुमति दें';

  @override
  String get app_description =>
      'एक ओपन-सोर्स ऐप है जो उपयोगकर्ताओं को कागज़ी दस्तावेज़ स्कैन करके उन्हें PDF फ़ाइल में बदलने देता है।';

  @override
  String get app_description_2 =>
      'कोई विज्ञापन नहीं। हम कोई डेटा एकत्र नहीं करते।\n हम आपकी गोपनीयता का सम्मान करते हैं।';

  @override
  String get open_source_github => 'GitHub पर ओपन सोर्स';

  @override
  String get couldnt_launch_url => 'लिंक नहीं खोला जा सका';
}
