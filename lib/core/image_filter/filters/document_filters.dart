import 'dart:math';
import 'dart:typed_data';

import '../../cv/edge_detection.dart' show rgbaToGrayscale;
import '../utils/document_filter_utils.dart';
import '../utils/image_filter_utils.dart' as image_filter_utils;
import 'filters.dart';

/// The colour modes offered by the scanner, in picker order.
///
/// These are *document* modes, not photo looks: the set mirrors what
/// mainstream scanner apps ship (Adobe Scan's Original/Auto/Greyscale/
/// Whiteboard, CamScanner's Original/Lighten/Magic-Colour/Greyscale/B&W).
/// Each filter's [Filter.name] doubles as its stable id — it is the key
/// used to cache previews and the value written to the database — so it is
/// deliberately not localized. The label shown to the user is resolved
/// separately by [FilterLabels] in the picker.
List<Filter> documentFiltersList = [
  OriginalFilter(),
  AutoFilter(),
  LightenFilter(),
  GrayscaleFilter(),
  BlackAndWhiteFilter(),
  WhiteboardFilter(),
];

/// The filter a page has when nothing has been applied to it.
Filter get defaultDocumentFilter => documentFiltersList.first;

/// Looks a filter up by its stored [Filter.name], falling back to
/// [defaultDocumentFilter] for an unknown or missing value (a page saved
/// by an older build, or one that has never been filtered).
Filter documentFilterByName(String? name) {
  if (name == null) return defaultDocumentFilter;
  return documentFiltersList.firstWhere(
    (filter) => filter.name == name,
    orElse: () => defaultDocumentFilter,
  );
}

/// Fraction of the darkest/brightest pixels ignored when auto-levelling, so
/// one dust speck or specular highlight cannot pin the whole range.
const double _clipFraction = 0.005;

/// Leaves the capture exactly as it was shot.
class OriginalFilter extends Filter {
  OriginalFilter() : super(name: 'Original');

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Nothing to do — this is what "no filter" means.
  }
}

/// Auto colour: per-channel auto-levels plus a touch of contrast.
///
/// Stretching each channel independently also neutralises the colour cast
/// of whatever light the page was shot under, which is why this reads as
/// "magic colour" — the paper goes white and the ink saturates without the
/// user picking a white balance.
class AutoFilter extends Filter {
  AutoFilter() : super(name: 'Auto');

  @override
  void apply(Uint8List pixels, int width, int height) {
    for (int channel = 0; channel < 3; channel++) {
      final bounds = percentileBounds(
        channelHistogram(pixels, channel),
        _clipFraction,
        _clipFraction,
      );
      applyLutToChannel(pixels, channel, stretchLut(bounds[0], bounds[1]));
    }
    image_filter_utils.contrast(pixels, 0.08);
  }
}

/// Lighten / save ink: keeps the colours but drives the paper to white.
///
/// Unlike [AutoFilter] the same scale is applied to all three channels, so
/// hues are preserved rather than rebalanced; only the brightness ceiling
/// moves. Above [_kneeStart] the pixel is then rolled smoothly towards
/// pure white, which is what makes the result cheap to print.
///
/// Both halves of that deliberately key off *luminance*, not the
/// individual channels: deciding per channel lets a pixel cross into the
/// background band on red but not on blue, which tints the seam — and a
/// hard cutoff draws a visible contour along wherever the paper happens to
/// cross it.
class LightenFilter extends Filter {
  LightenFilter() : super(name: 'Lighten');

  /// Luminance at which a pixel starts being treated as background.
  static const int _kneeStart = 200;

  @override
  void apply(Uint8List pixels, int width, int height) {
    final gray = rgbaToGrayscale(pixels, width, height);
    // Clip harder at the top than [AutoFilter] does: the goal is to find
    // the paper, not the brightest surviving pixel.
    final bounds = percentileBounds(grayHistogram(gray), 0.001, 0.05);
    final scaleLut = stretchLut(0, bounds[1]);

    // How far a pixel of each *original* luminance ends up into the
    // background band, as a 0-255 blend towards white. Smoothstepped so
    // the transition has no edge to see.
    final blendLut = Uint8List(256);
    for (int v = 0; v < 256; v++) {
      final scaled = scaleLut[v];
      if (scaled <= _kneeStart) continue;
      final t = (scaled - _kneeStart) / (255 - _kneeStart);
      blendLut[v] = (t * t * (3 - 2 * t) * 255).round();
    }

    for (int i = 0, pixel = 0; i < pixels.length; i += 4, pixel++) {
      final blend = blendLut[gray[pixel]];
      for (int channel = 0; channel < 3; channel++) {
        final scaled = scaleLut[pixels[i + channel]];
        pixels[i + channel] = scaled + ((255 - scaled) * blend) ~/ 255;
      }
    }
  }
}

/// Luminance-only, auto-levelled so text stays readable after the colour
/// information is gone.
class GrayscaleFilter extends Filter {
  GrayscaleFilter() : super(name: 'Grayscale');

