import 'dart:typed_data';

import 'image_filter_utils.dart' show clampPixel;

/// Shared primitives for the document filters in
/// `lib/core/image_filter/filters/document_filters.dart`.
///
/// Unlike the per-pixel helpers in `image_filter_utils.dart`, everything
/// here is a *global* or *neighbourhood* operation: it has to look at the
/// whole buffer (a histogram) or at a window around each pixel (a box
/// blur) before it can decide what any single pixel becomes. All functions
/// are pure and operate on flat typed buffers so they stay cheap to run
/// inside a `compute()` isolate, matching the style of
/// `lib/core/cv/edge_detection.dart`.

/// Summed-area table of a single-channel buffer.
///
/// The returned table is `(width + 1) * (height + 1)` so row/column 0 is an
/// all-zero border, which lets [boxSum] read a window sum without any
/// bounds branching. `Uint32List` is wide enough for the worst case: a
/// fully-white 255-valued image of ~16.8 megapixels still fits.
Uint32List integralImage(Uint8List gray, int width, int height) {
  final stride = width + 1;
  final table = Uint32List(stride * (height + 1));
  for (int y = 0; y < height; y++) {
    int rowSum = 0;
    final srcRow = y * width;
    final dstRow = (y + 1) * stride;
    final aboveRow = y * stride;
    for (int x = 0; x < width; x++) {
      rowSum += gray[srcRow + x];
      table[dstRow + x + 1] = table[aboveRow + x + 1] + rowSum;
    }
  }
  return table;
}

/// Sum of the [integralImage] window with inclusive corners
/// (`x0`, `y0`)-(`x1`, `y1`). Coordinates are clamped by the caller.
int boxSum(Uint32List table, int width, int x0, int y0, int x1, int y1) {
  final stride = width + 1;
  final top = y0 * stride;
  final bottom = (y1 + 1) * stride;
  return table[bottom + x1 + 1] -
      table[bottom + x0] -
      table[top + x1 + 1] +
      table[top + x0];
}

/// Box blur of a single-channel buffer with a `(2 * radius + 1)` square
/// window, in O(n) via [integralImage] rather than O(n * radius^2).
///
/// Used as a cheap illumination estimate: at a large radius the result is
/// the local paper/board brightness with the ink averaged away, which is
/// what the B&W and Whiteboard filters divide against.
Uint8List boxBlur(Uint8List gray, int width, int height, int radius) {
  final table = integralImage(gray, width, height);
  final out = Uint8List(width * height);
  for (int y = 0; y < height; y++) {
    final y0 = (y - radius) < 0 ? 0 : y - radius;
    final y1 = (y + radius) >= height ? height - 1 : y + radius;
    for (int x = 0; x < width; x++) {
      final x0 = (x - radius) < 0 ? 0 : x - radius;
      final x1 = (x + radius) >= width ? width - 1 : x + radius;
      final count = (x1 - x0 + 1) * (y1 - y0 + 1);
      out[y * width + x] = boxSum(table, width, x0, y0, x1, y1) ~/ count;
    }
  }
  return out;
}

/// 256-bin histogram of one channel of an RGBA buffer.
List<int> channelHistogram(Uint8List rgba, int channel) {
  final histogram = List<int>.filled(256, 0);
  for (int i = channel; i < rgba.length; i += 4) {
    histogram[rgba[i]]++;
  }
  return histogram;
}

/// 256-bin histogram of a single-channel buffer.
List<int> grayHistogram(Uint8List gray) {
  final histogram = List<int>.filled(256, 0);
  for (int i = 0; i < gray.length; i++) {
    histogram[gray[i]]++;
  }
  return histogram;
}

/// The values below which [lowFraction] of the samples fall and above which
/// [highFraction] of them fall, as `[low, high]`.
///
/// Clipping a small fraction off each end before stretching is what keeps a
/// single dust speck or specular highlight from pinning the whole range —
/// the standard "auto levels" trick.
List<int> percentileBounds(
  List<int> histogram,
  double lowFraction,
  double highFraction,
) {
  int total = 0;
  for (final count in histogram) {
    total += count;
  }
  if (total == 0) return const [0, 255];

  final lowTarget = (total * lowFraction).floor();
  final highTarget = (total * highFraction).floor();

  int low = 0, high = 255, seen = 0;
  for (int v = 0; v < 256; v++) {
    seen += histogram[v];
    if (seen > lowTarget) {
      low = v;
      break;
    }
  }
  seen = 0;
  for (int v = 255; v >= 0; v--) {
    seen += histogram[v];
    if (seen > highTarget) {
      high = v;
      break;
    }
  }
  if (high <= low) high = low + 1;
  return [low, high];
}

/// Builds a 256-entry lookup table that linearly stretches `[low, high]`
/// onto the full `0..255` range. A LUT is used rather than per-pixel maths
/// because every filter here applies the same mapping to millions of
/// pixels.
Uint8List stretchLut(int low, int high) {
  final lut = Uint8List(256);
  final span = (high - low).toDouble();
  for (int v = 0; v < 256; v++) {
    lut[v] = clampPixel((((v - low) / span) * 255).round());
  }
  return lut;
}

/// Applies [lut] to one channel of an RGBA buffer, in place.
void applyLutToChannel(Uint8List rgba, int channel, Uint8List lut) {
  for (int i = channel; i < rgba.length; i += 4) {
    rgba[i] = lut[rgba[i]];
  }
}

/// Applies [lut] to all three colour channels of an RGBA buffer, in place,
/// leaving alpha untouched.
void applyLutToRgb(Uint8List rgba, Uint8List lut) {
  for (int i = 0; i < rgba.length; i += 4) {
    rgba[i] = lut[rgba[i]];
    rgba[i + 1] = lut[rgba[i + 1]];
    rgba[i + 2] = lut[rgba[i + 2]];
  }
}

/// Box-averages a single-channel buffer down to [newWidth] x [newHeight].
///
/// The B&W and Whiteboard filters need a *local mean* / *illumination*
/// field, both of which are low-frequency by construction — computing them
/// on a downscaled copy and sampling back costs nothing in quality but
/// keeps the summed-area table off the order of tens of megabytes on a
/// full-resolution phone capture.
Uint8List downscaleGray(
  Uint8List gray,
  int width,
  int height,
  int newWidth,
  int newHeight,
) {
  final out = Uint8List(newWidth * newHeight);
  for (int y = 0; y < newHeight; y++) {
    final y0 = y * height ~/ newHeight;
    int y1 = (y + 1) * height ~/ newHeight;
    if (y1 <= y0) y1 = y0 + 1;
    for (int x = 0; x < newWidth; x++) {
      final x0 = x * width ~/ newWidth;
      int x1 = (x + 1) * width ~/ newWidth;
      if (x1 <= x0) x1 = x0 + 1;
      int sum = 0, count = 0;
      for (int sy = y0; sy < y1; sy++) {
        final row = sy * width;
        for (int sx = x0; sx < x1; sx++) {
          sum += gray[row + sx];
          count++;
        }
      }
      out[y * newWidth + x] = sum ~/ count;
    }
  }
  return out;
}
