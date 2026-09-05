import 'dart:math';
import 'dart:typed_data';

import 'package:camera_platform_interface/camera_platform_interface.dart'
    show ImageFormatGroup;
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/cv/document_detector.dart';
import 'package:openscan/core/cv/frame_adapter.dart';

/// Builds a Y-plane buffer with a deliberate row stride larger than the
/// logical width (as real camera frames on many devices have), so tests
/// exercise the stride-aware indexing path rather than assuming
/// bytesPerRow == width.
Uint8List _buildPaddedYPlane({
  required int width,
  required int height,
  required int bytesPerRow,
  required int Function(int x, int y) valueAt,
}) {
  final buf = Uint8List(bytesPerRow * height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      buf[y * bytesPerRow + x] = valueAt(x, y);
    }
  }
  return buf;
}

Uint8List _buildPaddedBgra({
  required int width,
  required int height,
  required int bytesPerRow,
  required (int b, int g, int r) Function(int x, int y) pixelAt,
}) {
  final buf = Uint8List(bytesPerRow * height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final (b, g, r) = pixelAt(x, y);
      final idx = y * bytesPerRow + x * 4;
      buf[idx] = b;
      buf[idx + 1] = g;
      buf[idx + 2] = r;
      buf[idx + 3] = 255;
    }
  }
  return buf;
}

