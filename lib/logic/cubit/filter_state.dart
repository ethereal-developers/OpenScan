part of 'filter_cubit.dart';

class FilterState {
  Map<String, List<int>?> cachedFilters = {};
  Filter selectedFilter;

  FilterState({
    required this.cachedFilters,
    required this.selectedFilter,
  });
}
