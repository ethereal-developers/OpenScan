import 'dart:typed_data';

/// Per-pixel primitives shared by the document filters in
/// `lib/core/image_filter/filters/document_filters.dart`. Each rewrites an
/// RGBA buffer (stride 4) in place and leaves alpha untouched.

int clampPixel(int x) => x.clamp(0, 255);

/// Pushes colours away from (positive) or towards (negative) grey.
void saturation(Uint8List bytes, num saturation) {
  saturation = (saturation < -1) ? -1 : saturation;
  for (int i = 0; i < bytes.length; i += 4) {
    num r = bytes[i], g = bytes[i + 1], b = bytes[i + 2];
    num gray =
        0.2989 * r + 0.5870 * g + 0.1140 * b; //weights from CCIR 601 spec
    bytes[i] = clampPixel(
      (-gray * saturation + bytes[i] * (1 + saturation)).round(),
    );
    bytes[i + 1] = clampPixel(
      (-gray * saturation + bytes[i + 1] * (1 + saturation)).round(),
    );
    bytes[i + 2] = clampPixel(
      (-gray * saturation + bytes[i + 2] * (1 + saturation)).round(),
    );
  }
}

/// Replaces every pixel with its luminance, written to all three channels
/// so the buffer stays RGBA.
void grayscale(Uint8List bytes) {
  for (int i = 0; i < bytes.length; i += 4) {
    int r = bytes[i], g = bytes[i + 1], b = bytes[i + 2];
    int avg = clampPixel((0.2126 * r + 0.7152 * g + 0.0722 * b).round());
    bytes[i] = avg;
    bytes[i + 1] = avg;
    bytes[i + 2] = avg;
  }
}

/// Contrast around mid-grey; [adj] runs -1 (flat) to 1 (harsh).
void contrast(Uint8List bytes, num adj) {
  adj *= 255;
  double factor = (259 * (adj + 255)) / (255 * (259 - adj));
  for (int i = 0; i < bytes.length; i += 4) {
    bytes[i] = clampPixel((factor * (bytes[i] - 128) + 128).round());
    bytes[i + 1] = clampPixel((factor * (bytes[i + 1] - 128) + 128).round());
    bytes[i + 2] = clampPixel((factor * (bytes[i + 2] - 128) + 128).round());
  }
}
