import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/image_filter/filters/document_filters.dart';

/// A page-like RGBA buffer: light paper, a dark ink block, and a shadow
/// gradient across the whole thing so the adaptive modes have something to
/// correct for.
Uint8List _page(int width, int height) {
  final rgba = Uint8List(width * height * 4);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      // Lighting falls off from left to right.
      final shade = 1 - (x / width) * 0.5;
      final inInk =
          x > width ~/ 3 &&
          x < width * 2 ~/ 3 &&
          y > height ~/ 3 &&
          y < height * 2 ~/ 3;
      final level = ((inInk ? 40 : 230) * shade).round();
      final i = (y * width + x) * 4;
      rgba[i] = level;
      rgba[i + 1] = level;
      rgba[i + 2] = level;
      rgba[i + 3] = 255;
    }
  }
  return rgba;
}

void main() {
  const width = 96, height = 96;

  test('the six document modes are offered, in picker order', () {
    expect(documentFiltersList.map((filter) => filter.name), [
      'Original',
      'Auto',
      'Lighten',
      'Grayscale',
      'B&W',
      'Whiteboard',
    ]);
  });

  test('documentFilterByName falls back to Original', () {
    expect(documentFilterByName('B&W').name, 'B&W');
    expect(documentFilterByName(null).name, 'Original');
    expect(documentFilterByName('Nashville').name, 'Original');
    expect(defaultDocumentFilter.name, 'Original');
  });

  test('every filter survives a 1x1 image', () {
    // Degenerate sizes are where the window/downscale arithmetic in the
    // adaptive modes would divide by zero if the clamps came off.
    for (final filter in documentFiltersList) {
      final rgba = Uint8List.fromList([128, 128, 128, 255]);
      expect(
        () => filter.apply(rgba, 1, 1),
        returnsNormally,
        reason: filter.name,
      );
    }
  });

  test('Original changes nothing', () {
    final rgba = _page(width, height);
    final untouched = Uint8List.fromList(rgba);
    OriginalFilter().apply(rgba, width, height);
    expect(rgba, untouched);
  });

  test('B&W emits only pure black and pure white', () {
    final rgba = _page(width, height);
    BlackAndWhiteFilter().apply(rgba, width, height);
    for (int i = 0; i < rgba.length; i += 4) {
      expect(rgba[i], anyOf(0, 255));
      expect(rgba[i + 1], rgba[i]);
      expect(rgba[i + 2], rgba[i]);
    }
  });

  test('B&W finds the ink despite the lighting gradient', () {
    final rgba = _page(width, height);
    BlackAndWhiteFilter().apply(rgba, width, height);

    // A pixel inside the ink block, on the *bright* side of the page...
    expect(_at(rgba, width, width ~/ 3 + 4, height ~/ 2), 0);
    // ...and blank paper on the *dark* side, which a single global
    // threshold would have been at risk of calling ink.
    expect(_at(rgba, width, width - 3, height ~/ 8), 255);
  });

  test('Grayscale leaves the three channels equal', () {
    final rgba = _colourPage(width, height);
    GrayscaleFilter().apply(rgba, width, height);
    for (int i = 0; i < rgba.length; i += 4) {
      expect(rgba[i + 1], rgba[i]);
      expect(rgba[i + 2], rgba[i]);
    }
  });

  test('Auto stretches a flat, low-contrast page out', () {
    final rgba = _colourPage(width, height);
    AutoFilter().apply(rgba, width, height);
    expect(_range(rgba), greaterThan(_range(_colourPage(width, height))));
  });

  test('Lighten drives the paper to pure white', () {
    final rgba = _page(width, height);
    LightenFilter().apply(rgba, width, height);
    // The brightest corner of the paper is the reference white.
    expect(_at(rgba, width, 1, 1), 255);
  });

  test('Whiteboard flattens the lighting gradient', () {
    Uint8List rgba = _page(width, height);
    final beforeSpread =
        (_at(rgba, width, 1, 1) - _at(rgba, width, width - 2, 1)).abs();
    WhiteboardFilter().apply(rgba, width, height);
    final afterSpread =
        (_at(rgba, width, 1, 1) - _at(rgba, width, width - 2, 1)).abs();
    expect(afterSpread, lessThan(beforeSpread));
  });
}

int _at(Uint8List rgba, int width, int x, int y) => rgba[(y * width + x) * 4];

int _range(Uint8List rgba) {
  int lowest = 255, highest = 0;
  for (int i = 0; i < rgba.length; i += 4) {
    lowest = min(lowest, rgba[i]);
    highest = max(highest, rgba[i]);
  }
  return highest - lowest;
}

/// A washed-out colour page: nothing near black or white, so auto-levels
/// have room to work.
Uint8List _colourPage(int width, int height) {
  final rgba = Uint8List(width * height * 4);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      rgba[i] = 120 + (x * 40 ~/ width);
      rgba[i + 1] = 130 + (y * 30 ~/ height);
      rgba[i + 2] = 110 + ((x + y) * 25 ~/ (width + height));
      rgba[i + 3] = 255;
    }
  }
  return rgba;
}
