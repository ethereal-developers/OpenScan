import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'contours.dart';
import 'edge_detection.dart';
import 'models/detection_result.dart';
import 'models/quad.dart';

/// Longest edge (px) that detection runs at. Keeps the pure-Dart edge/
/// contour pipeline fast on full-resolution camera photos; the resulting
/// quad is scaled back up to the original image size before being
/// returned, since [DetectionSuccess.quad] is always in original-image
/// coordinates.
const int kDetectionMaxDimension = 700;

/// Entry point designed to be run via `compute()`. Takes the image file
/// path and returns a [DetectionResult] — never throws, so a caller can
/// always resolve the returned future without needing to guard against an
/// unhandled isolate exception.
Future<DetectionResult> detectDocumentIsolateEntry(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const DetectionFailure('Could not decode image');
    }

    final originalWidth = decoded.width;
    final originalHeight = decoded.height;

    final longestEdge = max(originalWidth, originalHeight).toDouble();
    final workingScale =
        longestEdge > kDetectionMaxDimension ? kDetectionMaxDimension / longestEdge : 1.0;
    final workWidth = max(1, (originalWidth * workingScale).round());
    final workHeight = max(1, (originalHeight * workingScale).round());

    final rgba = _downscaleRgba(
      decoded.getBytes(order: img.ChannelOrder.rgba),
      originalWidth,
      originalHeight,
      workWidth,
      workHeight,
    );

    final gray = rgbaToGrayscale(rgba, workWidth, workHeight);
    final quad = detectQuadFromGrayscale(gray, workWidth, workHeight);
    if (quad == null) {
      return DetectionNotFound(originalWidth, originalHeight);
    }

    final scaleBackX = originalWidth / workWidth;
    final scaleBackY = originalHeight / workHeight;
    return DetectionSuccess(
      quad.scaled(scaleBackX, scaleBackY),
      originalWidth,
      originalHeight,
    );
  } catch (e) {
    return DetectionFailure(e.toString());
  }
}

/// Runs the grayscale->blur->sobel->otsu->dilate->quad pipeline on an
/// already-grayscale buffer. Pure function, no I/O — shared by the
/// file-based one-shot entry point above and the live-scan persistent
/// isolate, so the edge/contour logic only exists in one place.
Quad? detectQuadFromGrayscale(Uint8List gray, int width, int height) {
  final blurred = gaussianBlur3(gray, width, height);
  final magnitude = sobelMagnitude(blurred, width, height);
  final t = otsuThreshold(magnitude);
  final binary = threshold(magnitude, t);
  final dilated = dilate(binary, width, height, 4);
  return findDocumentQuad(dilated, width, height);
}

/// Nearest-neighbor downsample of an RGBA buffer (stride 4).
Uint8List _downscaleRgba(
  Uint8List src,
  int srcW,
  int srcH,
  int dstW,
  int dstH,
) {
  if (srcW == dstW && srcH == dstH) return src;

  final dst = Uint8List(dstW * dstH * 4);
  for (int y = 0; y < dstH; y++) {
    final sy = (y * srcH / dstH).floor().clamp(0, srcH - 1);
    for (int x = 0; x < dstW; x++) {
      final sx = (x * srcW / dstW).floor().clamp(0, srcW - 1);
      final srcIdx = (sy * srcW + sx) * 4;
      final dstIdx = (y * dstW + x) * 4;
      dst[dstIdx] = src[srcIdx];
      dst[dstIdx + 1] = src[srcIdx + 1];
      dst[dstIdx + 2] = src[srcIdx + 2];
      dst[dstIdx + 3] = src[srcIdx + 3];
    }
  }
  return dst;
}
