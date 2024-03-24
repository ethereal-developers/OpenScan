import 'dart:typed_data';

import 'color_filters.dart';
import '../models.dart';
import '../utils/color_filter_utils.dart' as color_filter_utils;
import '../utils/image_filter_utils.dart' as image_filter_utils;

import 'image_filters.dart';

///The [ContrastSubFilter] class is a SubFilter class to apply [contrast] to an image.
class ContrastSubFilter extends ColorSubFilter with ImageSubFilter {
  final num contrast;
  ContrastSubFilter(this.contrast);

  ///Apply the [ContrastSubFilter] to an Image.
  @override
  void apply(Uint8List pixels, int width, int height) =>
      image_filter_utils.contrast(pixels, contrast);

  ///Apply the [ContrastSubFilter] to a color.
  @override
  RGBA applyFilter(RGBA color) => color_filter_utils.contrast(color, contrast);
}

///The [BrightnessSubFilter] class is a SubFilter class to apply [brightness] to an image.
class BrightnessSubFilter extends ColorSubFilter with ImageSubFilter {
  final num brightness;
  BrightnessSubFilter(this.brightness);

  ///Apply the [BrightnessSubFilter] to an Image.
  @override
  void apply(Uint8List pixels, int width, int height) =>
      image_filter_utils.brightness(pixels, brightness);

  ///Apply the [BrightnessSubFilter] to a color.
  @override
  RGBA applyFilter(RGBA color) =>
      color_filter_utils.brightness(color, brightness);
}

///The [SaturationSubFilter] class is a SubFilter class to apply [saturation] to an image.
class SaturationSubFilter extends ColorSubFilter with ImageSubFilter {
  final num saturation;
  SaturationSubFilter(this.saturation);

  ///Apply the [SaturationSubFilter] to an Image.
  @override
  void apply(Uint8List pixels, int width, int height) =>
      image_filter_utils.saturation(pixels, saturation);

  ///Apply the [SaturationSubFilter] to a saturation.
  @override
  RGBA applyFilter(RGBA color) =>
      color_filter_utils.saturation(color, saturation);
}

///The [SepiaSubFilter] class is a SubFilter class to apply [sepia] to an image.
class SepiaSubFilter extends ColorSubFilter with ImageSubFilter {
  final num sepia;
  SepiaSubFilter(this.sepia);

  ///Apply the [SepiaSubFilter] to an Image.
  @override
  void apply(Uint8List pixels, int width, int height) =>
      image_filter_utils.sepia(pixels, sepia);

  ///Apply the [SepiaSubFilter] to a color.
  @override
  RGBA applyFilter(RGBA color) => color_filter_utils.sepia(color, sepia);
}

///The [GrayScaleSubFilter] class is a SubFilter class to apply GrayScale to an image.
class GrayScaleSubFilter extends ColorSubFilter with ImageSubFilter {
  ///Apply the [GrayScaleSubFilter] to an Image.
  @override
  void apply(Uint8List pixels, int width, int height) =>
      image_filter_utils.grayscale(pixels);

  ///Apply the [GrayScaleSubFilter] to a color.
  @override
  RGBA applyFilter(RGBA color) => color_filter_utils.grayscale(color);
}

///The [InvertSubFilter] class is a SubFilter class to invert an image.
class InvertSubFilter extends ColorSubFilter with ImageSubFilter {
  ///Apply the [InvertSubFilter] to an Image.
  @override
  void apply(Uint8List pixels, int width, int height) =>
      image_filter_utils.invert(pixels);

  ///Apply the [InvertSubFilter] to a color.
  @override
  RGBA applyFilter(RGBA color) => color_filter_utils.invert(color);
}

///The [HueRotationSubFilter] class is a SubFilter class to rotate hue in [degrees].
class HueRotationSubFilter extends ColorSubFilter with ImageSubFilter {
  final int degrees;
  HueRotationSubFilter(this.degrees);

  ///Apply the [HueRotationSubFilter] to an Image.
  @override
  void apply(Uint8List pixels, int width, int height) =>
      image_filter_utils.hueRotation(pixels, degrees);

  ///Apply the [HueRotationSubFilter] to a color.
  @override
  RGBA applyFilter(RGBA color) =>
      color_filter_utils.hueRotation(color, degrees);
}

///The [AddictiveColorSubFilter] class is a SubFilter class to emphasize a color using [red], [green] and [b] values.
class AddictiveColorSubFilter extends ColorSubFilter with ImageSubFilter {
  final int red;
  final int green;
  final int blue;
  AddictiveColorSubFilter(this.red, this.green, this.blue);

  ///Apply the [AddictiveColorSubFilter] to an Image.
  @override
  void apply(Uint8List pixels, int width, int height) =>
      image_filter_utils.addictiveColor(pixels, red, green, blue);

  ///Apply the [AddictiveColorSubFilter] to a color.
  @override
  RGBA applyFilter(RGBA color) =>
      color_filter_utils.addictiveColor(color, red, green, blue);
}

///The [RGBScaleSubFilter] class is a SubFilter class to scale RGB values of every pixels in an image.
class RGBScaleSubFilter extends ColorSubFilter with ImageSubFilter {
  final num red;
  final num green;
  final num blue;
  RGBScaleSubFilter(this.red, this.green, this.blue);

  ///Apply the [RGBScaleSubFilter] to an Image.
  @override
  void apply(Uint8List pixels, int width, int height) =>
      image_filter_utils.rgbScale(pixels, red, green, blue);

  ///Apply the [RGBScaleSubFilter] to a color.
  @override
  RGBA applyFilter(RGBA color) =>
      color_filter_utils.rgbScale(color, red, green, blue);
}

///The [RGBOverlaySubFilter] class is a SubFilter class to apply an overlay to an image.
class RGBOverlaySubFilter extends ColorSubFilter with ImageSubFilter {
  final num red;
  final num green;
  final num blue;
  final num scale;
  RGBOverlaySubFilter(this.red, this.green, this.blue, this.scale);

  ///Apply the [RGBOverlaySubFilter] to an Image.
  @override
  void apply(Uint8List pixels, int width, int height) =>
      image_filter_utils.colorOverlay(pixels, red, green, blue, scale);

  ///Apply the [RGBOverlaySubFilter] to a color.
  @override
  RGBA applyFilter(RGBA color) =>
      color_filter_utils.colorOverlay(color, red, green, blue, scale);
}