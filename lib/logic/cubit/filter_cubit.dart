import 'package:bloc/bloc.dart';
import 'package:openscan/core/image_filter/filters/filters.dart';

import '../../core/image_filter/filters/preset_filters.dart';

part 'filter_state.dart';

class FilterCubit extends Cubit<FilterState> {
  FilterCubit({
    required Map<String, List<int>> cachedFilters,
    required Filter currentFilter,
  }) : super(FilterState(
          cachedFilters: {},
          currentFilter: presetFiltersList[0],
        ));

  /// Updates the data to reflect in the UI - adhoc
  void emitState(state) {
    emit(FilterState(
      cachedFilters: state.cachedFilters,
      currentFilter: state.currentFilter,
    ));
  }

  void cacheImage(String key, List<int> bitImage) {
    state.cachedFilters[key] = bitImage;
    emitState(state);
  }
}
