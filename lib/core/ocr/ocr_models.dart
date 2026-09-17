import 'dart:convert';

/// One recognized word and where it sits on the page.
///
/// The rectangle is stored as fractions of the page's width and height
/// rather than pixels. Every consumer wants it at a different scale — the
/// PDF draws the page re-encoded smaller, a highlight overlay draws it at
/// whatever size the widget got — and a fraction survives all of them,
/// where a pixel box is only true for the exact image it was measured on.
class OcrWord {
  const OcrWord({
    required this.text,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;

  /// Tesseract's own 0-100 certainty for this word.
  final double confidence;

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  /// Builds from the platform channel's pixel box, normalized against the
  /// page size the native side measured it at.
  factory OcrWord.fromPixels(Map raw, {required int width, required int height}) {
    final w = width <= 0 ? 1 : width;
    final h = height <= 0 ? 1 : height;
    return OcrWord(
      text: raw['text'] as String? ?? '',
      confidence: (raw['confidence'] as num?)?.toDouble() ?? 0,
      left: (raw['left'] as num).toDouble() / w,
      top: (raw['top'] as num).toDouble() / h,
      right: (raw['right'] as num).toDouble() / w,
      bottom: (raw['bottom'] as num).toDouble() / h,
    );
  }

  Map<String, dynamic> toJson() => {
        't': text,
        'c': confidence,
        'l': left,
        'y': top,
        'r': right,
        'b': bottom,
      };

  factory OcrWord.fromJson(Map<String, dynamic> json) => OcrWord(
        text: json['t'] as String? ?? '',
        confidence: (json['c'] as num?)?.toDouble() ?? 0,
        left: (json['l'] as num?)?.toDouble() ?? 0,
        top: (json['y'] as num?)?.toDouble() ?? 0,
        right: (json['r'] as num?)?.toDouble() ?? 0,
        bottom: (json['b'] as num?)?.toDouble() ?? 0,
      );
}

/// Everything recognition produced for a single page.
class OcrPageText {
  const OcrPageText({
    required this.text,
    required this.words,
    required this.language,
    required this.sourcePath,
  });

  /// The page's text in reading order, as Tesseract laid it out.
  final String text;

  /// Word boxes, for the PDF's invisible text layer. Can be empty even
  /// when [text] is not: a page whose words all came back below the
  /// confidence floor still has readable text worth keeping.
  final List<OcrWord> words;

  /// The traineddata language this was recognized with.
  final String language;

  /// The image file this was recognized from.
  ///
  /// A page is not a fixed thing: re-cropping or filtering it writes a new
  /// file and points the page at that instead. Recording what was actually
  /// read means a later read can tell stored text apart from text that
  /// describes an image the page no longer uses.
  final String sourcePath;

  bool get isEmpty => text.trim().isEmpty;

  /// Whether this still describes [currentPath]'s contents.
  bool matches(String currentPath) => sourcePath == currentPath;

  String encodeWords() =>
      jsonEncode([for (final word in words) word.toJson()]);

  static List<OcrWord> decodeWords(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return [
        for (final word in decoded)
          if (word is Map<String, dynamic>) OcrWord.fromJson(word),
      ];
    } catch (_) {
      // Stored text is a cache, never the only copy of anything: a row
      // this build cannot parse is worth re-recognizing, not crashing on.
      return const [];
    }
  }
}
