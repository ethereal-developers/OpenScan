// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get about => 'Névjegy';

  @override
  String get cancel => 'Mégse';

  @override
  String get save => 'Mentés';

  @override
  String get open => 'Megnyitás';

  @override
  String get share => 'Megosztás';

  @override
  String get export => 'Exportálás';

  @override
  String get clear => 'Törlés';

  @override
  String get delete => 'Törlés';

  @override
  String get rename => 'Átnevezés';

  @override
  String get crop => 'Vágás';

  @override
  String get done => 'Kész';

  @override
  String get next => 'Tovább';

  @override
  String get skip => 'Kihagyás';

  @override
  String get loading => 'Betöltés';

  @override
  String get home => 'Kezdőlap';

  @override
  String get demo => 'Bemutató';

  @override
  String get quality => 'Minőség';

  @override
  String get version => 'Verzió';

  @override
  String get select => 'Kijelölés';

  @override
  String get select_all => 'Összes kijelölése';

  @override
  String get select_pages => 'Oldalak kijelölése';

  @override
  String get try_again => 'Próbálja újra';

  @override
  String get undo => 'VISSZAVONÁS';

  @override
  String get not_now => 'Most nem';

  @override
  String get open_settings => 'Beállítások megnyitása';

  @override
  String get more => 'Több';

  @override
  String get sort => 'Rendezés';

  @override
  String get settings => 'Beállítások';

  @override
  String get tutorial => 'Útmutató';

  @override
  String get library => 'Könyvtár';

  @override
  String get scan => 'Szkennelés';

  @override
  String get image => 'kép';

  @override
  String get images => 'képek';

  @override
  String get developers => 'Fejlesztők';

  @override
  String get tutorial_title => 'Hogyan használható az alkalmazás?';

  @override
  String get cant_be_undone => 'Ezt nem lehet visszavonni.';

  @override
  String get rotate => 'Forgatás';

  @override
  String get rotate_left => 'Forgatás balra';

  @override
  String get rotate_right => 'Forgatás jobbra';

  @override
  String pages_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oldal',
      one: '1 oldal',
    );
    return '$_temp0';
  }

  @override
  String get scan_options => 'Szkennelési beállítások';

  @override
  String get live_scan => 'Élő szkennelés';

  @override
  String get import_from_gallery => 'Importálás a galériából';

  @override
  String get import_from_gallery_short => 'Importálás a galériából';

  @override
  String get refresh => 'Húzza le a frissítéshez';

  @override
  String get last_updated => 'Utoljára frissítve';

  @override
  String get sort_order => 'Rendezési sorrend';

  @override
  String get search_documents => 'Dokumentumok keresése';

  @override
  String get no_documents_yet => 'Még nincs dokumentum';

  @override
  String get no_documents_body =>
      'Szkennelje be az első oldalt — körülbelül két másodperc, és csak ezen az eszközön marad.';

  @override
  String get start_scanning => 'Szkennelés indítása';

  @override
  String no_results_for(String query) {
    return 'Nincs találat erre: „$query”';
  }

  @override
  String get refreshing => 'Frissítés…';

  @override
  String get exporting => 'Exportálás…';

  @override
  String n_selected(int count) {
    return '$count kijelölve';
  }

  @override
  String get delete_document_q => 'Törli a dokumentumot?';

  @override
  String delete_n_documents_q(int count) {
    return 'Törli a(z) $count dokumentumot?';
  }

  @override
  String get document_deleted => 'Dokumentum törölve';

  @override
  String n_documents_deleted(int count) {
    return '$count dokumentum törölve';
  }

  @override
  String saved_n_to_device(int count) {
    return '$count mentve az eszközre';
  }

  @override
  String couldnt_export_n(int count) {
    return '$count exportálása nem sikerült';
  }

  @override
  String date_and_pages(String date, String pages) {
    return '$date · $pages';
  }

  @override
  String get sort_last_modified => 'Utoljára módosítva';

  @override
  String get sort_date_created => 'Létrehozás dátuma';

  @override
  String get sort_name => 'Név (A–Z)';

  @override
  String get sort_page_count => 'Oldalszám';

  @override
  String get scanning => 'Szkennelés';

  @override
  String get auto_capture => 'Automatikus rögzítés';

  @override
  String get auto_capture_desc => 'Rögzítés, amint az oldal megáll.';

  @override
  String get capture_sound => 'Rögzítés hangja';

  @override
  String get keep_original => 'Eredeti kép megtartása';

  @override
  String get keep_original_desc =>
      'Megtartja a vágatlan fényképet, hogy egy oldal újravágható legyen a teljes felvételből. Nagyjából megduplázza a dokumentum helyigényét.';

  @override
  String get avoid_gesture_strip => 'Vissza-gesztus sáv elkerülése';

  @override
  String get avoid_gesture_strip_desc =>
      'A vágósarkokat távol tartja a képernyő szélétől, ahol a húzás a rendszer vissza-gesztusát indíthatja el. Az oldal így kissé keskenyebb lesz.';

  @override
  String get default_filter => 'Alapértelmezett szűrő';

  @override
  String get appearance => 'Megjelenés';

  @override
  String get theme => 'Téma';

  @override
  String get language => 'Nyelv';

  @override
  String get accent_color => 'Kiemelő szín';

  @override
  String get privacy_storage => 'Adatvédelem és tárolás';

  @override
  String get privacy_body =>
      'Az OpenScan soha nem küldi el a dokumentumait sehová. Nincs fiók, nincs felhő, nincs telemetria.';

  @override
  String get cache => 'Gyorsítótár';

  @override
  String get clear_cache_q => 'Törli a gyorsítótárat?';

  @override
  String clear_cache_body(String size) {
    return '$size bélyegkép-adatot szabadít fel. A dokumentumait ez nem érinti.';
  }

  @override
  String cache_clear_action(String size) {
    return '$size · Törlés';
  }

  @override
  String get cache_cleared => 'Gyorsítótár törölve';

  @override
  String get couldnt_clear_cache => 'A gyorsítótár törlése nem sikerült';

  @override
  String get theme_system => 'Rendszer';

  @override
  String get theme_light => 'Világos';

  @override
  String get theme_dark => 'Sötét';

  @override
  String get filters => 'Szűrők';

  @override
  String get filter_original => 'Eredeti';

  @override
  String get filter_auto => 'Automatikus';

  @override
  String get filter_lighten => 'Világosítás';

  @override
  String get filter_grayscale => 'Szürkeárnyalatos';

  @override
  String get filter_bw => 'F&F';

  @override
  String get filter_whiteboard => 'Tábla';

  @override
  String get filter_action => 'Szűrő';

  @override
  String get apply_to_all_pages => 'Alkalmazás minden oldalra';

  @override
  String apply_to_all_n_pages(int count) {
    return 'Alkalmazás mind a(z) $count oldalra';
  }

  @override
  String get adjust_edges => 'Élek beállítása';

  @override
  String get automatic_crop => 'Automatikus vágás';

  @override
  String get no_crop => 'Nincs vágás';

  @override
  String get rescan => 'Újraszkennelés';

  @override
  String get couldnt_crop => 'A kép vágása nem sikerült — próbálja újra.';

  @override
  String get looking_for_document => 'Dokumentum keresése…';

  @override
  String get document_detected => 'Dokumentum észlelve';

  @override
  String get hold_still => 'TARTSA MOZDULATLANUL…';

  @override
  String get auto_on => 'AUTO · BE';

  @override
  String get auto_off => 'AUTO · KI';

  @override
  String get low_light =>
      'Gyenge fény — tartsa stabilan vagy kapcsolja be a vakut';

  @override
  String get torch_on => 'Lámpa be';

  @override
  String get torch_off => 'Lámpa ki';

  @override
  String get torch_unavailable => 'A lámpa nem érhető el ezen az eszközön.';

  @override
  String get auto_capture_on => 'Automatikus rögzítés be';

  @override
  String get auto_capture_off => 'Automatikus rögzítés ki';

  @override
  String get undo_last_capture => 'Utolsó rögzítés visszavonása';

  @override
  String get composition_grid => 'Kompozíciós rács';

  @override
  String get switch_camera => 'Kamera váltása';

  @override
  String get couldnt_capture => 'A rögzítés nem sikerült — próbálja újra.';

  @override
  String get couldnt_open_gallery => 'A galéria megnyitása nem sikerült.';

  @override
  String get couldnt_start_camera =>
      'A kamera indítása nem sikerült — lépjen vissza és próbálja újra.';

  @override
  String get camera_access_needed => 'Kamera-hozzáférés szükséges';

  @override
  String get camera_access_body =>
      'Az OpenScan csak oldalak szkennelésére használja a kamerát — semmi sem hagyja el az eszközt. A folytatáshoz kapcsolja be a Beállításokban.';

  @override
  String done_count(int count) {
    return 'Kész · $count';
  }

  @override
  String get delete_document => 'Dokumentum törlése';

  @override
  String get delete_document_body =>
      'Minden oldala vele együtt törlődik. Ezt nem lehet visszavonni.';

  @override
  String get delete_page_q => 'Törli az oldalt?';

  @override
  String delete_n_pages_q(int count) {
    return 'Törli a(z) $count oldalt?';
  }

  @override
  String get no_pages_title => 'Ennek a dokumentumnak nincsenek oldalai';

  @override
  String get no_pages_body =>
      'Az első oldala alapján kapta a nevét — bármikor átnevezheti a címre koppintva.';

  @override
  String get continue_scanning => 'Szkennelés folytatása';

  @override
  String get add_pages => 'Oldalak hozzáadása';

  @override
  String get export_selected => 'Kijelöltek exportálása';

  @override
  String export_n_selected(int count) {
    return '$count kijelölt exportálása';
  }

  @override
  String skipped_files(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fájl kihagyva, amelyeket az alkalmazás nem tud olvasni.',
      one: '1 fájl kihagyva, amelyet az alkalmazás nem tud olvasni.',
    );
    return '$_temp0';
  }

  @override
  String hold_to_reorder(String pages) {
    return '$pages · tartson nyomva egy oldalt az átrendezéshez';
  }

  @override
  String export_title(String name) {
    return 'Exportálás · $name';
  }

  @override
  String get quality_caps => 'MINŐSÉG';

  @override
  String get page_size => 'Oldalméret';

  @override
  String get all_pages => 'Minden oldal';

  @override
  String get selected_pages => 'Kijelölt oldalak';

  @override
  String page_x_of_y(int current, int total) {
    return '$total oldalból a(z) $current.';
  }

  @override
  String get exported => 'Exportálva';

  @override
  String get export_failed => 'Az exportálás sikertelen';

  @override
  String get no_pages_to_export => 'Nincsenek exportálható oldalak.';

  @override
  String get pdf_not_written => 'A PDF-et nem sikerült megírni';

  @override
  String get not_enough_storage => 'Nincs elég tárhely ezen az eszközön.';

  @override
  String get export_went_wrong => 'Valami hiba történt az exportálás során.';

  @override
  String couldnt_open_file(String message) {
    return 'A fájl megnyitása nem sikerült: $message';
  }

  @override
  String get no_app_opens_file =>
      'Ezen a telefonon egyetlen alkalmazás sem nyitja meg ezt a fájltípust';

  @override
  String get quality_ultra_low => 'Nagyon alacsony';

  @override
  String get quality_low => 'Alacsony';

  @override
  String get quality_medium => 'Közepes';

  @override
  String get quality_high => 'Magas';

  @override
  String result_and_more(String name, int count) {
    return '$name + $count további';
  }

  @override
  String get rename_file => 'Fájl átnevezése';

  @override
  String get file_name_empty => 'A fájlnév nem lehet üres';

  @override
  String get special_chars_not_allowed =>
      'Speciális karakterek nem engedélyezettek';

  @override
  String get save_to_device => 'Mentés az eszközre';

  @override
  String get share_pdf => 'PDF megosztása';

  @override
  String get share_images => 'Képek megosztása';

  @override
  String get demo_detect_title => 'Irányítsa rá, és be van szkennelve';

  @override
  String get demo_detect_body =>
      'Az OpenScan megtalálja az oldal éleit, és automatikusan rögzít — nem kell exponálógombot nyomni.';

  @override
  String get demo_private_title => 'Minden a telefonján marad';

  @override
  String get demo_private_body =>
      'Nincs fiók, nincs felhőfeltöltés, nincs hirdetés, nincs követés — soha.';

  @override
  String get demo_camera_title => 'Még egy dolog';

  @override
  String get demo_camera_body =>
      'Az OpenScannek szüksége van a kamerájára az oldalak szkenneléséhez. Csak erre használja.';

  @override
  String get allow_camera_access => 'Kamera-hozzáférés engedélyezése';

  @override
  String get app_description =>
      'egy nyílt forráskódú alkalmazás, amely lehetővé teszi a papíralapú dokumentumok beszkennelését és PDF-fájllá alakítását.';

  @override
  String get app_description_2 =>
      'Nincsenek hirdetések. Nem gyűjtünk adatokat.\n Tiszteletben tartjuk a magánszféráját.';

  @override
  String get open_source_github => 'Nyílt forráskód a GitHubon';

  @override
  String get couldnt_launch_url => 'A hivatkozás megnyitása nem sikerült';
}
