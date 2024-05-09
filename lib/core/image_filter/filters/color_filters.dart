import 'dart:typed_data';

import '../models.dart';
import 'filters.dart';

///The [ColorSubFilter] class is the abstract class to define any ColorSubFilter.
abstract class ColorSubFilter extends SubFilter {
  ///Apply the [SubFilter] to an Image.
  RGBA applyFilter(RGBA color);
}

///The [ColorFilter] class to define a Filter which will applied to each color, consists of multiple [SubFilter]s
class ColorFilter extends Filter {
  List<ColorSubFilter> subFilters;
  ColorFilter({required String name})
      : subFilters = [],
        super(name: name);

  @override
  void apply(Uint8List bytes, int width, int height) {
    for (int i = 0; i < bytes.length; i += 4) {
      RGBA color = RGBA(
          red: bytes[i],
          green: bytes[i + 1],
          blue: bytes[i + 2],
          alpha: bytes[i + 3]);
      for (ColorSubFilter subFilter in subFilters) {
        color = subFilter.applyFilter(color);
      }
      bytes[i] = color.red;
      bytes[i + 1] = color.green;
      bytes[i + 2] = color.blue;
      bytes[i + 3] = color.alpha;
    }
  }

  void addSubFilter(ColorSubFilter subFilter) {
    this.subFilters.add(subFilter);
  }

  void addSubFilters(List<ColorSubFilter> subFilters) {
    this.subFilters.addAll(subFilters);
  }
}
