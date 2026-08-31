// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get about => 'O aplikacji';

  @override
  String get cancel => 'Anuluj';

  @override
  String get save => 'Zapisz';

  @override
  String get open => 'Otwórz';

  @override
  String get share => 'Udostępnij';

  @override
  String get export => 'Eksportuj';

  @override
  String get clear => 'Wyczyść';

  @override
  String get delete => 'Usuń';

  @override
  String get rename => 'Zmień nazwę';

  @override
  String get crop => 'Przytnij';

  @override
  String get done => 'Gotowe';

  @override
  String get next => 'Dalej';

  @override
  String get skip => 'Pomiń';

  @override
  String get loading => 'Ładowanie';

  @override
  String get home => 'Ekran główny';

  @override
  String get demo => 'Pokaz';

  @override
  String get quality => 'Jakość';

  @override
  String get version => 'Wersja';

  @override
  String get select => 'Zaznacz';

  @override
  String get select_all => 'Zaznacz wszystko';

  @override
  String get select_pages => 'Zaznacz strony';

  @override
  String get try_again => 'Spróbuj ponownie';

  @override
  String get undo => 'COFNIJ';

  @override
  String get not_now => 'Nie teraz';

  @override
  String get open_settings => 'Otwórz ustawienia';

  @override
  String get more => 'Więcej';

  @override
  String get sort => 'Sortuj';

  @override
  String get settings => 'Ustawienia';

  @override
  String get tutorial => 'Samouczek';

  @override
  String get library => 'Biblioteka';

  @override
  String get scan => 'Skanuj';

  @override
  String get image => 'obraz';

  @override
  String get images => 'obrazy';

  @override
  String get developers => 'Twórcy';

  @override
  String get tutorial_title => 'Jak korzystać z aplikacji?';

  @override
  String get cant_be_undone => 'Tej operacji nie można cofnąć.';

  @override
  String get rotate => 'Obróć';

  @override
  String get rotate_left => 'Obróć w lewo';

  @override
  String get rotate_right => 'Obróć w prawo';

  @override
  String pages_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count strony',
      many: '$count stron',
      few: '$count strony',
      one: '1 strona',
    );
    return '$_temp0';
  }

  @override
  String get scan_options => 'Opcje skanowania';

  @override
  String get live_scan => 'Skanowanie na żywo';

  @override
  String get import_from_gallery => 'Importuj z galerii';

  @override
  String get import_from_gallery_short => 'Importuj z galerii';

  @override
  String get refresh => 'Przeciągnij w dół, aby odświeżyć';

  @override
  String get last_updated => 'Ostatnia aktualizacja';

  @override
  String get sort_order => 'Kolejność sortowania';

  @override
  String get search_documents => 'Szukaj dokumentów';

  @override
  String get no_documents_yet => 'Brak dokumentów';

  @override
  String get no_documents_body =>
      'Zeskanuj pierwszą stronę — zajmie to około dwóch sekund i pozostanie tylko na tym urządzeniu.';

  @override
  String get start_scanning => 'Rozpocznij skanowanie';

  @override
  String no_results_for(String query) {
    return 'Brak wyników dla „$query”';
  }

  @override
  String get refreshing => 'Odświeżanie…';

  @override
  String get exporting => 'Eksportowanie…';

  @override
  String n_selected(int count) {
    return 'Zaznaczono: $count';
  }

  @override
  String get delete_document_q => 'Usunąć dokument?';

  @override
  String delete_n_documents_q(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usunąć $count dokumentu?',
      many: 'Usunąć $count dokumentów?',
      few: 'Usunąć $count dokumenty?',
    );
    return '$_temp0';
  }

  @override
  String get document_deleted => 'Dokument usunięty';

  @override
  String n_documents_deleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usunięto $count dokumentu',
      many: 'Usunięto $count dokumentów',
      few: 'Usunięto $count dokumenty',
    );
    return '$_temp0';
  }

  @override
  String saved_n_to_device(int count) {
    return 'Zapisano $count na urządzeniu';
  }

  @override
  String couldnt_export_n(int count) {
    return 'Nie udało się wyeksportować: $count';
  }

  @override
  String date_and_pages(String date, String pages) {
    return '$date · $pages';
  }

  @override
  String get sort_last_modified => 'Ostatnia modyfikacja';

  @override
  String get sort_date_created => 'Data utworzenia';

  @override
  String get sort_name => 'Nazwa (A–Z)';

  @override
  String get sort_page_count => 'Liczba stron';

  @override
  String get scanning => 'Skanowanie';

  @override
  String get auto_capture => 'Automatyczne zdjęcie';

  @override
  String get auto_capture_desc =>
      'Zrób zdjęcie, gdy tylko strona się ustabilizuje.';

  @override
  String get capture_sound => 'Dźwięk migawki';

  @override
  String get keep_original => 'Zachowaj oryginalny obraz';

  @override
  String get keep_original_desc =>
      'Zachowuje nieprzycięte zdjęcie, aby stronę można było przyciąć ponownie z pełnego ujęcia. Mniej więcej podwaja miejsce zajmowane przez dokument.';

  @override
  String get avoid_gesture_strip => 'Unikaj paska gestu wstecz';

  @override
  String get avoid_gesture_strip_desc =>
      'Utrzymuje narożniki przycinania z dala od krawędzi ekranu, gdzie przeciągnięcie może wywołać systemowy gest wstecz. Strona będzie nieco węższa.';

  @override
  String get default_filter => 'Domyślny filtr';

  @override
  String get appearance => 'Wygląd';

  @override
  String get theme => 'Motyw';

  @override
  String get language => 'Język';

  @override
  String get accent_color => 'Kolor akcentu';

  @override
  String get privacy_storage => 'Prywatność i pamięć';

  @override
  String get privacy_body =>
      'OpenScan nigdy nigdzie nie wysyła Twoich dokumentów. Bez kont, bez chmury, bez telemetrii.';

  @override
  String get cache => 'Pamięć podręczna';

  @override
  String get clear_cache_q => 'Wyczyścić pamięć podręczną?';

  @override
  String clear_cache_body(String size) {
    return 'Zwolni $size danych miniatur. Twoje dokumenty pozostaną nienaruszone.';
  }

  @override
  String cache_clear_action(String size) {
    return '$size · Wyczyść';
  }

  @override
  String get cache_cleared => 'Pamięć podręczna wyczyszczona';

  @override
  String get couldnt_clear_cache =>
      'Nie udało się wyczyścić pamięci podręcznej';

  @override
  String get theme_system => 'Systemowy';

  @override
  String get theme_light => 'Jasny';

  @override
  String get theme_dark => 'Ciemny';

  @override
  String get filters => 'Filtry';

  @override
  String get filter_original => 'Oryginał';

  @override
  String get filter_auto => 'Automatyczny';

  @override
  String get filter_lighten => 'Rozjaśnienie';

  @override
  String get filter_grayscale => 'Odcienie szarości';

  @override
  String get filter_bw => 'Cz-b';

  @override
  String get filter_whiteboard => 'Tablica';

  @override
  String get filter_action => 'Filtr';

  @override
  String get apply_to_all_pages => 'Zastosuj do wszystkich stron';

  @override
  String apply_to_all_n_pages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zastosuj do wszystkich $count stron',
      many: 'Zastosuj do wszystkich $count stron',
      few: 'Zastosuj do wszystkich $count stron',
    );
    return '$_temp0';
  }

  @override
  String get adjust_edges => 'Dopasuj krawędzie';

  @override
  String get automatic_crop => 'Automatyczne przycięcie';

  @override
  String get no_crop => 'Bez przycinania';

  @override
  String get rescan => 'Skanuj ponownie';

  @override
  String get couldnt_crop =>
      'Nie udało się przyciąć obrazu — spróbuj ponownie.';

  @override
  String get looking_for_document => 'Szukanie dokumentu…';

  @override
  String get document_detected => 'Wykryto dokument';

  @override
  String get hold_still => 'NIE PORUSZAJ…';

  @override
  String get auto_on => 'AUTO · WŁ.';

  @override
  String get auto_off => 'AUTO · WYŁ.';

  @override
  String get low_light => 'Słabe światło — trzymaj stabilnie lub włącz latarkę';

  @override
  String get torch_on => 'Latarka włączona';

  @override
  String get torch_off => 'Latarka wyłączona';

  @override
  String get torch_unavailable =>
      'Latarka nie jest dostępna na tym urządzeniu.';

  @override
  String get auto_capture_on => 'Automatyczne zdjęcie włączone';

  @override
  String get auto_capture_off => 'Automatyczne zdjęcie wyłączone';

  @override
  String get undo_last_capture => 'Cofnij ostatnie zdjęcie';

  @override
  String get composition_grid => 'Siatka kompozycji';

  @override
  String get switch_camera => 'Przełącz aparat';

  @override
  String get couldnt_capture =>
      'Nie udało się zrobić zdjęcia — spróbuj ponownie.';

  @override
  String get couldnt_open_gallery => 'Nie udało się otworzyć galerii.';

  @override
  String get couldnt_start_camera =>
      'Nie udało się uruchomić aparatu — wróć i spróbuj ponownie.';

  @override
  String get camera_access_needed => 'Wymagany dostęp do aparatu';

  @override
  String get camera_access_body =>
      'OpenScan używa aparatu wyłącznie do skanowania stron — nic nie opuszcza Twojego urządzenia. Włącz dostęp w Ustawieniach, aby kontynuować.';

  @override
  String done_count(int count) {
    return 'Gotowe · $count';
  }

  @override
  String get delete_document => 'Usuń dokument';

  @override
  String get delete_document_body =>
      'Wszystkie jego strony zostaną usunięte. Tej operacji nie można cofnąć.';

  @override
  String get delete_page_q => 'Usunąć stronę?';

  @override
  String delete_n_pages_q(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usunąć $count strony?',
      many: 'Usunąć $count stron?',
      few: 'Usunąć $count strony?',
    );
    return '$_temp0';
  }

  @override
  String get no_pages_title => 'Ten dokument nie ma stron';

  @override
  String get no_pages_body =>
      'Nazwany według pierwszej strony — możesz zmienić nazwę w każdej chwili, dotykając tytułu.';

  @override
  String get continue_scanning => 'Kontynuuj skanowanie';

  @override
  String get add_pages => 'Dodaj strony';

  @override
  String get export_selected => 'Eksportuj zaznaczone';

  @override
  String export_n_selected(int count) {
    return 'Eksportuj zaznaczone: $count';
  }

  @override
  String skipped_files(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pominięto $count pliku, którego aplikacja nie może odczytać.',
      many: 'Pominięto $count plików, których aplikacja nie może odczytać.',
      few: 'Pominięto $count pliki, których aplikacja nie może odczytać.',
      one: 'Pominięto 1 plik, którego aplikacja nie może odczytać.',
    );
    return '$_temp0';
  }

  @override
  String hold_to_reorder(String pages) {
    return '$pages · przytrzymaj stronę, aby zmienić kolejność';
  }

  @override
  String export_title(String name) {
    return 'Eksport · $name';
  }

  @override
  String get quality_caps => 'JAKOŚĆ';

  @override
  String get page_size => 'Rozmiar strony';

  @override
  String get all_pages => 'Wszystkie strony';

  @override
  String get selected_pages => 'Zaznaczone strony';

  @override
  String page_x_of_y(int current, int total) {
    return 'Strona $current z $total';
  }

  @override
  String get exported => 'Wyeksportowano';

  @override
  String get export_failed => 'Eksport nie powiódł się';

  @override
  String get no_pages_to_export => 'Brak stron do wyeksportowania.';

  @override
  String get pdf_not_written => 'Nie udało się zapisać pliku PDF';

  @override
  String get not_enough_storage => 'Za mało miejsca na tym urządzeniu.';

  @override
  String get export_went_wrong => 'Coś poszło nie tak podczas eksportu.';

  @override
  String couldnt_open_file(String message) {
    return 'Nie udało się otworzyć pliku: $message';
  }

  @override
  String get no_app_opens_file =>
      'Żadna aplikacja na tym telefonie nie otwiera tego typu pliku';

  @override
  String get quality_ultra_low => 'Bardzo niska';

  @override
  String get quality_low => 'Niska';

  @override
  String get quality_medium => 'Średnia';

  @override
  String get quality_high => 'Wysoka';

  @override
  String result_and_more(String name, int count) {
    return '$name + $count więcej';
  }

  @override
  String get rename_file => 'Zmień nazwę pliku';

  @override
  String get file_name_empty => 'Nazwa pliku nie może być pusta';

  @override
  String get special_chars_not_allowed => 'Znaki specjalne są niedozwolone';

  @override
  String get save_to_device => 'Zapisz na urządzeniu';

  @override
  String get share_pdf => 'Udostępnij PDF';

  @override
  String get share_images => 'Udostępnij obrazy';

  @override
  String get demo_detect_title => 'Wyceluj, a strona jest zeskanowana';

  @override
  String get demo_detect_body =>
      'OpenScan znajduje krawędzie strony i robi zdjęcie automatycznie — bez naciskania migawki.';

  @override
  String get demo_private_title => 'Wszystko zostaje na Twoim telefonie';

  @override
  String get demo_private_body =>
      'Bez kont, bez przesyłania do chmury, bez reklam, bez śledzenia — nigdy.';

  @override
  String get demo_camera_title => 'Jeszcze jedno';

  @override
  String get demo_camera_body =>
      'OpenScan potrzebuje aparatu do skanowania stron. Do niczego innego go nie używa.';

  @override
  String get allow_camera_access => 'Zezwól na dostęp do aparatu';

  @override
  String get app_description =>
      'to aplikacja o otwartym kodzie źródłowym, która umożliwia skanowanie papierowych dokumentów i przekształcanie ich w plik PDF.';

  @override
  String get app_description_2 =>
      'Bez reklam. Nie zbieramy żadnych danych.\n Szanujemy Twoją prywatność.';

  @override
  String get open_source_github => 'Otwarty kod na GitHubie';

  @override
  String get couldnt_launch_url => 'Nie udało się otworzyć adresu URL';
}
