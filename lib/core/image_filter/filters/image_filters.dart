import 'dart:typed_data';

import 'filters.dart';

///The [ImageSubFilter] class is the abstract class to define any ImageSubFilter.
mixin ImageSubFilter on SubFilter {
  ///Apply the [SubFilter] to an Image.
  void apply(Uint8List pixels, int width, int height);
}

class ImageFilter extends Filter {
  List<ImageSubFilter> subFilters;

  ImageFilter({required String name})
      : subFilters = [],
        super(name: name, apply: _applyImageFilter);

  static void _applyImageFilter(List<int> pixels) {
    // Note: Subfilters will be applied when added via addSubFilter
  }

  void addSubFilter(ImageSubFilter subFilter) {
    this.subFilters.add(subFilter);
  }

  void addSubFilters(List<ImageSubFilter> subFilters) {
    this.subFilters.addAll(subFilters);
  }
}
