///The [Filter] class to define a Filter consists of multiple [SubFilter]s
class Filter {
  final String name;
  final Function(List<int>) apply;

  Filter({
    required this.name,
    required this.apply,
  });
}

///The [SubFilter] class is the abstract class to define any SubFilter.
abstract class SubFilter extends Object {}
