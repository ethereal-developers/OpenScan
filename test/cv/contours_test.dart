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

  group('sortCorners', () {
    /// Every labelling this function produces has to be geometrically
    /// honest — the right-hand corners actually right of the left-hand
    /// ones, the bottom ones actually below the top ones — and has to use
    /// each input point exactly once.
    void expectWellFormed(Quad q) {
      final xs = q.points.map((p) => '${p.x},${p.y}').toSet();
      expect(xs.length, 4, reason: 'each corner used exactly once');
      expect(q.topRight.x, greaterThan(q.topLeft.x));
      expect(q.bottomRight.x, greaterThan(q.bottomLeft.x));
      expect(q.bottomLeft.y, greaterThan(q.topLeft.y));
      expect(q.bottomRight.y, greaterThan(q.topRight.y));
    }

    test('labels an axis-aligned square whatever order it arrives in', () {
      const tl = Pt(0, 0), tr = Pt(10, 0), br = Pt(10, 10), bl = Pt(0, 10);
      for (final input in [
        [tl, tr, br, bl],
        [br, bl, tl, tr],
        [bl, br, tr, tl],
        [tr, bl, br, tl],
      ]) {
        final q = sortCorners(input);
        expect(q.topLeft.x, tl.x);
        expect(q.topLeft.y, tl.y);
        expect(q.topRight.x, tr.x);
        expect(q.bottomRight.y, br.y);
        expect(q.bottomLeft.x, bl.x);
        expectWellFormed(q);
      }
    });

    test('keeps corners distinct and sensibly labelled when the document '
        'is rotated toward 45 degrees', () {
      // A square turned ~40 degrees: the classic sum/difference sort hands
      // the same physical point to two slots here.
      final rotated = [Pt(30, 0), Pt(100, 40), Pt(70, 110), Pt(0, 70)];
      for (final input in [
        rotated,
        rotated.reversed.toList(),
        [rotated[2], rotated[0], rotated[3], rotated[1]],
      ]) {
        expectWellFormed(sortCorners(input));
      }
    });

    test('keeps a perspective trapezoid in clockwise order', () {
      final q = sortCorners([Pt(95, 90), Pt(20, 10), Pt(5, 85), Pt(80, 15)]);
      expect(q.topLeft.x, 20);
      expect(q.topRight.x, 80);
      expect(q.bottomRight.x, 95);
      expect(q.bottomLeft.x, 5);
      expectWellFormed(q);
    });
  });

  group('pickBestQuad clustering', () {
    const width = 400, height = 400;

    Quad shifted(double dx, double dy) => Quad(
          topLeft: Pt(50 + dx, 50 + dy),
          topRight: Pt(350 + dx, 50 + dy),
          bottomRight: Pt(350 + dx, 350 + dy),
          bottomLeft: Pt(50 + dx, 350 + dy),
        );

    test('averages near-identical candidates instead of picking one', () {
      // The same shape found three times with slightly different corners,
      // as the threshold/epsilon sweep does every frame.
      final best = pickBestQuad(
        [shifted(-2, 0), shifted(0, 0), shifted(2, 0)],
        width,
        height,
      );

      expect(best, isNotNull);
      expect(best!.topLeft.x, closeTo(50, 0.001));
    });

    test('a shape several candidates agree on beats a marginally larger '
        'one-off', () {
      const oneOff = Quad(
        topLeft: Pt(45, 45),
        topRight: Pt(355, 45),
        bottomRight: Pt(355, 355),
        bottomLeft: Pt(45, 355),
      );

      final best = pickBestQuad(
        [oneOff, shifted(0, 0), shifted(1, 0), shifted(-1, 0), shifted(0, 1)],
        width,
        height,
      );

      expect(best, isNotNull);
      expect(best!.topLeft.x, closeTo(50, 1.0));
    });
  });
}
