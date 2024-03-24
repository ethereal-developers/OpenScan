import 'dart:math';
import 'dart:typed_data';

import 'utils.dart';

int clampPixel(int x) => x.clamp(0, 255);
void saturation(Uint8List bytes, num saturation) {
  saturation = (saturation < -1) ? -1 : saturation;
  for (int i = 0; i < bytes.length; i += 4) {
    num r = bytes[i], g = bytes[i + 1], b = bytes[i + 2];
    num gray =
        0.2989 * r + 0.5870 * g + 0.1140 * b; //weights from CCIR 601 spec
    bytes[i] =
        clampPixel((-gray * saturation + bytes[i] * (1 + saturation)).round());
    bytes[i + 1] = clampPixel(
        (-gray * saturation + bytes[i + 1] * (1 + saturation)).round());
    bytes[i + 2] = clampPixel(
        (-gray * saturation + bytes[i + 2] * (1 + saturation)).round());
  }
}

void hueRotation(Uint8List bytes, int degrees) {
  double U = cos(degrees * pi / 180);
  double W = sin(degrees * pi / 180);

  for (int i = 0; i < bytes.length; i += 4) {
    num r = bytes[i], g = bytes[i + 1], b = bytes[i + 2];
    bytes[i] = clampPixel(((.299 + .701 * U + .168 * W) * r +
            (.587 - .587 * U + .330 * W) * g +
            (.114 - .114 * U - .497 * W) * b)
        .round());
    bytes[i + 1] = clampPixel(((.299 - .299 * U - .328 * W) * r +
            (.587 + .413 * U + .035 * W) * g +
            (.114 - .114 * U + .292 * W) * b)
        .round());
    bytes[i + 2] = clampPixel(((.299 - .3 * U + 1.25 * W) * r +
            (.587 - .588 * U - 1.05 * W) * g +
            (.114 + .886 * U - .203 * W) * b)
        .round());
  }
}

void grayscale(Uint8List bytes) {
  for (int i = 0; i < bytes.length; i += 4) {
    int r = bytes[i], g = bytes[i + 1], b = bytes[i + 2];
    int avg = clampPixel((0.2126 * r + 0.7152 * g + 0.0722 * b).round());
    bytes[i] = avg;
    bytes[i + 1] = avg;
    bytes[i + 2] = avg;
  }
}

// Adj is 0 (unchanged) to 1 (sepia)
void sepia(Uint8List bytes, num adj) {
  for (int i = 0; i < bytes.length; i += 4) {
    int r = bytes[i], g = bytes[i + 1], b = bytes[i + 2];
    bytes[i] = clampPixel(
        ((r * (1 - (0.607 * adj))) + (g * .769 * adj) + (b * .189 * adj))
            .round());
    bytes[i + 1] = clampPixel(
        ((r * .349 * adj) + (g * (1 - (0.314 * adj))) + (b * .168 * adj))
            .round());
    bytes[i + 2] = clampPixel(
        ((r * .272 * adj) + (g * .534 * adj) + (b * (1 - (0.869 * adj))))
            .round());
  }
}

void invert(Uint8List bytes) {
  for (int i = 0; i < bytes.length; i += 4) {
    bytes[i] = clampPixel(255 - bytes[i]);
    bytes[i + 1] = clampPixel(255 - bytes[i + 1]);
    bytes[i + 2] = clampPixel(255 - bytes[i + 2]);
  }
}

/* adj should be -1 (darker) to 1 (lighter). 0 is unchanged. */
void brightness(Uint8List bytes, num adj) {
  adj = (adj > 1) ? 1 : adj;
  adj = (adj < -1) ? -1 : adj;
  adj = ~~(255 * adj).round();
  for (int i = 0; i < bytes.length; i += 4) {
    bytes[i] = clampPixel(bytes[i] + (adj as int));
    bytes[i + 1] = clampPixel(bytes[i + 1] + adj);
    bytes[i + 2] = clampPixel(bytes[i + 2] + adj);
  }
}

