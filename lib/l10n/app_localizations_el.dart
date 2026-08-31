// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get about => 'Σχετικά';

  @override
  String get cancel => 'Άκυρο';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get open => 'Άνοιγμα';

  @override
  String get share => 'Κοινοποίηση';

  @override
  String get export => 'Εξαγωγή';

  @override
  String get clear => 'Εκκαθάριση';

  @override
  String get delete => 'Διαγραφή';

  @override
  String get rename => 'Μετονομασία';

  @override
  String get crop => 'Περικοπή';

  @override
  String get done => 'Τέλος';

  @override
  String get next => 'Επόμενο';

  @override
  String get skip => 'Παράλειψη';

  @override
  String get loading => 'Φόρτωση';

  @override
  String get home => 'Αρχική';

  @override
  String get demo => 'Επίδειξη';

  @override
  String get quality => 'Ποιότητα';

  @override
  String get version => 'Έκδοση';

  @override
  String get select => 'Επιλογή';

  @override
  String get select_all => 'Επιλογή όλων';

  @override
  String get select_pages => 'Επιλογή σελίδων';

  @override
  String get try_again => 'Δοκιμάστε ξανά';

  @override
  String get undo => 'ΑΝΑΙΡΕΣΗ';

  @override
  String get not_now => 'Όχι τώρα';

  @override
  String get open_settings => 'Άνοιγμα ρυθμίσεων';

  @override
  String get more => 'Περισσότερα';

  @override
  String get sort => 'Ταξινόμηση';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get tutorial => 'Οδηγός';

  @override
  String get library => 'Βιβλιοθήκη';

  @override
  String get scan => 'Σάρωση';

  @override
  String get image => 'εικόνα';

  @override
  String get images => 'εικόνες';

  @override
  String get developers => 'Προγραμματιστές';

  @override
  String get tutorial_title => 'Πώς να χρησιμοποιήσετε την εφαρμογή;';

  @override
  String get cant_be_undone => 'Αυτό δεν μπορεί να αναιρεθεί.';

  @override
  String get rotate => 'Περιστροφή';

  @override
  String get rotate_left => 'Περιστροφή αριστερά';

  @override
  String get rotate_right => 'Περιστροφή δεξιά';

  @override
  String pages_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count σελίδες',
      one: '1 σελίδα',
    );
    return '$_temp0';
  }

  @override
  String get scan_options => 'Επιλογές σάρωσης';

  @override
  String get live_scan => 'Ζωντανή σάρωση';

  @override
  String get import_from_gallery => 'Εισαγωγή από τη συλλογή';

  @override
  String get import_from_gallery_short => 'Εισαγωγή από τη συλλογή';

  @override
  String get refresh => 'Σύρετε προς τα κάτω για ανανέωση';

  @override
  String get last_updated => 'Τελευταία ενημέρωση';

  @override
  String get sort_order => 'Σειρά ταξινόμησης';

  @override
  String get search_documents => 'Αναζήτηση εγγράφων';

  @override
  String get no_documents_yet => 'Κανένα έγγραφο ακόμη';

  @override
  String get no_documents_body =>
      'Σαρώστε την πρώτη σας σελίδα — παίρνει περίπου δύο δευτερόλεπτα και μένει μόνο σε αυτή τη συσκευή.';

  @override
  String get start_scanning => 'Έναρξη σάρωσης';

  @override
  String no_results_for(String query) {
    return 'Κανένα αποτέλεσμα για «$query»';
  }

  @override
  String get refreshing => 'Ανανέωση…';

  @override
  String get exporting => 'Εξαγωγή…';

  @override
  String n_selected(int count) {
    return '$count επιλεγμένα';
  }

  @override
  String get delete_document_q => 'Διαγραφή εγγράφου;';

  @override
  String delete_n_documents_q(int count) {
    return 'Διαγραφή $count εγγράφων;';
  }

  @override
  String get document_deleted => 'Το έγγραφο διαγράφηκε';

  @override
  String n_documents_deleted(int count) {
    return '$count έγγραφα διαγράφηκαν';
  }

  @override
  String saved_n_to_device(int count) {
    return 'Αποθηκεύτηκαν $count στη συσκευή';
  }

  @override
  String couldnt_export_n(int count) {
    return 'Δεν ήταν δυνατή η εξαγωγή $count';
  }

  @override
  String date_and_pages(String date, String pages) {
    return '$date · $pages';
  }

  @override
  String get sort_last_modified => 'Τελευταία τροποποίηση';

  @override
  String get sort_date_created => 'Ημερομηνία δημιουργίας';

  @override
  String get sort_name => 'Όνομα (Α–Ω)';

  @override
  String get sort_page_count => 'Αριθμός σελίδων';

  @override
  String get scanning => 'Σάρωση';

  @override
  String get auto_capture => 'Αυτόματη λήψη';

  @override
  String get auto_capture_desc => 'Λήψη μόλις η σελίδα σταθεροποιηθεί.';

  @override
  String get capture_sound => 'Ήχος λήψης';

  @override
  String get keep_original => 'Διατήρηση αρχικής εικόνας';

  @override
  String get keep_original_desc =>
      'Διατηρεί τη μη περικομμένη φωτογραφία ώστε μια σελίδα να μπορεί να περικοπεί ξανά από την πλήρη λήψη. Περίπου διπλασιάζει τον χώρο που χρησιμοποιεί ένα έγγραφο.';

  @override
  String get avoid_gesture_strip => 'Αποφυγή ζώνης χειρονομίας επιστροφής';

  @override
  String get avoid_gesture_strip_desc =>
      'Κρατά τις γωνίες περικοπής μακριά από την άκρη της οθόνης, όπου ένα σύρσιμο μπορεί να ενεργοποιήσει τη χειρονομία επιστροφής του συστήματος. Κάνει τη σελίδα ελαφρώς στενότερη.';

  @override
  String get default_filter => 'Προεπιλεγμένο φίλτρο';

  @override
  String get appearance => 'Εμφάνιση';

  @override
  String get theme => 'Θέμα';

  @override
  String get language => 'Γλώσσα';

  @override
  String get accent_color => 'Χρώμα τονισμού';

  @override
  String get privacy_storage => 'Απόρρητο και αποθήκευση';

  @override
  String get privacy_body =>
      'Το OpenScan δεν στέλνει ποτέ τα έγγραφά σας πουθενά. Χωρίς λογαριασμούς, χωρίς cloud, χωρίς τηλεμετρία.';

  @override
  String get cache => 'Προσωρινή μνήμη';

  @override
  String get clear_cache_q => 'Εκκαθάριση προσωρινής μνήμης;';

  @override
  String clear_cache_body(String size) {
    return 'Ελευθερώνει $size δεδομένων μικρογραφιών. Τα έγγραφά σας δεν επηρεάζονται.';
  }

  @override
  String cache_clear_action(String size) {
    return '$size · Εκκαθάριση';
  }

  @override
  String get cache_cleared => 'Η προσωρινή μνήμη εκκαθαρίστηκε';

  @override
  String get couldnt_clear_cache =>
      'Δεν ήταν δυνατή η εκκαθάριση της προσωρινής μνήμης';

  @override
  String get theme_system => 'Σύστημα';

  @override
  String get theme_light => 'Φωτεινό';

  @override
  String get theme_dark => 'Σκοτεινό';

  @override
  String get filters => 'Φίλτρα';

  @override
  String get filter_original => 'Αρχικό';

  @override
  String get filter_auto => 'Αυτόματο';

  @override
  String get filter_lighten => 'Φωτεινότερο';

  @override
  String get filter_grayscale => 'Κλίμακα του γκρι';

  @override
  String get filter_bw => 'Α&Μ';

  @override
  String get filter_whiteboard => 'Πίνακας';

  @override
  String get filter_action => 'Φίλτρο';

  @override
  String get apply_to_all_pages => 'Εφαρμογή σε όλες τις σελίδες';

  @override
  String apply_to_all_n_pages(int count) {
    return 'Εφαρμογή σε όλες τις $count σελίδες';
  }

  @override
  String get adjust_edges => 'Προσαρμογή άκρων';

  @override
  String get automatic_crop => 'Αυτόματη περικοπή';

  @override
  String get no_crop => 'Χωρίς περικοπή';

  @override
  String get rescan => 'Επανασάρωση';

  @override
  String get couldnt_crop =>
      'Δεν ήταν δυνατή η περικοπή της εικόνας — δοκιμάστε ξανά.';

  @override
  String get looking_for_document => 'Αναζήτηση εγγράφου…';

  @override
  String get document_detected => 'Εντοπίστηκε έγγραφο';

  @override
  String get hold_still => 'ΜΕΙΝΕΤΕ ΑΚΙΝΗΤΟΙ…';

  @override
  String get auto_on => 'ΑΥΤΟΜΑΤΟ · ΕΝΕΡΓΟ';

  @override
  String get auto_off => 'ΑΥΤΟΜΑΤΟ · ΑΝΕΝΕΡΓΟ';

  @override
  String get low_light =>
      'Χαμηλός φωτισμός — κρατήστε σταθερά ή ανάψτε τον φακό';

  @override
  String get torch_on => 'Φακός ενεργός';

  @override
  String get torch_off => 'Φακός ανενεργός';

  @override
  String get torch_unavailable =>
      'Ο φακός δεν είναι διαθέσιμος σε αυτή τη συσκευή.';

  @override
  String get auto_capture_on => 'Αυτόματη λήψη ενεργή';

  @override
  String get auto_capture_off => 'Αυτόματη λήψη ανενεργή';

  @override
  String get undo_last_capture => 'Αναίρεση τελευταίας λήψης';

  @override
  String get composition_grid => 'Πλέγμα σύνθεσης';

  @override
  String get switch_camera => 'Εναλλαγή κάμερας';

  @override
  String get couldnt_capture => 'Δεν ήταν δυνατή η λήψη — δοκιμάστε ξανά.';

  @override
  String get couldnt_open_gallery => 'Δεν ήταν δυνατό το άνοιγμα της συλλογής.';

  @override
  String get couldnt_start_camera =>
      'Δεν ήταν δυνατή η εκκίνηση της κάμερας — επιστρέψτε και δοκιμάστε ξανά.';

  @override
  String get camera_access_needed => 'Απαιτείται πρόσβαση στην κάμερα';

  @override
  String get camera_access_body =>
      'Το OpenScan χρησιμοποιεί την κάμερά σας μόνο για σάρωση σελίδων — τίποτα δεν φεύγει από τη συσκευή σας. Ενεργοποιήστε την στις Ρυθμίσεις για να συνεχίσετε.';

  @override
  String done_count(int count) {
    return 'Τέλος · $count';
  }

  @override
  String get delete_document => 'Διαγραφή εγγράφου';

  @override
  String get delete_document_body =>
      'Κάθε σελίδα διαγράφεται μαζί του. Αυτό δεν μπορεί να αναιρεθεί.';

  @override
  String get delete_page_q => 'Διαγραφή σελίδας;';

  @override
  String delete_n_pages_q(int count) {
    return 'Διαγραφή $count σελίδων;';
  }

  @override
  String get no_pages_title => 'Αυτό το έγγραφο δεν έχει σελίδες';

  @override
  String get no_pages_body =>
      'Ονομάζεται από την πρώτη σας σελίδα — μετονομάστε το ανά πάσα στιγμή πατώντας τον τίτλο.';

  @override
  String get continue_scanning => 'Συνέχεια σάρωσης';

  @override
  String get add_pages => 'Προσθήκη σελίδων';

  @override
  String get export_selected => 'Εξαγωγή επιλεγμένων';

  @override
  String export_n_selected(int count) {
    return 'Εξαγωγή $count επιλεγμένων';
  }

  @override
  String skipped_files(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Παραλείφθηκαν $count αρχεία που δεν μπορεί να διαβάσει η εφαρμογή.',
      one: 'Παραλείφθηκε 1 αρχείο που δεν μπορεί να διαβάσει η εφαρμογή.',
    );
    return '$_temp0';
  }

  @override
  String hold_to_reorder(String pages) {
    return '$pages · κρατήστε πατημένη μια σελίδα για αναδιάταξη';
  }

  @override
  String export_title(String name) {
    return 'Εξαγωγή · $name';
  }

  @override
  String get quality_caps => 'ΠΟΙΟΤΗΤΑ';

  @override
  String get page_size => 'Μέγεθος σελίδας';

  @override
  String get all_pages => 'Όλες οι σελίδες';

  @override
  String get selected_pages => 'Επιλεγμένες σελίδες';

  @override
  String page_x_of_y(int current, int total) {
    return 'Σελίδα $current από $total';
  }

  @override
  String get exported => 'Εξήχθη';

  @override
  String get export_failed => 'Η εξαγωγή απέτυχε';

  @override
  String get no_pages_to_export => 'Δεν υπάρχουν σελίδες για εξαγωγή.';

  @override
  String get pdf_not_written => 'Δεν ήταν δυνατή η εγγραφή του PDF';

  @override
  String get not_enough_storage =>
      'Δεν υπάρχει αρκετός αποθηκευτικός χώρος σε αυτή τη συσκευή.';

  @override
  String get export_went_wrong => 'Κάτι πήγε στραβά κατά την εξαγωγή.';

  @override
  String couldnt_open_file(String message) {
    return 'Δεν ήταν δυνατό το άνοιγμα του αρχείου: $message';
  }

  @override
  String get no_app_opens_file =>
      'Καμία εφαρμογή σε αυτό το τηλέφωνο δεν ανοίγει αυτόν τον τύπο αρχείου';

  @override
  String get quality_ultra_low => 'Πολύ χαμηλή';

  @override
  String get quality_low => 'Χαμηλή';

  @override
  String get quality_medium => 'Μεσαία';

  @override
  String get quality_high => 'Υψηλή';

  @override
  String result_and_more(String name, int count) {
    return '$name + $count ακόμη';
  }

  @override
  String get rename_file => 'Μετονομασία αρχείου';

  @override
  String get file_name_empty => 'Το όνομα αρχείου δεν μπορεί να είναι κενό';

  @override
  String get special_chars_not_allowed => 'Δεν επιτρέπονται ειδικοί χαρακτήρες';

  @override
  String get save_to_device => 'Αποθήκευση στη συσκευή';

  @override
  String get share_pdf => 'Κοινοποίηση PDF';

  @override
  String get share_images => 'Κοινοποίηση εικόνων';

  @override
  String get demo_detect_title => 'Στοχεύστε, και σαρώθηκε';

  @override
  String get demo_detect_body =>
      'Το OpenScan βρίσκει τις άκρες της σελίδας και κάνει λήψη αυτόματα — χωρίς πάτημα κλείστρου.';

  @override
  String get demo_private_title => 'Όλα μένουν στο τηλέφωνό σας';

  @override
  String get demo_private_body =>
      'Χωρίς λογαριασμούς, χωρίς μεταφορτώσεις στο cloud, χωρίς διαφημίσεις, χωρίς παρακολούθηση — ποτέ.';

  @override
  String get demo_camera_title => 'Ένα τελευταίο πράγμα';

  @override
  String get demo_camera_body =>
      'Το OpenScan χρειάζεται την κάμερά σας για να σαρώνει σελίδες. Αυτό είναι το μόνο για το οποίο χρησιμοποιείται.';

  @override
  String get allow_camera_access => 'Να επιτραπεί η πρόσβαση στην κάμερα';

  @override
  String get app_description =>
      'είναι μια εφαρμογή ανοιχτού κώδικα που επιτρέπει στους χρήστες να σαρώνουν έντυπα έγγραφα και να τα μετατρέπουν σε αρχείο PDF.';

  @override
  String get app_description_2 =>
      'Χωρίς διαφημίσεις. Δεν συλλέγουμε δεδομένα.\n Σεβόμαστε το απόρρητό σας.';

  @override
  String get open_source_github => 'Ανοιχτός κώδικας στο GitHub';

  @override
  String get couldnt_launch_url => 'Δεν ήταν δυνατό το άνοιγμα του συνδέσμου';
}
