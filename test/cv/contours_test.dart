import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/cv/contours.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';

void main() {
  group('isPlausibleQuad', () {
    const frameWidth = 400;
    const frameHeight = 600;

    test('accepts a normal, roughly-rectangular document-sized quad', () {
      const quad = Quad(
        topLeft: Pt(40, 60),
        topRight: Pt(360, 50),
        bottomRight: Pt(370, 560),
        bottomLeft: Pt(30, 570),
      );
      expect(isPlausibleQuad(quad, frameWidth, frameHeight), isTrue);
    });

    test('rejects a quad whose area is too small relative to the frame', () {
      // A tiny 10x10 square in the corner of a 400x600 frame — a valid
      // convex quad, but far too small to plausibly be the document.
      const quad = Quad(
        topLeft: Pt(0, 0),
        topRight: Pt(10, 0),
        bottomRight: Pt(10, 10),
        bottomLeft: Pt(0, 10),
      );
      expect(isPlausibleQuad(quad, frameWidth, frameHeight), isFalse);
    });

    test('rejects a near-triangular quad (two corners nearly coincident)', () {
      // topRight sits almost exactly on top of topLeft, so despite having
      // four distinct points this is effectively a triangle/sliver.
      const quad = Quad(
        topLeft: Pt(40, 60),
        topRight: Pt(41, 61),
        bottomRight: Pt(370, 560),
        bottomLeft: Pt(30, 570),
      );
      expect(isPlausibleQuad(quad, frameWidth, frameHeight), isFalse);
    });

    test('rejects a sliver quad with a very acute interior angle', () {
      // A thin kite shape: well past the area-ratio floor on its own
      // (~6.75% of a 400x1000 frame), but topLeft's interior angle is
      // ~7.6 degrees — a needle-thin corner no real document has. This
      // isolates the angle check from the area check above.
      const wideFrameWidth = 400;
      const wideFrameHeight = 1000;
      const quad = Quad(
        topLeft: Pt(200, 50),
        topRight: Pt(230, 500),
        bottomRight: Pt(200, 950),
        bottomLeft: Pt(170, 500),
      );
      expect(isPlausibleQuad(quad, wideFrameWidth, wideFrameHeight), isFalse);
    });

    test('rejects when width or height is non-positive', () {
      const quad = Quad(
        topLeft: Pt(0, 0),
        topRight: Pt(10, 0),
        bottomRight: Pt(10, 10),
        bottomLeft: Pt(0, 10),
      );
      expect(isPlausibleQuad(quad, 0, frameHeight), isFalse);
      expect(isPlausibleQuad(quad, frameWidth, 0), isFalse);
    });

    test('accepts a quad skewed by steep perspective without false-rejecting',
        () {
      // A document photographed at a sharp angle is still legitimately
      // trapezoidal — this shouldn't be mistaken for a sliver.
      const quad = Quad(
        topLeft: Pt(150, 80),
        topRight: Pt(320, 60),
        bottomRight: Pt(380, 560),
        bottomLeft: Pt(20, 560),
      );
      expect(isPlausibleQuad(quad, frameWidth, frameHeight), isTrue);
    });
  });

  group('findDocumentQuad rejects degenerate detections', () {
    test('a mask with only a tiny bright blob returns null', () {
      const width = 200, height = 200;
      final mask = Uint8List(width * height);
      // A 5x5 blob — well under the 5% area-ratio floor.
      for (int y = 0; y < 5; y++) {
        for (int x = 0; x < 5; x++) {
          mask[y * width + x] = 1;
        }
      }
      expect(findDocumentQuad(mask, width, height), isNull);
    });
  });
}
