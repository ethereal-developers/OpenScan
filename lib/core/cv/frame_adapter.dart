import 'dart:typed_data';

import 'package:camera_platform_interface/camera_platform_interface.dart'
    show ImageFormatGroup;

/// Longest edge (px) that live-scan detection runs at. Much smaller than
/// [kDetectionMaxDimension] (used for the one-shot file-based pipeline)
/// since this runs many times per second on live camera frames — the
/// overlay is guidance-only, final detection always reruns at full
/// resolution on the captured photo.
const int kLiveDetectionMaxDimension = 320;

/// Converts a live camera frame directly to a small grayscale buffer,
/// downsampling in the same pass so the full-resolution frame is never
/// materialized as grayscale. Pure function — only primitive/typed-data
/// arguments — so it's safe to call from the main isolate before handing
/// the (small) result off to a worker isolate, and trivially unit
/// testable without any `camera` plugin/widget dependency.
///
/// Returns `null` if [format] isn't one this adapter knows how to
/// convert — callers should treat that as "skip this frame".
Uint8List? grayscaleFromFrame({
  required Uint8List yPlaneOrBgraBytes,
  required int bytesPerRow,
  required int width,
  required int height,
  required ImageFormatGroup format,
  required int targetLongEdge,
}) {
  if (width <= 0 || height <= 0) return null;

  final scale = targetLongEdge / (width > height ? width : height);
  final dstW = scale < 1.0 ? (width * scale).round().clamp(1, width) : width;
  final dstH = scale < 1.0 ? (height * scale).round().clamp(1, height) : height;

  switch (format) {
    case ImageFormatGroup.yuv420:
      return _downsampleYPlane(
        yPlaneOrBgraBytes,
        bytesPerRow,
        width,
        height,
        dstW,
        dstH,
      );
    case ImageFormatGroup.bgra8888:
      return _downsampleBgra(
        yPlaneOrBgraBytes,
        bytesPerRow,
        width,
        height,
        dstW,
        dstH,
      );
    case ImageFormatGroup.jpeg:
    case ImageFormatGroup.nv21:
    case ImageFormatGroup.unknown:
      return null;
  }
}

/// The Y (luma) plane of a YUV420 frame is already grayscale — no color
/// conversion needed, just stride-aware nearest-neighbor downsampling.
/// [bytesPerRow] may be larger than [width] due to platform padding, so
/// every row must be indexed by its actual stride, never by [width].
Uint8List _downsampleYPlane(
  Uint8List yPlane,
  int bytesPerRow,
  int srcW,
  int srcH,
  int dstW,
  int dstH,
) {
  final dst = Uint8List(dstW * dstH);
  for (int y = 0; y < dstH; y++) {
    final sy = (y * srcH / dstH).floor().clamp(0, srcH - 1);
    final rowOffset = sy * bytesPerRow;
    for (int x = 0; x < dstW; x++) {
      final sx = (x * srcW / dstW).floor().clamp(0, srcW - 1);
      dst[y * dstW + x] = yPlane[rowOffset + sx];
    }
  }
  return dst;
}

/// Converts BGRA8888 (iOS) to grayscale using the same luminance weights
/// as [edge_detection.dart]'s `rgbaToGrayscale`, with byte order swapped
/// and stride-aware indexing (bytesPerRow may exceed width*4).
Uint8List _downsampleBgra(
  Uint8List bgra,
  int bytesPerRow,
  int srcW,
  int srcH,
  int dstW,
  int dstH,
) {
  final dst = Uint8List(dstW * dstH);
  for (int y = 0; y < dstH; y++) {
    final sy = (y * srcH / dstH).floor().clamp(0, srcH - 1);
    final rowOffset = sy * bytesPerRow;
    for (int x = 0; x < dstW; x++) {
      final sx = (x * srcW / dstW).floor().clamp(0, srcW - 1);
      final srcIdx = rowOffset + sx * 4;
      final b = bgra[srcIdx], g = bgra[srcIdx + 1], r = bgra[srcIdx + 2];
      dst[y * dstW + x] =
          (0.2126 * r + 0.7152 * g + 0.0722 * b).round().clamp(0, 255);
    }
  }
  return dst;
}
