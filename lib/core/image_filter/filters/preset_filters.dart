import 'dart:typed_data';

import 'color_filters.dart';
import 'filters.dart';
import 'subfilters.dart';

// NoFilter: No filter
class Original extends ColorFilter {
  Original() : super(name: "Original");

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Do nothing
  }
}

// Clarendon: adds light to lighter areas and dark to darker areas
class ClarendonFilter extends ColorFilter {
  ClarendonFilter() : super(name: "Clarendon") {
    subFilters.add(new BrightnessSubFilter(.1));
    subFilters.add(new ContrastSubFilter(.1));
    subFilters.add(new SaturationSubFilter(.15));
  }
}

class AddictiveRedFilter extends ColorFilter {
  AddictiveRedFilter() : super(name: "AddictiveRed") {
    subFilters.add(new AddictiveColorSubFilter(50, 0, 0));
  }
}

class AddictiveBlueFilter extends ColorFilter {
  AddictiveBlueFilter() : super(name: "AddictiveBlue") {
    subFilters.add(new AddictiveColorSubFilter(0, 0, 50));
  }
}

// Gingham: Vintage-inspired, taking some color out
class GinghamFilter extends ColorFilter {
  GinghamFilter() : super(name: "Gingham") {
    subFilters.add(new SepiaSubFilter(.04));
    subFilters.add(new ContrastSubFilter(-.15));
  }
}

// Moon: B/W, increase brightness and decrease contrast
class MoonFilter extends ColorFilter {
  MoonFilter() : super(name: "Moon") {
    subFilters.add(new GrayScaleSubFilter());
    subFilters.add(new ContrastSubFilter(-.04));
    subFilters.add(new BrightnessSubFilter(0.1));
  }
}

// Lark: Brightens and intensifies colours but not red hues
class LarkFilter extends ColorFilter {
  LarkFilter() : super(name: "Lark") {
    subFilters.add(new BrightnessSubFilter(0.08));
    subFilters.add(new GrayScaleSubFilter());
    subFilters.add(new ContrastSubFilter(-.04));
  }
}

// Reyes: a new vintage filter, gives your photos a “dusty” look
class ReyesFilter extends ColorFilter {
  ReyesFilter() : super(name: "Reyes") {
    subFilters.add(new SepiaSubFilter(0.4));
    subFilters.add(new BrightnessSubFilter(0.13));
    subFilters.add(new ContrastSubFilter(-.05));
  }
}

// Juno: Brightens colors, and intensifies red and yellow hues
class JunoFilter extends ColorFilter {
  JunoFilter() : super(name: "Juno") {
    subFilters.add(new RGBScaleSubFilter(1.01, 1.04, 1));
    subFilters.add(new SaturationSubFilter(0.3));
  }
}

// Slumber: Desaturates the image as well as adds haze for a retro, dreamy look – with an emphasis on blacks and blues
class SlumberFilter extends ColorFilter {
  SlumberFilter() : super(name: "Slumber") {
    subFilters.add(new BrightnessSubFilter(.1));
    subFilters.add(new SaturationSubFilter(-0.5));
  }
}

// Crema: Adds a creamy look that both warms and cools the image
class CremaFilter extends ColorFilter {
  CremaFilter() : super(name: "Crema") {
    subFilters.add(new RGBScaleSubFilter(1.04, 1, 1.02));
    subFilters.add(new SaturationSubFilter(-0.05));
  }
}

// Ludwig: A slight hint of desaturation that also enhances light
class LudwigFilter extends ColorFilter {
  LudwigFilter() : super(name: "Ludwig") {
    subFilters.add(new BrightnessSubFilter(.05));
    subFilters.add(new SaturationSubFilter(-0.03));
  }
}

// Aden: This filter gives a blue/pink natural look
class AdenFilter extends ColorFilter {
  AdenFilter() : super(name: "Aden") {
    subFilters.add(new RGBOverlaySubFilter(228, 130, 225, 0.13));
    subFilters.add(new SaturationSubFilter(-0.2));
  }
}

