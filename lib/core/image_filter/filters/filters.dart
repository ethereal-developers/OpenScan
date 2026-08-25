import 'dart:typed_data';

/// A colour mode that can be applied to a scanned page.
///
/// [name] is the filter's stable id: it is the key previews are cached
/// under and the value written to the database, so it must not change with
/// the app's locale. The label the user sees is resolved separately, by
/// `filterLabel` in `lib/view/screens/filter_screen.dart`.
abstract class Filter extends Object {
  Filter({required this.name});

  final String name;

  /// Rewrites [pixels] — an RGBA buffer of stride 4 — in place.
  void apply(Uint8List pixels, int width, int height);
}