// Better result (slow) - adj should be < 1 (desaturated) to 1 (unchanged) and < 1
void hueSaturation(Uint8List bytes, num adj) {
  for (int i = 0; i < bytes.length; i += 4) {
    var hsv = rgbToHsv(bytes[i], bytes[i + 1], bytes[i + 2]);
    hsv[1] = (hsv[1] ?? 0) * adj;
    var rgb = hsvToRgb(hsv[0]!, hsv[1]!, hsv[2]!);
    bytes[i] = clampPixel(rgb[0] as int);
    bytes[i + 1] = clampPixel(rgb[1] as int);
    bytes[i + 2] = clampPixel(rgb[2] as int);
  }
}

// Contrast - the adj value should be -1 to 1
void contrast(Uint8List bytes, num adj) {
  adj *= 255;
  double factor = (259 * (adj + 255)) / (255 * (259 - adj));
  for (int i = 0; i < bytes.length; i += 4) {
    bytes[i] = clampPixel((factor * (bytes[i] - 128) + 128).round());
    bytes[i + 1] = clampPixel((factor * (bytes[i + 1] - 128) + 128).round());
    bytes[i + 2] = clampPixel((factor * (bytes[i + 2] - 128) + 128).round());
  }
}

// ColorOverlay - add a slight color overlay.
void colorOverlay(Uint8List bytes, num red, num green, num blue, num scale) {
  for (int i = 0; i < bytes.length; i += 4) {
    bytes[i] = clampPixel((bytes[i] - (bytes[i] - red) * scale).round());
    bytes[i + 1] =
        clampPixel((bytes[i + 1] - (bytes[i + 1] - green) * scale).round());
    bytes[i + 2] =
        clampPixel((bytes[i + 2] - (bytes[i + 2] - blue) * scale).round());
  }
}

// RGB Scale
void rgbScale(Uint8List bytes, num red, num green, num blue) {
  for (int i = 0; i < bytes.length; i += 4) {
    bytes[i] = clampPixel((bytes[i] * red).round());
    bytes[i + 1] = clampPixel((bytes[i + 1] * green).round());
    bytes[i + 2] = clampPixel((bytes[i + 2] * blue).round());
  }
}

// Convolute - weights are 3x3 matrix
void convolute(
    Uint8List pixels, int width, int height, List<num> weights, num bias) {
  var bytes = Uint8List.fromList(pixels);
  int side = sqrt(weights.length).round();
  int halfSide = ~~(side / 2).round() - side % 2;
  int sw = width;
  int sh = height;

  int w = sw;
  int h = sh;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      int sy = y;
      int sx = x;
      int dstOff = (y * w + x) * 4;
      num r = bias, g = bias, b = bias;
      for (int cy = 0; cy < side; cy++) {
        for (int cx = 0; cx < side; cx++) {
          int scy = sy + cy - halfSide;
          int scx = sx + cx - halfSide;

          if (scy >= 0 && scy < sh && scx >= 0 && scx < sw) {
            int srcOff = (scy * sw + scx) * 4;
            num wt = weights[cy * side + cx];

            r += bytes[srcOff] * wt;
            g += bytes[srcOff + 1] * wt;
            b += bytes[srcOff + 2] * wt;
          }
        }
      }
      pixels[dstOff] = clampPixel(r.round());
      pixels[dstOff + 1] = clampPixel(g.round());
      pixels[dstOff + 2] = clampPixel(b.round());
    }
  }
}

void addictiveColor(Uint8List bytes, int red, int green, int blue) {
  for (int i = 0; i < bytes.length; i += 4) {
    bytes[i] = clampPixel(bytes[i] + red);
    bytes[i + 1] = clampPixel(bytes[i + 1] + green);
    bytes[i + 2] = clampPixel(bytes[i + 2] + blue);
  }
}