// Perpetua: Adding a pastel look, this filter is ideal for portraits
class PerpetuaFilter extends ColorFilter {
  PerpetuaFilter() : super(name: "Perpetua") {
    subFilters.add(new RGBScaleSubFilter(1.05, 1.1, 1));
  }
}

// Amaro: Adds light to an image, with the focus on the centre
class AmaroFilter extends ColorFilter {
  AmaroFilter() : super(name: "Amaro") {
    subFilters.add(new SaturationSubFilter(0.3));
    subFilters.add(new BrightnessSubFilter(0.15));
  }
}

// Mayfair: Applies a warm pink tone, subtle vignetting to brighten the photograph center and a thin black border
class MayfairFilter extends ColorFilter {
  MayfairFilter() : super(name: "Mayfair") {
    subFilters.add(new RGBOverlaySubFilter(230, 115, 108, 0.05));
    subFilters.add(new SaturationSubFilter(0.15));
  }
}

// Rise: Adds a "glow" to the image, with softer lighting of the subject
class RiseFilter extends ColorFilter {
  RiseFilter() : super(name: "Rise") {
    subFilters.add(new RGBOverlaySubFilter(255, 170, 0, 0.1));
    subFilters.add(new BrightnessSubFilter(0.09));
    subFilters.add(new SaturationSubFilter(0.1));
  }
}

// Hudson: Creates an "icy" illusion with heightened shadows, cool tint and dodged center
class HudsonFilter extends ColorFilter {
  HudsonFilter() : super(name: "Hudson") {
    subFilters.add(new RGBScaleSubFilter(1, 1, 1.25));
    subFilters.add(new ContrastSubFilter(0.1));
    subFilters.add(new BrightnessSubFilter(0.15));
  }
}

// Valencia: Fades the image by increasing exposure and warming the colors, to give it an antique feel
class ValenciaFilter extends ColorFilter {
  ValenciaFilter() : super(name: "Valencia") {
    subFilters.add(new RGBOverlaySubFilter(255, 225, 80, 0.08));
    subFilters.add(new SaturationSubFilter(0.1));
    subFilters.add(new ContrastSubFilter(0.05));
  }
}

// X-Pro II: Increases color vibrance with a golden tint, high contrast and slight vignette added to the edges
class XProIIFilter extends ColorFilter {
  XProIIFilter() : super(name: "X-Pro II") {
    subFilters.add(new RGBOverlaySubFilter(255, 255, 0, 0.07));
    subFilters.add(new SaturationSubFilter(0.2));
    subFilters.add(new ContrastSubFilter(0.15));
  }
}

// Sierra: Gives a faded, softer look
class SierraFilter extends ColorFilter {
  SierraFilter() : super(name: "Sierra") {
    subFilters.add(new ContrastSubFilter(-0.15));
    subFilters.add(new SaturationSubFilter(0.1));
  }
}

// Willow: A monochromatic filter with subtle purple tones and a translucent white border
class WillowFilter extends ColorFilter {
  WillowFilter() : super(name: "Willow") {
    subFilters.add(new GrayScaleSubFilter());
    subFilters.add(new RGBOverlaySubFilter(100, 28, 210, 0.03));
    subFilters.add(new BrightnessSubFilter(0.1));
  }
}

// Lo-Fi: Enriches color and adds strong shadows through the use of saturation and "warming" the temperature
class LoFiFilter extends ColorFilter {
  LoFiFilter() : super(name: "Lo-Fi") {
    subFilters.add(new ContrastSubFilter(0.15));
    subFilters.add(new SaturationSubFilter(0.2));
  }
}

// Inkwell: Direct shift to black and white
class InkwellFilter extends ColorFilter {
  InkwellFilter() : super(name: "Inkwell") {
    subFilters.add(new GrayScaleSubFilter());
  }
}

// Hefe: Hight contrast and saturation, with a similar effect to Lo-Fi but not quite as dramatic
class HefeFilter extends ColorFilter {
  HefeFilter() : super(name: "Hefe") {
    subFilters.add(new ContrastSubFilter(0.1));
    subFilters.add(new SaturationSubFilter(0.15));
  }
}

