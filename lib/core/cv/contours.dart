import 'dart:math';
import 'dart:typed_data';

import 'models/point.dart';
import 'models/quad.dart';

/// Finds the largest convex quadrilateral in a binary edge mask (1 = edge),
/// analogous to OpenCV's `findContours` + `approxPolyDP` + `sortPoints`
/// pipeline. Returns the quad in the mask's own coordinate space (the
/// caller is responsible for rescaling to the original image size).
Quad? findDocumentQuad(Uint8List mask, int width, int height) {
  final components = _connectedComponents(mask, width, height);
  components.sort((a, b) => b.length.compareTo(a.length));

  final candidateCount = components.length < 5 ? components.length : 5;
  for (int i = 0; i < candidateCount; i++) {
    final members = components[i];
    if (members.length < 4) continue;

    final hull = _convexHull(members);
    if (hull.length < 4) continue;

    for (final epsilonFactor in const [0.02, 0.04, 0.06, 0.08, 0.1]) {
      final simplified = hull.length <= 4
          ? hull
          : _simplifyClosedPolygon(hull, epsilonFactor);
      if (simplified.length == 4 && _isConvex(simplified)) {
        final area = _polygonArea(simplified);
        if (area / (width * height) > 0.05) {
          return _sortCorners(simplified);
        }
      }
    }
  }
  return null;
}

/// 8-connected flood fill over the binary mask, returning member pixels
/// per connected component (BFS via an index queue, not recursion, so it
/// is safe on large masks).
List<List<Pt>> _connectedComponents(Uint8List mask, int width, int height) {
  final visited = Uint8List(width * height);
  final components = <List<Pt>>[];

  for (int start = 0; start < mask.length; start++) {
    if (mask[start] != 1 || visited[start] == 1) continue;

    final members = <Pt>[];
    final queue = <int>[start];
    visited[start] = 1;
    int head = 0;

    while (head < queue.length) {
      final idx = queue[head++];
      final x = idx % width;
      final y = idx ~/ width;
      members.add(Pt(x.toDouble(), y.toDouble()));

      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final nx = x + dx, ny = y + dy;
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
          final nIdx = ny * width + nx;
          if (mask[nIdx] == 1 && visited[nIdx] == 0) {
            visited[nIdx] = 1;
            queue.add(nIdx);
          }
        }
      }
    }
    components.add(members);
  }
  return components;
}

/// Andrew's monotone-chain convex hull.
List<Pt> _convexHull(List<Pt> points) {
  final pts = List<Pt>.from(points)
    ..sort((a, b) => a.x != b.x ? a.x.compareTo(b.x) : a.y.compareTo(b.y));
  if (pts.length < 3) return pts;

  double cross(Pt o, Pt a, Pt b) =>
      (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);

  final lower = <Pt>[];
  for (final p in pts) {
    while (lower.length >= 2 &&
        cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }

  final upper = <Pt>[];
  for (final p in pts.reversed) {
    while (upper.length >= 2 &&
        cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }

  lower.removeLast();
  upper.removeLast();
  return [...lower, ...upper];
}

/// Ramer-Douglas-Peucker simplification of a *closed* polygon: splits at
/// the two farthest-apart hull points into two open chains, simplifies
/// each, then merges — standing in for `approxPolyDP(3% arc length)`.
List<Pt> _simplifyClosedPolygon(List<Pt> hull, double epsilonFactor) {
  double perimeter = 0;
  for (int i = 0; i < hull.length; i++) {
    perimeter += _dist(hull[i], hull[(i + 1) % hull.length]);
  }
  final epsilon = epsilonFactor * perimeter;

  int ai = 0, bi = 0;
  double best = -1;
  for (int i = 0; i < hull.length; i++) {
    for (int j = i + 1; j < hull.length; j++) {
      final d = _dist(hull[i], hull[j]);
      if (d > best) {
        best = d;
        ai = i;
        bi = j;
      }
    }
  }

  List<Pt> chain(int from, int to) {
    final result = <Pt>[];
    int i = from;
    while (true) {
      result.add(hull[i]);
      if (i == to) break;
      i = (i + 1) % hull.length;
    }
    return result;
  }

  final chain1 = _rdp(chain(ai, bi), epsilon);
  final chain2 = _rdp(chain(bi, ai), epsilon);

  return [...chain1, ...chain2.sublist(1, chain2.length - 1)];
}

List<Pt> _rdp(List<Pt> points, double epsilon) {
  if (points.length < 3) return points;

  double maxDist = -1;
  int index = 0;
  final start = points.first;
  final end = points.last;

  for (int i = 1; i < points.length - 1; i++) {
    final d = _perpendicularDistance(points[i], start, end);
    if (d > maxDist) {
      maxDist = d;
      index = i;
    }
  }

  if (maxDist > epsilon) {
    final left = _rdp(points.sublist(0, index + 1), epsilon);
    final right = _rdp(points.sublist(index), epsilon);
    return [...left.sublist(0, left.length - 1), ...right];
  }
  return [start, end];
}

double _perpendicularDistance(Pt p, Pt a, Pt b) {
  final dx = b.x - a.x, dy = b.y - a.y;
  final len = sqrt(dx * dx + dy * dy);
  if (len == 0) return _dist(p, a);
  final t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / (len * len);
  final projX = a.x + t * dx, projY = a.y + t * dy;
  return _dist(p, Pt(projX, projY));
}

double _dist(Pt a, Pt b) => sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));

bool _isConvex(List<Pt> pts) {
  final n = pts.length;
  bool? positiveSign;
  for (int i = 0; i < n; i++) {
    final a = pts[i], b = pts[(i + 1) % n], c = pts[(i + 2) % n];
    final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
    if (cross == 0) continue;
    final positive = cross > 0;
    if (positiveSign == null) {
      positiveSign = positive;
    } else if (positiveSign != positive) {
      return false;
    }
  }
  return true;
}

double _polygonArea(List<Pt> pts) {
  double area = 0;
  for (int i = 0; i < pts.length; i++) {
    final a = pts[i], b = pts[(i + 1) % pts.length];
    area += a.x * b.y - b.x * a.y;
  }
  return area.abs() / 2;
}

/// Canonical corner order: top-left / top-right / bottom-right /
/// bottom-left, via the classic sum/difference sort (same math OpenCV's
/// `Imgproc`-based `sortPoints` used, but defined exactly once and shared
/// by every consumer instead of being re-implemented per platform).
Quad _sortCorners(List<Pt> pts) {
  final bySum = List<Pt>.from(pts)
    ..sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
  final byDiff = List<Pt>.from(pts)
    ..sort((a, b) => (a.y - a.x).compareTo(b.y - b.x));

  return Quad(
    topLeft: bySum.first,
    bottomRight: bySum.last,
    topRight: byDiff.first,
    bottomLeft: byDiff.last,
  );
}
