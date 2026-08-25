import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/image_filter/utils/document_filter_utils.dart';

/// Straightforward O(area) window sum, to check [boxSum] against.
int _bruteForceSum(Uint8List gray, int width, int x0, int y0, int x1, int y1) {
  int sum = 0;
  for (int y = y0; y <= y1; y++) {
    for (int x = x0; x <= x1; x++) {
      sum += gray[y * width + x];
    }
  }
  return sum;
}

void main() {
  group('integralImage / boxSum', () {
    test('matches a brute-force window sum for every window', () {
      const width = 17, height = 13;
      final random = Random(7);
      final gray = Uint8List.fromList(
        List.generate(width * height, (_) => random.nextInt(256)),
      );
      final table = integralImage(gray, width, height);

      for (int y0 = 0; y0 < height; y0 += 3) {
        for (int y1 = y0; y1 < height; y1 += 4) {
          for (int x0 = 0; x0 < width; x0 += 3) {
            for (int x1 = x0; x1 < width; x1 += 5) {
              expect(
                boxSum(table, width, x0, y0, x1, y1),
                _bruteForceSum(gray, width, x0, y0, x1, y1),
                reason: 'window ($x0,$y0)-($x1,$y1)',
              );
            }
          }
        }
      }
    });
  });

  group('boxBlur', () {
    test('averages a single bright pixel out across its window', () {
      final gray = Uint8List(81);
      gray[40] = 255; // centre of a 9x9 field
      final blurred = boxBlur(gray, 9, 9, 1);
      // The 3x3 window centred on the bright pixel holds 255 out of 9.
      expect(blurred[40], 255 ~/ 9);
      // A pixel far outside that window sees nothing of it.
      expect(blurred[0], 0);
    });
  });

  group('percentileBounds', () {
    test('clips the requested fraction off each end', () {
      // The bulk of the page sits between 60 and 200, with one stray black
      // pixel and one stray white one — a dust speck and a highlight.
      final histogram = List<int>.filled(256, 0);
      histogram[60] = 50;
      histogram[200] = 50;
      histogram[0] = 1;
      histogram[255] = 1;

      final bounds = percentileBounds(histogram, 0.02, 0.02);
      expect(bounds[0], 60, reason: 'the lone black outlier is clipped');
      expect(bounds[1], 200, reason: 'the lone white outlier is clipped');
    });

    test('returns the full range for an empty histogram', () {
      expect(percentileBounds(List<int>.filled(256, 0), 0.01, 0.01), [0, 255]);
    });

    test('never returns an empty range', () {
      final histogram = List<int>.filled(256, 0);
      histogram[42] = 1000;
      final bounds = percentileBounds(histogram, 0.005, 0.005);
      expect(bounds[1], greaterThan(bounds[0]));
    });
  });

  group('stretchLut', () {
    test('maps the given bounds onto the full range', () {
      final lut = stretchLut(50, 200);
      expect(lut[50], 0);
      expect(lut[200], 255);
      expect(lut[20], 0, reason: 'below the low bound clamps to black');
      expect(lut[240], 255, reason: 'above the high bound clamps to white');
    });
  });

  group('downscaleGray', () {
    test('box-averages down to the requested size', () {
      // 4x4 split into four 2x2 blocks of 0, 40, 80 and 120.
      final gray = Uint8List.fromList([
        0, 0, 40, 40, //
        0, 0, 40, 40, //
        80, 80, 120, 120, //
        80, 80, 120, 120, //
      ]);
      expect(downscaleGray(gray, 4, 4, 2, 2), [0, 40, 80, 120]);
    });
  });
}