// Nashville: Warms the temperature, lowers contrast and increases exposure to give a light "pink" tint – making it feel "nostalgic"
class NashvilleFilter extends ColorFilter {
  NashvilleFilter() : super(name: "Nashville") {
    subFilters.add(new RGBOverlaySubFilter(220, 115, 188, 0.12));
    subFilters.add(new ContrastSubFilter(-0.05));
  }
}

// Stinson: washing out the colors ever so slightly
class StinsonFilter extends ColorFilter {
  StinsonFilter() : super(name: "Stinson") {
    subFilters.add(new BrightnessSubFilter(0.1));
    subFilters.add(new SepiaSubFilter(0.3));
  }
}

// Vesper: adds a yellow tint that
class VesperFilter extends ColorFilter {
  VesperFilter() : super(name: "Vesper") {
    subFilters.add(new RGBOverlaySubFilter(255, 225, 0, 0.05));
    subFilters.add(new BrightnessSubFilter(0.06));
    subFilters.add(new ContrastSubFilter(0.06));
  }
}

// Earlybird: Gives an older look with a sepia tint and warm temperature
class EarlybirdFilter extends ColorFilter {
  EarlybirdFilter() : super(name: "Earlybird") {
    subFilters.add(new RGBOverlaySubFilter(255, 165, 40, 0.2));
    subFilters.add(new SaturationSubFilter(0.15));
  }
}

// Brannan: Increases contrast and exposure and adds a metallic tint
class BrannanFilter extends ColorFilter {
  BrannanFilter() : super(name: "Brannan") {
    subFilters.add(new ContrastSubFilter(0.2));
    subFilters.add(new RGBOverlaySubFilter(140, 10, 185, 0.1));
  }
}

// Sutro: Burns photo edges, increases highlights and shadows dramatically with a focus on purple and brown colors
class SutroFilter extends ColorFilter {
  SutroFilter() : super(name: "Sutro") {
    subFilters.add(new BrightnessSubFilter(-0.1));
    subFilters.add(new SaturationSubFilter(-0.1));
  }
}

// Toaster: Ages the image by "burning" the centre and adds a dramatic vignette
class ToasterFilter extends ColorFilter {
  ToasterFilter() : super(name: "Toaster") {
    subFilters.add(new SepiaSubFilter(0.1));
    subFilters.add(new RGBOverlaySubFilter(255, 145, 0, 0.2));
  }
}

// Walden: Increases exposure and adds a yellow tint
class WaldenFilter extends ColorFilter {
  WaldenFilter() : super(name: "Walden") {
    subFilters.add(new BrightnessSubFilter(0.1));
    subFilters.add(new RGBOverlaySubFilter(255, 255, 0, 0.2));
  }
}

// 1977: The increased exposure with a red tint gives the photograph a rosy, brighter, faded look.
class F1977Filter extends ColorFilter {
  F1977Filter() : super(name: "1977") {
    subFilters.add(new RGBOverlaySubFilter(255, 25, 0, 0.15));
    subFilters.add(new BrightnessSubFilter(0.1));
  }
}

// Kelvin: Increases saturation and temperature to give it a radiant "glow"
class KelvinFilter extends ColorFilter {
  KelvinFilter() : super(name: "Kelvin") {
    subFilters.add(new RGBOverlaySubFilter(255, 140, 0, 0.1));
    subFilters.add(new RGBScaleSubFilter(1.15, 1.05, 1));
    subFilters.add(new SaturationSubFilter(0.35));
  }
}

// Maven: darkens images, increases shadows, and adds a slightly yellow tint overal
class MavenFilter extends ColorFilter {
  MavenFilter() : super(name: "Maven") {
    subFilters.add(new RGBOverlaySubFilter(225, 240, 0, 0.1));
    subFilters.add(new SaturationSubFilter(0.25));
    subFilters.add(new ContrastSubFilter(0.05));
  }
}

