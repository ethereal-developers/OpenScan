import 'dart:math';
import 'dart:typed_data';

/// Pure-Dart replacements for the OpenCV grayscale/blur/edge/dilate/
/// threshold steps that used to run natively via
/// `Imgproc.cvtColor`/`GaussianBlur`/`Canny`/`dilate`/`threshold`.
///
/// All functions operate on flat byte buffers (matching the RGBA/
/// single-channel array patterns already used elsewhere in this codebase,
/// e.g. `lib/core/image_filter/utils/image_filter_utils.dart`) rather than
/// package-specific image objects, so they stay cheap to run inside an
/// isolate and easy to unit test.

/// Converts an RGBA buffer (stride 4) to a single-channel luminance buffer.
Uint8List rgbaToGrayscale(Uint8List rgba, int width, int height) {
  final gray = Uint8List(width * height);
  for (int i = 0, p = 0; p < gray.length; i += 4, p++) {
    final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
    gray[p] = (0.2126 * r + 0.7152 * g + 0.0722 * b).round().clamp(0, 255);
  }
  return gray;
}

/// A 3x3 Gaussian blur (approximating OpenCV's `GaussianBlur(3x3)`).
Uint8List gaussianBlur3(Uint8List gray, int width, int height) {
  final out = Uint8List(width * height);
  const kernel = [1, 2, 1, 2, 4, 2, 1, 2, 1];
  const kernelSum = 16;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int sum = 0;
      int k = 0;
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final sx = (x + dx).clamp(0, width - 1);
          final sy = (y + dy).clamp(0, height - 1);
          sum += gray[sy * width + sx] * kernel[k++];
        }
      }
      out[y * width + x] = (sum / kernelSum).round().clamp(0, 255);
    }
  }
  return out;
}

/// Sobel gradient magnitude, clamped to 0-255. Stands in for OpenCV's
/// `Canny` step: rather than reproducing full non-max-suppression plus
/// hysteresis, the magnitude image is thresholded (see [otsuThreshold]) and
/// then dilated/closed, which is sufficient to find the outer boundary of a
/// photographed document.
Uint8List sobelMagnitude(Uint8List gray, int width, int height) {
  final out = Uint8List(width * height);

  int at(int x, int y) {
    final cx = x.clamp(0, width - 1);
    final cy = y.clamp(0, height - 1);
    return gray[cy * width + cx];
  }

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final gx = -at(x - 1, y - 1) -
          2 * at(x - 1, y) -
          at(x - 1, y + 1) +
          at(x + 1, y - 1) +
          2 * at(x + 1, y) +
          at(x + 1, y + 1);
      final gy = -at(x - 1, y - 1) -
          2 * at(x, y - 1) -
          at(x + 1, y - 1) +
          at(x - 1, y + 1) +
          2 * at(x, y + 1) +
          at(x + 1, y + 1);
      final mag = sqrt((gx * gx + gy * gy).toDouble());
      out[y * width + x] = mag.clamp(0.0, 255.0).round();
    }
  }
  return out;
}

/// Otsu's method: picks a global threshold that best separates a bimodal
/// histogram, standing in for OpenCV's `THRESH_TRIANGLE`.
int otsuThreshold(Uint8List image) {
  final hist = List<int>.filled(256, 0);
  for (final v in image) {
    hist[v]++;
  }

  final total = image.length;
  double sum = 0;
  for (int i = 0; i < 256; i++) {
    sum += i * hist[i];
  }

  double sumB = 0;
  int wB = 0;
  double maxVariance = -1;
  int threshold = 128;

  for (int t = 0; t < 256; t++) {
    wB += hist[t];
    if (wB == 0) continue;
    final wF = total - wB;
    if (wF == 0) break;

    sumB += t * hist[t];
    final mB = sumB / wB;
    final mF = (sum - sumB) / wF;
    final between = wB * wF * (mB - mF) * (mB - mF);
    if (between > maxVariance) {
      maxVariance = between;
      threshold = t;
    }
  }
  return threshold;
}

/// Binarizes [image] against threshold [t]: returns a 0/1 mask.
Uint8List threshold(Uint8List image, int t) {
  final out = Uint8List(image.length);
  for (int i = 0; i < image.length; i++) {
    out[i] = image[i] >= t ? 1 : 0;
  }
  return out;
}

/// Binary dilation with a roughly `(2*radius+1)` square structuring
/// element, implemented as two separable max-filter passes (O(n*radius)
/// instead of O(n*radius^2)) — stands in for OpenCV's `dilate(9x9)`.
Uint8List dilate(Uint8List mask, int width, int height, int radius) {
  final rowPass = Uint8List(width * height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int v = 0;
      for (int dx = -radius; dx <= radius && v == 0; dx++) {
        final sx = x + dx;
        if (sx < 0 || sx >= width) continue;
        if (mask[y * width + sx] == 1) v = 1;
      }
      rowPass[y * width + x] = v;
    }
  }

  final out = Uint8List(width * height);
  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      int v = 0;
      for (int dy = -radius; dy <= radius && v == 0; dy++) {
        final sy = y + dy;
        if (sy < 0 || sy >= height) continue;
        if (rowPass[sy * width + x] == 1) v = 1;
      }
      out[y * width + x] = v;
    }
  }
  return out;
}
