import 'point.dart';

/// A quadrilateral with corners in a single canonical order everywhere in
/// the app: clockwise starting at the top-left. This is the only
/// representation of a detected/edited document boundary that crosses any
/// layer boundary (detector -> crop UI -> perspective warp).
class Quad {
  final Pt topLeft;
  final Pt topRight;
  final Pt bottomRight;
  final Pt bottomLeft;

  const Quad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  Quad scaled(double sx, double sy) => Quad(
        topLeft: topLeft.scaled(sx, sy),
        topRight: topRight.scaled(sx, sy),
        bottomRight: bottomRight.scaled(sx, sy),
        bottomLeft: bottomLeft.scaled(sx, sy),
      );

  List<Pt> get points => [topLeft, topRight, bottomRight, bottomLeft];
}