// Ginza: brightens and adds a warm glow
class GinzaFilter extends ColorFilter {
  GinzaFilter() : super(name: "Ginza") {
    subFilters.add(new SepiaSubFilter(0.06));
    subFilters.add(new BrightnessSubFilter(0.1));
  }
}

// Skyline: brightens to the image pop
class SkylineFilter extends ColorFilter {
  SkylineFilter() : super(name: "Skyline") {
    subFilters.add(new SaturationSubFilter(0.35));
    subFilters.add(new BrightnessSubFilter(0.1));
  }
}

// Dogpatch: increases the contrast, while washing out the lighter colors
class DogpatchFilter extends ColorFilter {
  DogpatchFilter() : super(name: "Dogpatch") {
    subFilters.add(new ContrastSubFilter(0.15));
    subFilters.add(new BrightnessSubFilter(0.1));
  }
}

// Brooklyn
class BrooklynFilter extends ColorFilter {
  BrooklynFilter() : super(name: "Brooklyn") {
    subFilters.add(new RGBOverlaySubFilter(25, 240, 252, 0.05));
    subFilters.add(new SepiaSubFilter(0.3));
  }
}

// Helena: adds an orange and teal vibe
class HelenaFilter extends ColorFilter {
  HelenaFilter() : super(name: "Helena") {
    subFilters.add(new RGBOverlaySubFilter(208, 208, 86, 0.2));
    subFilters.add(new ContrastSubFilter(0.15));
  }
}

// Ashby: gives images a great golden glow and a subtle vintage feel
class AshbyFilter extends ColorFilter {
  AshbyFilter() : super(name: "Ashby") {
    subFilters.add(new RGBOverlaySubFilter(255, 160, 25, 0.1));
    subFilters.add(new BrightnessSubFilter(0.1));
  }
}

// Charmes: a high contrast filter, warming up colors in your image with a red tint
class CharmesFilter extends ColorFilter {
  CharmesFilter() : super(name: "Charmes") {
    subFilters.add(new RGBOverlaySubFilter(255, 50, 80, 0.12));
    subFilters.add(new ContrastSubFilter(0.05));
  }
}

class PerfectFilter extends ColorFilter {
  PerfectFilter() : super(name: "Perfect") {
    subFilters.add(new RGBScaleSubFilter(1, 1, 1.1));
    subFilters.add(new ContrastSubFilter(0.1));
    subFilters.add(new BrightnessSubFilter(0.15));
  }
}

class SparkFilter extends ColorFilter {
  SparkFilter() : super(name: "Spark") {
    subFilters.add(new RGBScaleSubFilter(1, 1, 1));
    subFilters.add(new ContrastSubFilter(0.1));
    subFilters.add(new BrightnessSubFilter(0.2));
  }
}

List<Filter> presetFiltersList = [
  Original(),
  PerfectFilter(),
  SparkFilter(),
  // AddictiveBlueFilter(),
  // AddictiveRedFilter(),
  // AdenFilter(),
  // AmaroFilter(),
  // AshbyFilter(),
  // BrannanFilter(),
  // BrooklynFilter(),
  // CharmesFilter(),
  // ClarendonFilter(),
  // CremaFilter(),
  // DogpatchFilter(),
  // EarlybirdFilter(),
  // F1977Filter(),
  // GinghamFilter(),
  // GinzaFilter(),
  // HefeFilter(),
  // HelenaFilter(),
  HudsonFilter(),
  // InkwellFilter(),
  // JunoFilter(),
  // KelvinFilter(),
  // LarkFilter(),
  // LoFiFilter(),
  // LudwigFilter(),
  // MavenFilter(),
  // MayfairFilter(),
  MoonFilter(),
  // NashvilleFilter(),
  // PerpetuaFilter(),
  // ReyesFilter(),
  // RiseFilter(),
  // SierraFilter(),
  // SkylineFilter(),
  SlumberFilter(),
  // StinsonFilter(),
  // SutroFilter(),
  // ToasterFilter(),
  // ValenciaFilter(),
  // VesperFilter(),
  // WaldenFilter(),
  WillowFilter(),
  // XProIIFilter(),
];
