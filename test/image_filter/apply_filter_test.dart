import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/image_filter/apply_filter.dart';
import 'package:openscan/core/image_filter/filters/document_filters.dart';

img.Image _decode(Object bytes) => img.decodeImage(bytes as Uint8List)!;

Uint8List _pageJpeg({int width = 120, int height = 160}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(220, 215, 205));
  img.fillRect(
    image,
    x1: width ~/ 4,
    y1: height ~/ 4,
    x2: width * 3 ~/ 4,
    y2: height * 3 ~/ 4,
    color: img.ColorRgb8(30, 30, 35),
  );
  return img.encodeJpg(image, quality: 100);
}

void main() {
  test('filterEncodedImage actually rewrites the pixels', () {
    // Guards the trap that made the old filter code a no-op: the `image`
    // package hands out a *copy* of the pixel buffer, so a filter that
    // mutates it has to be wrapped back into a new Image before encoding.
    final encoded = _pageJpeg();
    final filtered = filterEncodedImage(documentFilterByName('B&W'), encoded);
    expect(filtered, isNot(equals(encoded)));

    final decoded = _decode(filtered);
    final pixel = decoded.getPixel(2, 2);
    expect(pixel.r, anyOf(closeTo(0, 8), closeTo(255, 8)));
  });

  test('filterEncodedImage downscales to maxEdge', () {
    final decoded = _decode(
      filterEncodedImage(
        documentFilterByName('Auto'),
        _pageJpeg(),
        maxEdge: 40,
      ),
    );
    expect(decoded.height, 40);
    expect(decoded.width, lessThanOrEqualTo(40));
  });

  group('applyFilterIsolateEntry', () {
    late Directory tempDir;
    late String srcPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('apply_filter_test');
      srcPath = '${tempDir.path}/page.jpg';
      File(srcPath).writeAsBytesSync(_pageJpeg());
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('returns the encoded bytes when no dest is given', () async {
      final result = await applyFilterIsolateEntry({
        'filter': 'Grayscale',
        'src': srcPath,
        'maxEdge': 60,
      });
      expect(result, isA<Uint8List>());
      expect(_decode(result).height, 60);
    });

    test('writes to dest and returns the path when one is given', () async {
      final destPath = '${tempDir.path}/filtered.jpg';
      final result = await applyFilterIsolateEntry({
        'filter': 'Whiteboard',
        'src': srcPath,
        'dest': destPath,
      });
      expect(result, destPath);
      expect(File(destPath).existsSync(), isTrue);
      expect(_decode(File(destPath).readAsBytesSync()).width, 120);
    });
  });
}