void main() {
  group('grayscaleFromFrame (yuv420)', () {
    test('downsamples the Y-plane using stride-aware indexing', () {
      const srcW = 64, srcH = 48, bytesPerRow = 80; // padded stride
      final yPlane = _buildPaddedYPlane(
        width: srcW,
        height: srcH,
        bytesPerRow: bytesPerRow,
        valueAt: (x, y) => x, // horizontal gradient, easy to predict
      );

      final gray = grayscaleFromFrame(
        yPlaneOrBgraBytes: yPlane,
        bytesPerRow: bytesPerRow,
        width: srcW,
        height: srcH,
        format: ImageFormatGroup.yuv420,
        targetLongEdge: 32,
      );

      expect(gray, isNotNull);
      // Longest edge (srcW=64) scales to 32 -> scale 0.5, so dst is 32x24.
      const dstW = 32, dstH = 24;
      expect(gray!.length, dstW * dstH);

      // Sample a few destination pixels and confirm they equal the
      // nearest-neighbor source column's gradient value (== source x).
      for (final dx in [0, 10, 31]) {
        final sx = (dx * srcW / dstW).floor().clamp(0, srcW - 1);
        expect(gray[dx], sx, reason: 'dst x=$dx should map to src x=$sx');
      }
    });

    test('leaves frame unscaled when already below targetLongEdge', () {
      const srcW = 20, srcH = 10, bytesPerRow = 20;
      final yPlane = _buildPaddedYPlane(
        width: srcW,
        height: srcH,
        bytesPerRow: bytesPerRow,
        valueAt: (x, y) => 42,
      );

      final gray = grayscaleFromFrame(
        yPlaneOrBgraBytes: yPlane,
        bytesPerRow: bytesPerRow,
        width: srcW,
        height: srcH,
        format: ImageFormatGroup.yuv420,
        targetLongEdge: 320,
      );

      expect(gray, isNotNull);
      expect(gray!.length, srcW * srcH);
      expect(gray.every((v) => v == 42), isTrue);
    });
  });

  group('grayscaleFromFrame (bgra8888)', () {
    test('applies luminance weights with byte-order-aware, stride-aware indexing', () {
      const srcW = 16, srcH = 16, bytesPerRow = 16 * 4 + 32; // padded stride
      final bgra = _buildPaddedBgra(
        width: srcW,
        height: srcH,
        bytesPerRow: bytesPerRow,
        pixelAt: (x, y) => (0, 0, 255), // pure red (B=0,G=0,R=255)
      );

      final gray = grayscaleFromFrame(
        yPlaneOrBgraBytes: bgra,
        bytesPerRow: bytesPerRow,
        width: srcW,
        height: srcH,
        format: ImageFormatGroup.bgra8888,
        targetLongEdge: 16,
      );

      expect(gray, isNotNull);
      // Pure red -> luminance = round(0.2126 * 255) = 54.
      final expected = (0.2126 * 255).round();
      expect(gray!.every((v) => v == expected), isTrue);
    });
  });

  group('grayscaleFromFrame box-average downsampling', () {
    test('reduces variance vs. nearest-neighbor on noisy input', () {
      const srcW = 64, srcH = 64, bytesPerRow = 64;
      final random = Random(42);
      final yPlane = _buildPaddedYPlane(
        width: srcW,
        height: srcH,
        bytesPerRow: bytesPerRow,
        // Uncorrelated per-pixel noise around a mid-gray baseline —
        // averaging a neighborhood should measurably reduce the spread of
        // the downsampled values relative to picking one raw sample each.
        valueAt: (x, y) => 128 + (random.nextInt(41) - 20),
      );

      final gray = grayscaleFromFrame(
        yPlaneOrBgraBytes: yPlane,
        bytesPerRow: bytesPerRow,
        width: srcW,
        height: srcH,
        format: ImageFormatGroup.yuv420,
        targetLongEdge: 16,
      );
      expect(gray, isNotNull);

      const dstW = 16, dstH = 16;
      final nearestNeighbor = Uint8List(dstW * dstH);
      for (int y = 0; y < dstH; y++) {
        final sy = (y * srcH / dstH).floor().clamp(0, srcH - 1);
        for (int x = 0; x < dstW; x++) {
          final sx = (x * srcW / dstW).floor().clamp(0, srcW - 1);
          nearestNeighbor[y * dstW + x] = yPlane[sy * bytesPerRow + sx];
        }
      }

      double variance(Uint8List data) {
        final mean = data.reduce((a, b) => a + b) / data.length;
        final sumSq =
            data.fold<double>(0, (s, v) => s + pow(v - mean, 2).toDouble());
        return sumSq / data.length;
      }

      expect(variance(gray!), lessThan(variance(nearestNeighbor)));
    });

    test('still detects a document-shaped step edge after downsampling', () {
      const srcW = 640, srcH = 480, bytesPerRow = 640;
      final yPlane = _buildPaddedYPlane(
        width: srcW,
        height: srcH,
        bytesPerRow: bytesPerRow,
        valueAt: (x, y) =>
            (x >= 100 && x < 540 && y >= 80 && y < 400) ? 230 : 20,
      );

      final gray = grayscaleFromFrame(
        yPlaneOrBgraBytes: yPlane,
        bytesPerRow: bytesPerRow,
        width: srcW,
        height: srcH,
        format: ImageFormatGroup.yuv420,
        targetLongEdge: 320,
      );
      expect(gray, isNotNull);

      const dstW = 320, dstH = 240; // 640x480 scaled to targetLongEdge=320
      final quad = detectQuadFromGrayscale(gray!, dstW, dstH);

      expect(quad, isNotNull,
          reason: 'box-averaged downsample should not blur the step edge '
              'away entirely');
    });
  });

  group('grayscaleFromFrame (unsupported formats)', () {
    test('returns null for jpeg/nv21/unknown', () {
      for (final format in [
        ImageFormatGroup.jpeg,
        ImageFormatGroup.nv21,
        ImageFormatGroup.unknown,
      ]) {
        final result = grayscaleFromFrame(
          yPlaneOrBgraBytes: Uint8List(100),
          bytesPerRow: 10,
          width: 10,
          height: 10,
          format: format,
          targetLongEdge: 320,
        );
        expect(result, isNull, reason: '$format should be unsupported');
      }
    });

    test('returns null for non-positive dimensions', () {
      final result = grayscaleFromFrame(
        yPlaneOrBgraBytes: Uint8List(0),
        bytesPerRow: 0,
        width: 0,
        height: 0,
        format: ImageFormatGroup.yuv420,
        targetLongEdge: 320,
      );
      expect(result, isNull);
    });
  });
}
