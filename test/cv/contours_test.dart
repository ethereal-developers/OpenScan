import 'dart:math';
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

  group('bestCornerAssignment', () {
    test('re-labels an unordered point set to match the closest reference slot',
        () {
      const reference = Quad(
        topLeft: Pt(10, 10),
        topRight: Pt(90, 10),
        bottomRight: Pt(90, 90),
        bottomLeft: Pt(10, 90),
      );
      // Same 4 points, deliberately shuffled and slightly perturbed, so
      // naive index-order assignment would be wrong.
      final shuffled = const [
        Pt(91, 91), // near bottomRight
        Pt(9, 9), // near topLeft
        Pt(9, 91), // near bottomLeft
        Pt(91, 9), // near topRight
      ];

      final result = bestCornerAssignment(shuffled, reference);

      expect(result.quad.topLeft, const Pt(9, 9));
      expect(result.quad.topRight, const Pt(91, 9));
      expect(result.quad.bottomRight, const Pt(91, 91));
      expect(result.quad.bottomLeft, const Pt(9, 91));
      expect(result.totalDistance, closeTo(4 * sqrt(2), 0.01));
    });
  });

  group('findDocumentQuad with previousQuad biasing', () {
    /// Builds a mask with two disjoint filled rectangles: a larger one
    /// near the top-left (found first, since components are tried largest
    /// -> smallest) and a smaller one near the bottom-right, both well
    /// past the 5% area-ratio floor for a 200x200 mask (2000px).
    Uint8List _twoRectangleMask(int width, int height) {
      final mask = Uint8List(width * height);
      void fill(int x0, int y0, int x1, int y1) {
        for (int y = y0; y < y1; y++) {
          for (int x = x0; x < x1; x++) {
            mask[y * width + x] = 1;
          }
        }
      }

      fill(10, 10, 90, 60); // larger: 80x50 = 4000px
      fill(120, 120, 175, 165); // smaller: 55x45 = 2475px
      return mask;
    }

    test('without previousQuad, returns the first (largest) valid candidate',
        () {
      const width = 200, height = 200;
      final mask = _twoRectangleMask(width, height);

      final quad = findDocumentQuad(mask, width, height);

      expect(quad, isNotNull);
      // The larger top-left rectangle should win.
      expect(quad!.topLeft.x, lessThan(100));
      expect(quad.topLeft.y, lessThan(100));
    });

    test('with previousQuad near the smaller rectangle, that one is chosen',
        () {
      const width = 200, height = 200;
      final mask = _twoRectangleMask(width, height);

      const previousQuad = Quad(
        topLeft: Pt(120, 120),
        topRight: Pt(174, 120),
        bottomRight: Pt(174, 164),
        bottomLeft: Pt(120, 164),
      );

      final quad = findDocumentQuad(mask, width, height,
          previousQuad: previousQuad);

      expect(quad, isNotNull);
      // The smaller bottom-right rectangle should now win, since it's the
      // valid candidate closest to previousQuad.
      expect(quad!.topLeft.x, greaterThan(100));
      expect(quad.topLeft.y, greaterThan(100));
    });
  });
}