  @override
  void apply(Uint8List pixels, int width, int height) {
    image_filter_utils.grayscale(pixels);
    final bounds = percentileBounds(
      channelHistogram(pixels, 0),
      _clipFraction,
      _clipFraction,
    );
    applyLutToRgb(pixels, stretchLut(bounds[0], bounds[1]));
  }
}

/// Pure black and white via Bradley-Roth adaptive thresholding.
///
/// A single global threshold fails on the thing phone scans always have —
/// uneven lighting, where one corner of the page is darker than the ink in
/// another. Comparing each pixel against the mean of a window around it
/// instead makes the decision locally, so a shadowed corner binarizes on
/// its own terms. This is also by far the smallest mode to store in a PDF.
class BlackAndWhiteFilter extends Filter {
  BlackAndWhiteFilter() : super(name: 'B&W');

  /// How far below the local mean a pixel must sit to count as ink.
  /// Bradley-Roth's paper uses 15%; the same value keeps thin strokes
  /// without speckling blank paper.
  static const double _bias = 0.15;

  @override
  void apply(Uint8List pixels, int width, int height) {
    final gray = rgbaToGrayscale(pixels, width, height);
    final mean = _localMeanField(gray, width, height);

    for (int y = 0; y < height; y++) {
      final meanRow = (y * mean.height ~/ height) * mean.width;
      final row = y * width;
      for (int x = 0; x < width; x++) {
        final local = mean.values[meanRow + (x * mean.width ~/ width)];
        final ink = gray[row + x] < local * (1 - _bias);
        final v = ink ? 0 : 255;
        final i = (row + x) * 4;
        pixels[i] = v;
        pixels[i + 1] = v;
        pixels[i + 2] = v;
      }
    }
  }
}

/// Whiteboard: divides out the illumination so shadows and glare flatten,
/// then pushes saturation and contrast so the marker strokes pop.
///
/// The illumination estimate is a heavily blurred copy of the image: at a
/// large enough radius the strokes average away and what is left is the
/// lighting across the board.
class WhiteboardFilter extends Filter {
  WhiteboardFilter() : super(name: 'Whiteboard');

  @override
  void apply(Uint8List pixels, int width, int height) {
    final gray = rgbaToGrayscale(pixels, width, height);
    final illumination = _illuminationField(gray, width, height);

    for (int y = 0; y < height; y++) {
      final fieldRow = (y * illumination.height ~/ height) * illumination.width;
      final row = y * width;
      for (int x = 0; x < width; x++) {
        final level =
            illumination.values[fieldRow + (x * illumination.width ~/ width)];
        // Guard the divisor: a genuinely black region would otherwise
        // blow up to pure white.
        final scale = 255 / max(level, 16);
        final i = (row + x) * 4;
        pixels[i] = image_filter_utils.clampPixel((pixels[i] * scale).round());
        pixels[i + 1] = image_filter_utils.clampPixel(
          (pixels[i + 1] * scale).round(),
        );
        pixels[i + 2] = image_filter_utils.clampPixel(
          (pixels[i + 2] * scale).round(),
        );
      }
    }

    image_filter_utils.saturation(pixels, 0.35);
    image_filter_utils.contrast(pixels, 0.15);
  }
}

/// A low-frequency single-channel field sampled back up to image size by
/// the filter that asked for it.
class _Field {
  _Field(this.values, this.width, this.height);

  final Uint8List values;
  final int width;
  final int height;
}

/// Longest edge the mean/illumination fields are computed at. Both fields
/// are smooth by construction, so working on a downscaled copy costs no
/// visible quality and keeps the summed-area table small enough to build
/// on a phone even for a full-resolution capture.
const int _fieldMaxEdge = 640;

_Field _downscaledGray(Uint8List gray, int width, int height) {
  final longest = max(width, height);
  if (longest <= _fieldMaxEdge) return _Field(gray, width, height);
  final scale = _fieldMaxEdge / longest;
  final w = max(1, (width * scale).round());
  final h = max(1, (height * scale).round());
  return _Field(downscaleGray(gray, width, height, w, h), w, h);
}

/// Mean of a window roughly an eighth of the page wide around each pixel —
/// the window size Bradley-Roth recommends for text.
_Field _localMeanField(Uint8List gray, int width, int height) {
  final small = _downscaledGray(gray, width, height);
  final radius = max(2, small.width ~/ 16);
  return _Field(
    boxBlur(small.values, small.width, small.height, radius),
    small.width,
    small.height,
  );
}

/// Much wider window than [_localMeanField]: here the strokes have to
/// average away entirely, leaving only the lighting.
_Field _illuminationField(Uint8List gray, int width, int height) {
  final small = _downscaledGray(gray, width, height);
  final radius = max(4, min(small.width, small.height) ~/ 6);
  return _Field(
    boxBlur(small.values, small.width, small.height, radius),
    small.width,
    small.height,
  );
}
