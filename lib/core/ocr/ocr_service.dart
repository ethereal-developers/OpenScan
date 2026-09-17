import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/core/ocr/ocr_models.dart';
import 'package:openscan/core/ocr/tessdata.dart';

/// Thrown when a page could not be recognized. Carries the platform's
/// message so the UI can say what went wrong rather than "OCR failed".
class OcrException implements Exception {
  OcrException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Progress through a multi-page recognition run.
class OcrProgress {
  const OcrProgress({
    required this.completed,
    required this.total,
    required this.failed,
  });

  final int completed;
  final int total;
  final int failed;

  bool get isDone => completed + failed >= total;
}

/// Text recognition, and the cache in front of it.
///
/// Recognition is genuinely expensive — seconds per page on a mid-range
/// phone — so nothing here runs a page twice. Every result is written to
/// the database keyed by the image it was read from, and a request for a
/// page whose stored text still matches that image is answered from the
/// row.
///
/// Everything is on-device: the traineddata ships in the APK and the
/// native side opens it from local storage. No page, and no text read off
/// one, leaves the phone.
class OcrService {
  OcrService._();

  static final OcrService instance = OcrService._();

  static const MethodChannel _channel =
      MethodChannel('com.ethereal.openscan/ocr');

  final DatabaseHelper _database = DatabaseHelper();

  /// Serializes work queued from Dart.
  ///
  /// The native side already runs one page at a time on a single thread,
  /// but without this a screen that asks for twenty pages would hold
  /// twenty pending channel calls, and cancelling would have nothing to
  /// cancel but the one already inside Tesseract.
  Future<void> _queue = Future.value();

  bool _cancelled = false;

  /// Asks the native side to abandon the page it is recognizing, and stops
  /// this service handing it any more.
  ///
  /// The in-flight page still returns — Tesseract unwinds to a partial or
  /// empty result rather than throwing — so callers see the run stop at
  /// the next page rather than mid-word.
  Future<void> cancel() async {
    _cancelled = true;
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (e) {
      debugPrint('Could not stop OCR: ${e.message}');
    }
  }

  /// The text on record for [image], or null if there is none that still
  /// describes the image the page currently points at.
  Future<OcrPageText?> cachedText({
    required String tableName,
    required ImageOS image,
  }) async {
    final row =
        await _database.getPageText(tableName: tableName, imgPath: image.imgPath);
    if (row == null) return null;
    final source = row['source_img_path'] as String?;
    if (source == null || source != image.imgPath) return null;
    return OcrPageText(
      text: row['text'] as String? ?? '',
      words: OcrPageText.decodeWords(row['words'] as String?),
      language: row['language'] as String? ?? TessData.defaultLanguage,
      sourcePath: source,
    );
  }

  /// Recognizes one page, or returns what is already on record for it.
  ///
  /// Pass [force] to re-read a page whose stored text is still valid —
  /// the only reason to is a language change, since the image itself
  /// changing already invalidates the row.
  Future<OcrPageText> recognize({
    required String tableName,
    required ImageOS image,
    String? language,
    bool force = false,
  }) async {
    if (!force) {
      final cached = await cachedText(tableName: tableName, image: image);
      if (cached != null) return cached;
    }

    final lang = language ?? TessData.defaultLanguage;
    final completer = Completer<OcrPageText>();
    // Chained onto the queue rather than awaited directly, so concurrent
    // callers line up instead of overlapping. The chain deliberately never
    // carries an error forward: one page failing must not poison every
    // page queued behind it.
    _queue = _queue.then((_) async {
      try {
        completer.complete(await _run(tableName, image, lang));
      } catch (e) {
        completer.completeError(e);
      }
    });
    return completer.future;
  }

  Future<OcrPageText> _run(
      String tableName, ImageOS image, String language) async {
    final dataPath = await TessData.ensureInstalled();

    final Map<dynamic, dynamic>? raw;
    try {
      raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('recognize', {
        'imagePath': image.imgPath,
        'dataPath': dataPath,
        'language': language,
      });
    } on PlatformException catch (e) {
      throw OcrException(e.message ?? 'Recognition failed');
    } on MissingPluginException {
      throw OcrException('Text recognition is not available on this device');
    }
    if (raw == null) throw OcrException('Recognition returned nothing');

    final width = (raw['width'] as num?)?.toInt() ?? 0;
    final height = (raw['height'] as num?)?.toInt() ?? 0;
    final rawWords = raw['words'];
    final result = OcrPageText(
      text: (raw['text'] as String? ?? '').trim(),
      words: [
        if (rawWords is List)
          for (final word in rawWords)
            if (word is Map) OcrWord.fromPixels(word, width: width, height: height),
      ],
      language: language,
      sourcePath: image.imgPath,
    );

    await _database.savePageText(
      tableName: tableName,
      imgPath: image.imgPath,
      text: result.text,
      words: result.encodeWords(),
      language: language,
    );
    return result;
  }

  /// Recognizes every page in [images] that does not already have valid
  /// text, reporting after each one.
  ///
  /// Pages that fail are counted and skipped rather than ending the run:
  /// one unreadable page in a forty-page document should cost that page,
  /// not the other thirty-nine.
  Future<Map<String, OcrPageText>> recognizeAll({
    required String tableName,
    required List<ImageOS> images,
    String? language,
    bool force = false,
    void Function(OcrProgress progress)? onProgress,
  }) async {
    _cancelled = false;
    final results = <String, OcrPageText>{};
    int completed = 0;
    int failed = 0;

    for (final image in images) {
      if (_cancelled) break;
      try {
        results[image.imgPath] = await recognize(
          tableName: tableName,
          image: image,
          language: language,
          force: force,
        );
        completed++;
      } catch (e) {
        debugPrint('Could not recognize ${image.imgPath}: $e');
        failed++;
      }
      onProgress?.call(OcrProgress(
        completed: completed,
        total: images.length,
        failed: failed,
      ));
    }
    return results;
  }

  /// How many of a document's pages have usable text on record.
  Future<int> recognizedCount(String tableName) =>
      _database.recognizedPageCount(tableName);

  /// The stored text for a whole document, keyed by image path. Only rows
  /// still describing the page's current image are returned.
  Future<Map<String, OcrPageText>> documentText({
    required String tableName,
    required List<ImageOS> images,
  }) async {
    final rows = await _database.getDocumentText(tableName);
    final result = <String, OcrPageText>{};
    for (final image in images) {
      final row = rows[image.imgPath];
      if (row == null) continue;
      result[image.imgPath] = OcrPageText(
        text: row['text'] as String? ?? '',
        words: OcrPageText.decodeWords(row['words'] as String?),
        language: row['language'] as String? ?? TessData.defaultLanguage,
        sourcePath: image.imgPath,
      );
    }
    return result;
  }

  /// Directory names of documents whose text contains [query].
  Future<Set<String>> search(String query) =>
      _database.searchDocumentText(query);
}
