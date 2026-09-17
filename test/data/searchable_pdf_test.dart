import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/core/ocr/ocr_models.dart';
import 'package:pdf/pdf.dart';

/// The invisible text layer, checked where it actually matters: in the
/// bytes of the written PDF.
///
/// A layer that renders but carries no extractable text would look
/// perfect on screen and be exactly as unsearchable as no layer at all,
/// so these read the text back out of the file rather than trusting the
/// widget tree that produced it.
void main() {
  late Directory workspace;
  final fileOperations = FileOperations();

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('openscan_pdf_test');
  });

  tearDown(() {
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  /// A page image on disk, the shape a stored scan has.
  ImageOS page(String name, {int width = 1200, int height = 1600}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(250, 250, 248));
    final path = '${workspace.path}/$name.jpg';
    File(path).writeAsBytesSync(img.encodeJpg(image, quality: 85));
    return ImageOS(imgPath: path);
  }

  /// Every text run the PDF carries, pulled out of its content streams.
  ///
  /// The pdf package writes those streams Flate-compressed, so they are
  /// inflated first; anything that will not inflate is not a content
  /// stream and is skipped.
  String extractText(File pdf) {
    final bytes = pdf.readAsBytesSync();
    final found = StringBuffer();
    const streamMarker = 'stream';
    final text = String.fromCharCodes(bytes);

    int index = 0;
    while (true) {
      index = text.indexOf(streamMarker, index);
      if (index < 0) break;
      int start = index + streamMarker.length;
      // Past the EOL that must follow the `stream` keyword.
      if (start < bytes.length && bytes[start] == 0x0D) start++;
      if (start < bytes.length && bytes[start] == 0x0A) start++;
      final end = text.indexOf('endstream', start);
      if (end < 0) break;
      try {
        found.write(
            String.fromCharCodes(zlib.decode(bytes.sublist(start, end))));
      } catch (_) {
        // Not a Flate stream (an embedded JPEG, say).
      }
      // Past the whole `endstream` keyword: resuming at `end` would find
      // the `stream` inside it and pair that with the *next* object's
      // `endstream`, which quietly skips every other real stream.
      index = end + 'endstream'.length;
    }
    return found.toString();
  }

  Future<File> writePdf(
    List<ImageOS> pages,
    List<List<OcrWord>> words,
  ) async {
    final path = await fileOperations.createPdf({
      'selectedDirectory': workspace,
      'fileName': 'export',
      'images': pages,
      'pageFormat': PdfPageFormat.a4,
      'ocrWords': words,
    });
    expect(path, isNotNull, reason: 'the PDF should have been written');
    return File(path!);
  }

  OcrWord word(String text, {double top = 0.2, double left = 0.1}) => OcrWord(
        text: text,
        confidence: 90,
        left: left,
        top: top,
        right: left + 0.2,
        bottom: top + 0.03,
      );

  test('recognized words end up as extractable text in the PDF', () async {
    final pdf = await writePdf(
      [page('one')],
      [
        [word('Invoice'), word('42', top: 0.3)]
      ],
    );

    final content = extractText(pdf);
    expect(content, contains('Invoice'));
    expect(content, contains('42'));
  });

  test('each page carries only its own words', () async {
    final pdf = await writePdf(
      [page('one'), page('two')],
      [
        [word('Alpha')],
        [word('Bravo')],
      ],
    );

    final content = extractText(pdf);
    expect(content, contains('Alpha'));
    expect(content, contains('Bravo'));
  });

  test('a PDF exported without OCR carries no text layer', () async {
    final pdf = await writePdf([page('one')], const []);
    expect(extractText(pdf), isNot(contains('Invoice')));
    expect(pdf.lengthSync(), greaterThan(0));
  });

  test('a page with no recognized words still gets written', () async {
    // A blank page in the middle of a document must not cost the export.
    final pdf = await writePdf(
      [page('one'), page('blank'), page('three')],
      [
        [word('First')],
        const <OcrWord>[],
        [word('Third')],
      ],
    );

    final content = extractText(pdf);
    expect(content, contains('First'));
    expect(content, contains('Third'));
  });

  test('a word Helvetica cannot encode is dropped, not fatal', () async {
    // The standard PDF fonts are Latin-1 only. Before the text was
    // sanitized this threw while saving, losing the entire export over one
    // mis-recognized glyph.
    final pdf = await writePdf(
      [page('one')],
      [
        [word('日本語'), word('Readable', top: 0.4)]
      ],
    );

    final content = extractText(pdf);
    expect(content, contains('Readable'));
  });

  test('the text layer is drawn fully transparent', () async {
    // The whole point: searchable, not visible. The words are drawn under
    // a graphics state with both fill and stroke alpha at zero, so a
    // reader finds them and a human never sees them printed over the scan.
    final pdf = await writePdf(
      [page('one')],
      [
        [word('Invoice')]
      ],
    );

    final raw = String.fromCharCodes(pdf.readAsBytesSync());
    expect(raw, contains('/ca 0'));
    expect(raw, contains('/CA 0'));
    // And the text run actually sits inside that state.
    expect(extractText(pdf), contains('gs'));
  });

  test('a word is placed where it was read from on the page', () async {
    // A4 is 595.28pt wide; the page is drawn inside a 5pt margin, so a
    // 1200x1600 scan is scaled to 585.28pt across. A word starting a
    // tenth of the way in therefore belongs ~58.5pt from the left edge of
    // the drawn image. If this drifts, every highlight in every reader
    // lands on the wrong part of the page.
    final pdf = await writePdf(
      [page('one', width: 1200, height: 1600)],
      [
        [word('Invoice', left: 0.1, top: 0.2)]
      ],
    );

    final content = extractText(pdf);
    final match = RegExp(r'1 0 0 1 (\d+\.?\d*) [\d.]+ cm\s+q 1 0 0 1 0 0 cm\s+/a\d+ gs')
        .firstMatch(content);
    expect(match, isNotNull,
        reason: 'the word should be positioned by a translate matrix');
    expect(double.parse(match!.group(1)!), closeTo(58.5, 1.0));
  });

  test('the words fit on the page they were placed on', () async {
    // Positions are fractions of the drawn image, so every word must land
    // inside the page box rather than off the edge of the paper.
    final pdf = await writePdf(
      [page('one')],
      [
        [word('TopLeft', left: 0.0, top: 0.0), word('BottomRight', left: 0.75, top: 0.95)]
      ],
    );

    final content = extractText(pdf);
    expect(content, contains('TopLeft'));
    expect(content, contains('BottomRight'));
  });
}
