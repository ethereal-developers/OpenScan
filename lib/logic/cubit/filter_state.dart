part of 'filter_cubit.dart';

class FilterState {
  Map<String, List<int>> cachedFilters = {};
  Filter currentFilter;

  FilterState({
    required this.cachedFilters,
    required this.currentFilter,
  });
}
