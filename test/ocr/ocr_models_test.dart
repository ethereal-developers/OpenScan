import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/ocr/ocr_models.dart';

void main() {
  group('OcrWord.fromPixels', () {
    test('turns the native pixel box into fractions of the page', () {
      final word = OcrWord.fromPixels(
        {'text': 'Invoice', 'confidence': 91.5,
         'left': 200, 'top': 150, 'right': 600, 'bottom': 250},
        width: 2000,
        height: 3000,
      );

      expect(word.text, 'Invoice');
      expect(word.confidence, 91.5);
      expect(word.left, 0.1);
      expect(word.top, 0.05);
      expect(word.right, 0.3);
      expect(word.bottom, closeTo(0.0833, 0.0001));
      expect(word.width, closeTo(0.2, 0.0001));
    });

    test('is resolution independent: the same box on the same page, '
        'measured at two sizes, normalizes identically', () {
      // This is the property the searchable PDF depends on. A page is
      // recognized at its stored 2400px, then re-encoded smaller on the
      // way into the export; a word's position has to survive that.
      final large = OcrWord.fromPixels(
        {'text': 'Total', 'confidence': 88,
         'left': 480, 'top': 960, 'right': 720, 'bottom': 1020},
        width: 2400,
        height: 3000,
      );
      final small = OcrWord.fromPixels(
        {'text': 'Total', 'confidence': 88,
         'left': 240, 'top': 480, 'right': 360, 'bottom': 510},
        width: 1200,
        height: 1500,
      );

      expect(small.left, closeTo(large.left, 1e-9));
      expect(small.top, closeTo(large.top, 1e-9));
      expect(small.right, closeTo(large.right, 1e-9));
      expect(small.bottom, closeTo(large.bottom, 1e-9));
    });

    test('a page whose size came back as zero does not divide by it', () {
      final word = OcrWord.fromPixels(
        {'text': 'x', 'confidence': 50,
         'left': 10, 'top': 20, 'right': 30, 'bottom': 40},
        width: 0,
        height: 0,
      );
      expect(word.left.isFinite, isTrue);
      expect(word.bottom.isFinite, isTrue);
    });
  });

  group('word encoding', () {
    test('survives a round trip through the database column', () {
      final page = OcrPageText(
        text: 'Invoice 42',
        words: [
          const OcrWord(text: 'Invoice', confidence: 91,
              left: 0.1, top: 0.2, right: 0.3, bottom: 0.24),
          const OcrWord(text: '42', confidence: 77,
              left: 0.32, top: 0.2, right: 0.36, bottom: 0.24),
        ],
        language: 'eng',
        sourcePath: '/pages/1.jpg',
      );

      final decoded = OcrPageText.decodeWords(page.encodeWords());

      expect(decoded, hasLength(2));
      expect(decoded.first.text, 'Invoice');
      expect(decoded.first.confidence, 91);
      expect(decoded.first.left, 0.1);
      expect(decoded.last.text, '42');
      expect(decoded.last.right, 0.36);
    });

    test('a column this build cannot parse reads as no words, not a crash', () {
      // Stored text is a cache. Losing it costs one re-run; throwing here
      // would take down whatever screen asked for it.
      expect(OcrPageText.decodeWords('not json at all'), isEmpty);
      expect(OcrPageText.decodeWords('{"not":"a list"}'), isEmpty);
      expect(OcrPageText.decodeWords(''), isEmpty);
      expect(OcrPageText.decodeWords(null), isEmpty);
    });
  });

  group('staleness', () {
    const page = OcrPageText(
      text: 'hello',
      words: [],
      language: 'eng',
      sourcePath: '/pages/1.jpg',
    );

    test('matches the image it was read from', () {
      expect(page.matches('/pages/1.jpg'), isTrue);
    });

    test('does not match the page after a re-crop writes a new file', () {
      expect(page.matches('/pages/1-cropped.jpg'), isFalse);
    });

    test('a page of whitespace counts as empty', () {
      const blank = OcrPageText(
          text: '  \n \t ', words: [], language: 'eng', sourcePath: '/a.jpg');
      expect(blank.isEmpty, isTrue);
      expect(page.isEmpty, isFalse);
    });
  });
}
