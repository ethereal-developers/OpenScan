// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get about => 'Acerca de';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get open => 'Abrir';

  @override
  String get share => 'Compartir';

  @override
  String get export => 'Exportar';

  @override
  String get clear => 'Borrar';

  @override
  String get delete => 'Eliminar';

  @override
  String get rename => 'Cambiar nombre';

  @override
  String get crop => 'Recortar';

  @override
  String get done => 'Listo';

  @override
  String get next => 'Siguiente';

  @override
  String get skip => 'Omitir';

  @override
  String get loading => 'Cargando';

  @override
  String get home => 'Inicio';

  @override
  String get demo => 'Demostración';

  @override
  String get quality => 'Calidad';

  @override
  String get version => 'Versión';

  @override
  String get select => 'Seleccionar';

  @override
  String get select_all => 'Seleccionar todo';

  @override
  String get select_pages => 'Seleccionar páginas';

  @override
  String get reorder_pages => 'Reordenar páginas';

  @override
  String get try_again => 'Reintentar';

  @override
  String get undo => 'DESHACER';

  @override
  String get not_now => 'Ahora no';

  @override
  String get open_settings => 'Abrir Ajustes';

  @override
  String get more => 'Más';

  @override
  String get sort => 'Ordenar';

  @override
  String get settings => 'Ajustes';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get library => 'Biblioteca';

  @override
  String get scan => 'Escanear';

  @override
  String get image => 'imagen';

  @override
  String get images => 'imágenes';

  @override
  String get developers => 'Desarrolladores';

  @override
  String get view_on_linkedin => 'Ver en LinkedIn';

  @override
  String get tutorial_title => '¿Cómo se usa la app?';

  @override
  String get cant_be_undone => 'Esta acción no se puede deshacer.';

  @override
  String get rotate => 'Girar';

  @override
  String get rotate_left => 'Girar a la izquierda';

  @override
  String get rotate_right => 'Girar a la derecha';

  @override
  String pages_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return '$_temp0';
  }

  @override
  String get scan_options => 'Opciones de escaneo';

  @override
  String get live_scan => 'Escaneo en vivo';

  @override
  String get import_from_gallery => 'Importar de la Galería';

  @override
  String get import_from_gallery_short => 'Importar de la galería';

  @override
  String get refresh => 'Desliza hacia abajo para actualizar';

  @override
  String get last_updated => 'Última actualización';

  @override
  String get sort_order => 'Orden';

  @override
  String get search_documents => 'Buscar documentos';

  @override
  String get no_documents_yet => 'Aún no hay documentos';

  @override
  String get no_documents_body =>
      'Escanea tu primera página: tarda unos dos segundos y se queda solo en este dispositivo.';

  @override
  String get start_scanning => 'Empezar a escanear';

  @override
  String no_results_for(String query) {
    return 'No hay resultados para \"$query\"';
  }

  @override
  String get refreshing => 'Actualizando…';

  @override
  String get exporting => 'Exportando…';

  @override
  String n_selected(int count) {
    return '$count seleccionados';
  }

  @override
  String get delete_document_q => '¿Eliminar documento?';

  @override
  String delete_n_documents_q(int count) {
    return '¿Eliminar $count documentos?';
  }

  @override
  String get document_deleted => 'Documento eliminado';

  @override
  String n_documents_deleted(int count) {
    return '$count documentos eliminados';
  }

  @override
  String saved_n_to_device(int count) {
    return '$count guardados en el dispositivo';
  }

  @override
  String couldnt_export_n(int count) {
    return 'No se pudieron exportar $count';
  }

  @override
  String date_and_pages(String date, String pages) {
    return '$date · $pages';
  }

  @override
  String get sort_last_modified => 'Última modificación';

  @override
  String get sort_date_created => 'Fecha de creación';

  @override
  String get sort_name => 'Nombre (A–Z)';

  @override
  String get sort_page_count => 'Número de páginas';

  @override
  String get scanning => 'Escaneo';

  @override
  String get live_detection => 'Detectar bordes del documento';

  @override
  String get live_detection_desc =>
      'Marca el contorno de la página en la cámara y recorta cada foto a ella. Desactívalo para hacer fotos normales y recortarlas después.';

  @override
  String get auto_capture => 'Captura automática';

  @override
  String get auto_capture_desc =>
      'Hace la foto en cuanto la página se queda quieta.';

  @override
  String get batch_capture => 'Modo por lotes';

  @override
  String get batch_capture_desc =>
      'Mantiene la cámara abierta para varias páginas y el recorte se ajusta después. Desactivado, cada foto abre la pantalla de recorte antes de guardarse.';

  @override
  String get scan_mode_single => 'Una';

  @override
  String get scan_mode_batch => 'Lote';

  @override
  String get capture_sound => 'Sonido de captura';

  @override
  String get keep_original => 'Conservar imagen original';

  @override
  String get keep_original_desc =>
      'Guarda la foto sin recortar para poder volver a recortar la página desde la captura completa. Ocupa aproximadamente el doble de espacio por documento.';

  @override
  String get avoid_gesture_strip => 'Evitar la zona del gesto atrás';

  @override
  String get avoid_gesture_strip_desc =>
      'Mantiene las esquinas de recorte lejos del borde de la pantalla, donde arrastrar puede activar el gesto atrás del sistema. La página queda un poco más estrecha.';

  @override
  String get default_filter => 'Filtro predeterminado';

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get language => 'Idioma';

  @override
  String get accent_color => 'Color de acento';

  @override
  String get privacy_storage => 'Privacidad y almacenamiento';

  @override
  String get privacy_body =>
      'OpenScan nunca envía tus documentos a ningún sitio. Sin cuentas, sin nube, sin telemetría.';

  @override
  String get cache => 'Caché';

  @override
  String get clear_cache_q => '¿Borrar caché?';

  @override
  String clear_cache_body(String size) {
    return 'Libera $size de miniaturas. Tus documentos no se ven afectados.';
  }

  @override
  String cache_clear_action(String size) {
    return '$size · Borrar';
  }

  @override
  String get cache_cleared => 'Caché borrada';

  @override
  String get couldnt_clear_cache => 'No se pudo borrar la caché';

  @override
  String get theme_system => 'Sistema';

  @override
  String get theme_light => 'Claro';

  @override
  String get theme_dark => 'Oscuro';

  @override
  String get filters => 'Filtros';

  @override
  String get filter_original => 'Original';

  @override
  String get filter_auto => 'Auto';

  @override
  String get filter_lighten => 'Aclarar';

  @override
  String get filter_grayscale => 'Escala de grises';

  @override
  String get filter_bw => 'B/N';

  @override
  String get filter_whiteboard => 'Pizarra';

  @override
  String get filter_action => 'Filtro';

  @override
  String get apply_to_all_pages => 'Aplicar a todas las páginas';

  @override
  String apply_to_all_n_pages(int count) {
    return 'Aplicar a las $count páginas';
  }

  @override
  String get adjust_edges => 'Ajustar bordes';

  @override
  String get automatic_crop => 'Recorte automático';

  @override
  String get no_crop => 'Sin recorte';

  @override
  String get rescan => 'Volver a escanear';

  @override
  String get couldnt_crop =>
      'No se pudo recortar la imagen. Inténtalo de nuevo.';

  @override
  String get looking_for_document => 'Buscando un documento…';

  @override
  String get document_detected => 'Documento detectado';

  @override
  String get hold_still => 'NO TE MUEVAS…';

  @override
  String get auto_on => 'AUTO · SÍ';

  @override
  String get auto_off => 'AUTO · NO';

  @override
  String get low_light => 'Poca luz: mantén el pulso o enciende el flash';

  @override
  String get torch_on => 'Linterna encendida';

  @override
  String get torch_off => 'Linterna apagada';

  @override
  String get torch_unavailable =>
      'La linterna no está disponible en este dispositivo.';

  @override
  String get auto_capture_on => 'Captura automática activada';

  @override
  String get auto_capture_off => 'Captura automática desactivada';

  @override
  String get auto_capture_needs_detection =>
      'Activa primero la detección de bordes: la captura automática espera a la página que encuentra.';

  @override
  String get undo_last_capture => 'Deshacer última captura';

  @override
  String get composition_grid => 'Cuadrícula de composición';

  @override
  String get switch_camera => 'Cambiar cámara';

  @override
  String get couldnt_capture => 'No se pudo capturar. Inténtalo de nuevo.';

  @override
  String get couldnt_open_gallery => 'No se pudo abrir la galería.';

  @override
  String get couldnt_start_camera =>
      'No se pudo iniciar la cámara. Vuelve atrás e inténtalo de nuevo.';

  @override
  String get camera_access_needed => 'Se necesita acceso a la cámara';

  @override
  String get camera_access_body =>
      'OpenScan solo usa la cámara para escanear páginas; nada sale de tu dispositivo. Actívalo en Ajustes para continuar.';

  @override
  String done_count(int count) {
    return 'Listo · $count';
  }

  @override
  String get delete_document => 'Eliminar documento';

  @override
  String get delete_document_body =>
      'Se eliminarán todas sus páginas. Esta acción no se puede deshacer.';

  @override
  String get delete_page_q => '¿Eliminar página?';

  @override
  String delete_n_pages_q(int count) {
    return '¿Eliminar $count páginas?';
  }

  @override
  String get no_pages_title => 'Este documento no tiene páginas';

  @override
  String get no_pages_body =>
      'Recibe el nombre de tu primera página; cámbialo cuando quieras tocando el título.';

  @override
  String get continue_scanning => 'Seguir escaneando';

  @override
  String get add_pages => 'Añadir páginas';

  @override
  String get export_selected => 'Exportar selección';

  @override
  String export_n_selected(int count) {
    return 'Exportar $count seleccionados';
  }

  @override
  String skipped_files(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se omitieron $count archivos que esta app no puede leer.',
      one: 'Se omitió 1 archivo que esta app no puede leer.',
    );
    return '$_temp0';
  }

  @override
  String hold_to_select(String pages) {
    return '$pages · mantén pulsada una página para seleccionarla';
  }

  @override
  String export_title(String name) {
    return 'Exportar · $name';
  }

  @override
  String get quality_caps => 'CALIDAD';

  @override
  String get page_size => 'Tamaño de página';

  @override
  String get page_size_letter => 'Carta';

  @override
  String get page_size_legal => 'Oficio';

  @override
  String get all_pages => 'Todas las páginas';

  @override
  String get selected_pages => 'Páginas seleccionadas';

  @override
  String page_x_of_y(int current, int total) {
    return 'Página $current de $total';
  }

  @override
  String get exported => 'Exportado';

  @override
  String saved_to_folder(String folder) {
    return 'Guardado en $folder';
  }

  @override
  String saved_n_to_folder(int count, String folder) {
    return '$count guardados en $folder';
  }

  @override
  String get saved_privately =>
      'Guardado dentro de OpenScan, donde otras apps no pueden verlo. Usa Compartir para enviarlo a otro sitio.';

  @override
  String get export_failed => 'Error al exportar';

  @override
  String get no_pages_to_export => 'No hay páginas para exportar.';

  @override
  String get pdf_not_written => 'No se pudo crear el PDF';

  @override
  String get not_enough_storage =>
      'No hay suficiente espacio de almacenamiento en este dispositivo.';

  @override
  String get export_went_wrong => 'Algo salió mal al exportar.';

  @override
  String couldnt_open_file(String message) {
    return 'No se pudo abrir el archivo: $message';
  }

  @override
  String get no_app_opens_file =>
      'Ninguna app de este teléfono abre ese tipo de archivo';

  @override
  String get quality_ultra_low => 'Muy baja';

  @override
  String get quality_low => 'Baja';

  @override
  String get quality_medium => 'Media';

  @override
  String get quality_high => 'Alta';

  @override
  String result_and_more(String name, int count) {
    return '$name y $count más';
  }

  @override
  String get rename_file => 'Cambiar nombre del archivo';

  @override
  String get file_name_empty => 'El nombre del archivo no puede estar vacío';

  @override
  String get special_chars_not_allowed =>
      'No se permiten caracteres especiales';

  @override
  String get save_to_device => 'Guardar en el dispositivo';

  @override
  String get share_pdf => 'Compartir PDF';

  @override
  String get share_images => 'Compartir imágenes';

  @override
  String get demo_scan_title => 'Apunta a la página';

  @override
  String get demo_scan_body =>
      'OpenScan encuentra los bordes de la página: toca el disparador para hacer la foto. Activa la Captura automática y la hará sola cuando te quedes quieto.';

  @override
  String get demo_pages_title => 'Sigue para añadir más páginas';

  @override
  String get demo_pages_body =>
      'Cada foto se añade al mismo documento. Toca Listo cuando las tengas todas.';

  @override
  String get demo_adjust_title => 'Endereza y limpia';

  @override
  String get demo_adjust_body =>
      'Arrastra las esquinas si los bordes no encajan y elige un filtro: Auto, Escala de grises o B/N.';

  @override
  String get demo_organise_title => 'Reordena y añade páginas';

  @override
  String get demo_organise_body =>
      'Mantén pulsada una página para seleccionarla, reordena las páginas desde el menú ⋮ y añade más páginas cuando quieras.';

  @override
  String get demo_export_title => 'Guarda o comparte en PDF';

  @override
  String get demo_export_body =>
      'Elige la calidad y el tamaño de página, y guárdalo en tu teléfono o envíalo a donde quieras.';

  @override
  String get demo_privacy_title => 'Nunca sale de tu teléfono';

  @override
  String get demo_privacy_body =>
      'Sin cuentas, sin nube, sin anuncios, sin rastreo. La cámara solo se usa para escanear.';

  @override
  String get allow_camera_access => 'Permitir acceso a la cámara';

  @override
  String get app_description =>
      'es una app de código abierto que permite escanear documentos en papel y convertirlos en un archivo PDF.';

  @override
  String get app_description_2 =>
      'Sin anuncios. No recopilamos ningún dato.\n Respetamos tu privacidad.';

  @override
  String get open_source_github => 'Código abierto en GitHub';

  @override
  String get couldnt_launch_url => 'No se pudo abrir el enlace';
}
