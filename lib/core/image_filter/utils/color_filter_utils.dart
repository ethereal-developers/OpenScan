import 'dart:math';

import '../models.dart';
import 'utils.dart' as imageUtils;

int clampPixel(int x) => x.clamp(0, 255);
RGBA saturation(RGBA color, num saturation) {
  saturation = (saturation < -1) ? -1 : saturation;
  num gray = 0.2989 * color.red +
      0.5870 * color.green +
      0.1140 * color.blue; //weights from CCIR 601 spec
  return new RGBA(
    red:
        clampPixel((-gray * saturation + color.red * (1 + saturation)).round()),
    green: clampPixel(
        (-gray * saturation + color.green * (1 + saturation)).round()),
    blue: clampPixel(
        (-gray * saturation + color.blue * (1 + saturation)).round()),
    alpha: color.alpha,
  );
}

RGBA hueRotation(RGBA color, int degrees) {
  double U = cos(degrees * pi / 180);
  double W = sin(degrees * pi / 180);

  num r = color.red, g = color.green, b = color.blue;
  return new RGBA(
    red: clampPixel(((.299 + .701 * U + .168 * W) * r +
            (.587 - .587 * U + .330 * W) * g +
            (.114 - .114 * U - .497 * W) * b)
        .round()),
    green: clampPixel(((.299 - .299 * U - .328 * W) * r +
            (.587 + .413 * U + .035 * W) * g +
            (.114 - .114 * U + .292 * W) * b)
        .round()),
    blue: clampPixel(((.299 - .3 * U + 1.25 * W) * r +
            (.587 - .588 * U - 1.05 * W) * g +
            (.114 + .886 * U - .203 * W) * b)
        .round()),
    alpha: color.alpha,
  );
}

RGBA grayscale(RGBA color) {
  int avg = clampPixel(
      (0.2126 * color.red + 0.7152 * color.green + 0.0722 * color.blue)
          .round());
  return new RGBA(
    red: avg,
    green: avg,
    blue: avg,
    alpha: color.alpha,
  );
}

// Adj is 0 (unchanged) to 1 (sepia)
RGBA sepia(RGBA color, num adj) {
  int r = color.red, g = color.green, b = color.blue;
  return new RGBA(
      red: clampPixel(
          ((r * (1 - (0.607 * adj))) + (g * .769 * adj) + (b * .189 * adj))
              .round()),
      green: clampPixel(
          ((r * .349 * adj) + (g * (1 - (0.314 * adj))) + (b * .168 * adj))
              .round()),
      blue: clampPixel(
          ((r * .272 * adj) + (g * .534 * adj) + (b * (1 - (0.869 * adj))))
              .round()),
      alpha: color.alpha);
}

RGBA invert(RGBA color) {
  return new RGBA(
    red: clampPixel(255 - color.red),
    green: clampPixel(255 - color.green),
    blue: clampPixel(255 - color.blue),
    alpha: color.alpha,
  );
}

/* adj should be -1 (darker) to 1 (lighter). 0 is unchanged. */
RGBA brightness(RGBA color, num adj) {
  adj = (adj > 1) ? 1 : adj;
  adj = (adj < -1) ? -1 : adj;
  adj = ~~(255 * adj).round();
  return new RGBA(
      red: clampPixel(color.red + (adj as int)),
      green: clampPixel(color.green + adj),
      blue: clampPixel(color.blue + adj),
      alpha: color.alpha);
}

// Better result (slow) - adj should be < 1 (desaturated) to 1 (unchanged) and < 1
RGBA hueSaturation(RGBA color, num adj) {
  var hsv = imageUtils.rgbToHsv(color.red, color.green, color.blue);
  hsv[1] = (hsv[1] ?? 0) * adj;
  var rgb = imageUtils.hsvToRgb(hsv[0]!, hsv[1]!, hsv[2]!);
  return new RGBA(
    red: clampPixel(rgb[0] as int),
    green: clampPixel(rgb[1] as int),
    blue: clampPixel(rgb[2] as int),
    alpha: color.alpha,
  );
}

// Contrast - the adj value should be -1 to 1
RGBA contrast(RGBA color, num adj) {
  adj *= 255;
  double factor = (259 * (adj + 255)) / (255 * (259 - adj));
  return new RGBA(
    red: clampPixel((factor * (color.red - 128) + 128).round()),
    green: clampPixel((factor * (color.green - 128) + 128).round()),
    blue: clampPixel((factor * (color.blue - 128) + 128).round()),
    alpha: color.alpha,
  );
}

// ColorOverlay - add a slight color overlay.
RGBA colorOverlay(RGBA color, num red, num green, num blue, num scale) {
  return new RGBA(
    red: clampPixel((color.red - (color.red - red) * scale).round()),
    green: clampPixel((color.green - (color.green - green) * scale).round()),
    blue: clampPixel((color.blue - (color.blue - blue) * scale).round()),
    alpha: color.alpha,
  );
}

// RGB Scale
RGBA rgbScale(RGBA color, num red, num green, num blue) {
  return new RGBA(
    red: clampPixel((color.red * red).round()),
    green: clampPixel((color.green * green).round()),
    blue: clampPixel((color.blue * blue).round()),
    alpha: color.alpha,
  );
}

RGBA addictiveColor(RGBA color, int red, int green, int blue) {
  return new RGBA(
    red: clampPixel(color.red + red),
    green: clampPixel(color.green + green),
    blue: clampPixel(color.blue + blue),
    alpha: color.alpha,
  );
}
