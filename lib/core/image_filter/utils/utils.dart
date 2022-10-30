import 'dart:math';

List<num?> rgbToHsv(num r, num g, num b) {
  r /= 255;
  g /= 255;
  b /= 255;

  num _max = max(
    r,
    max(g, b),
  );
  num _min = min(
    r,
    max(g, b),
  );
  num? h, s, v = _max;

  num d = _max - _min;
  s = _max == 0 ? 0 : d / _max;

  if (max == min) {
    h = 0; // achromatic
  } else {
    if (_max == r) {
      h = (g - b) / d + (g < b ? 6 : 0);
    } else if (_max == g) {
      h = (b - r) / d + 2;
    } else if (_max == b) {
      h = (r - g) / d + 4;
    }
  }

  h = h ?? 0 / 6;

  return [h, s, v];
}

List<num> hsvToRgb(num h, num s, num v) {
  int r = 0, g = 0, b = 0;

  int i = (h * 6).floor();
  int f = h * 6 - i as int;
  int p = v * (1 - s) as int;
  int q = v * (1 - f * s) as int;
  int t = v * (1 - (1 - f) * s) as int;

  switch (i % 6) {
    case 0:
      r = v as int;
      g = t;
      b = p;
      break;
    case 1:
      r = q;
      g = v as int;
      b = p;
      break;
    case 2:
      r = p;
      g = v as int;
      b = t;
      break;
    case 3:
      r = p;
      g = q;
      b = v as int;
      break;
    case 4:
      r = t;
      g = p;
      b = v as int;
      break;
    case 5:
      r = v as int;
      g = p;
      b = q;
      break;
  }

  return [r * 255, g * 255, b * 255];
}
