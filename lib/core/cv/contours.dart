import 'dart:math';
import 'dart:typed_data';

import 'models/point.dart';
import 'models/quad.dart';

/// Finds the best convex quadrilateral in a binary edge mask (1 = edge),
/// analogous to OpenCV's `findContours` + `approxPolyDP` + `sortPoints`
/// pipeline, scored the same way the reference document-scanner app's
/// native detector scores candidates (area, weighted by how close the
/// corners are to 90 degrees) rather than just taking whichever candidate
/// a sweep happens to reach first — see [pickBestQuad]. Returns the quad
/// in the mask's own coordinate space (the caller is responsible for
/// rescaling to the original image size).
Quad? findDocumentQuad(Uint8List mask, int width, int height,
    {Quad? previousQuad}) {
  final candidates = findDocumentQuadCandidates(mask, width, height);
  return pickBestQuad(candidates, width, height, previousQuad: previousQuad);
}

/// Collects every candidate quad that passes [isPlausibleQuad] across the
/// full connected-component x RDP-epsilon sweep of a binary edge mask,
/// instead of stopping at the first one found. Kept separate from
/// [pickBestQuad] so a caller (the live-scan pipeline) can merge
/// candidates gathered from several differently-thresholded masks of the
/// same frame before scoring — mirroring the reference app's approach of
/// trying several detection strategies per frame and scoring the pooled
/// results, rather than trusting a single threshold's result.
List<Quad> findDocumentQuadCandidates(Uint8List mask, int width, int height) {
  final components = _connectedComponents(mask, width, height);
  components.sort((a, b) => b.length.compareTo(a.length));

  final candidateCount = components.length < 5 ? components.length : 5;
  final results = <Quad>[];

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
        final quad = sortCorners(simplified);
        if (isPlausibleQuad(quad, width, height)) {
          results.add(quad);
        }
      }
    }
  }
  return results;
}

/// Weight given to proximity to [previousQuad] (in [pickBestQuad]) versus
/// intrinsic candidate quality (area + squareness). Deliberately small —
/// a strong pull toward the previous frame's position is what caused the
/// RDP-epsilon-sweep-era instability this scoring approach replaces
/// (chasing whichever candidate merely sat closest to last frame, even a
/// poor-quality one); this is a tie-breaker for temporal consistency
/// between otherwise similarly-good candidates, not the primary signal.
const double kPreviousQuadProximityWeight = 0.15;

/// Picks the best candidate from [candidates] (as gathered by
/// [findDocumentQuadCandidates], possibly pooled from multiple masks),
/// mirroring the reference document-scanner app's native detector: score
/// every valid candidate by area and how close its corners are to 90
/// degrees (`getContourSortFactor` in its `DocumentDetector.cpp`) and take
/// the highest-scoring one, rather than whichever a sweep happens to reach
/// first. This is what makes detection consistent frame-to-frame for a
/// document that hasn't actually moved — the same objectively-best
/// contour keeps winning, instead of an arbitrary tie among several
/// similarly-plausible ones. If [previousQuad] is supplied, a small
/// proximity bonus ([kPreviousQuadProximityWeight]) nudges the choice
/// toward whichever candidate best corresponds to it (via
/// [bestCornerAssignment]) when candidates are otherwise close in quality.
Quad? pickBestQuad(
  List<Quad> candidates,
  int width,
  int height, {
  Quad? previousQuad,
}) {
  if (candidates.isEmpty) return null;

  final diagonal = sqrt(width * width + height * height).toDouble();

  Quad? best;
  double bestScore = double.negativeInfinity;
  for (final candidate in candidates) {
    var score = _qualityScore(candidate, width, height);
    var result = candidate;

    if (previousQuad != null) {
      final match = bestCornerAssignment(candidate.points, previousQuad);
      result = match.quad;
      final proximity = diagonal == 0
          ? 0.0
          : 1 - (match.totalDistance / diagonal).clamp(0.0, 1.0);
      score += kPreviousQuadProximityWeight * proximity;
    }

    if (score > bestScore) {
      bestScore = score;
      best = result;
    }
  }
  return best;
}

/// Area (as a fraction of the frame) weighted by squareness — mirrors the
/// reference app's `getContourSortFactor`: `area + weight * (1 - maxCos)`,
/// where a cosine near 0 means corners near 90 degrees. Larger, more
/// rectangular quads score higher; used by [pickBestQuad] to choose among
/// several otherwise-valid candidates instead of taking whichever the
/// sweep reaches first.
double _qualityScore(Quad quad, int width, int height) {
  final areaRatio = _polygonArea(quad.points) / (width * height);
  return areaRatio * (1 - _maxAngleDeviationFraction(quad));
}

/// Largest per-corner deviation from a perfect 90-degree angle, across all
/// 4 corners, normalized to [0,1] (0 = every corner is exactly 90 degrees;
/// 1 = a corner is maximally skewed, i.e. 0 or 180 degrees).
double _maxAngleDeviationFraction(Quad quad) {
  final pts = quad.points;
  double maxDeviation = 0;
  for (int i = 0; i < pts.length; i++) {
    final a = pts[(i - 1 + pts.length) % pts.length];
    final b = pts[i];
    final c = pts[(i + 1) % pts.length];
    final deviation = (_angleAtVertexDegrees(a, b, c) - 90).abs();
    if (deviation > maxDeviation) maxDeviation = deviation;
  }
  return (maxDeviation / 90).clamp(0.0, 1.0);
}

/// All 24 permutations of the indices [0,1,2,3], used by
/// [bestCornerAssignment] to brute-force the best correspondence between
/// an unordered set of 4 points and a reference [Quad]'s corner slots.
const List<List<int>> _cornerPermutations = [
  [0, 1, 2, 3], [0, 1, 3, 2], [0, 2, 1, 3], [0, 2, 3, 1],
  [0, 3, 1, 2], [0, 3, 2, 1], [1, 0, 2, 3], [1, 0, 3, 2],
  [1, 2, 0, 3], [1, 2, 3, 0], [1, 3, 0, 2], [1, 3, 2, 0],
  [2, 0, 1, 3], [2, 0, 3, 1], [2, 1, 0, 3], [2, 1, 3, 0],
  [2, 3, 0, 1], [2, 3, 1, 0], [3, 0, 1, 2], [3, 0, 2, 1],
  [3, 1, 0, 2], [3, 1, 2, 0], [3, 2, 0, 1], [3, 2, 1, 0],
];

/// Assigns [points] (exactly 4, unordered) to the corner slots of
/// [reference] — topLeft/topRight/bottomRight/bottomLeft — choosing
/// whichever of the 24 possible permutations minimizes total corner-to-
/// corner distance to [reference]. Used to keep a physical corner mapped
/// to the same slot across frames even when a purely geometric labeling
/// (like [sortCorners]) would flip near a ~45-degree document rotation —
/// both by [findDocumentQuad]'s previous-quad-biased candidate selection
/// and by the live-scan `QuadSmoother`'s per-slot temporal filters.
({Quad quad, double totalDistance}) bestCornerAssignment(
  List<Pt> points,
  Quad reference,
) {
  assert(points.length == 4);
  final refPts = reference.points;

  List<int>? bestPerm;
  double bestDistance = double.infinity;
  for (final perm in _cornerPermutations) {
    double total = 0;
    for (int i = 0; i < 4; i++) {
      total += _dist(points[perm[i]], refPts[i]);
    }
    if (total < bestDistance) {
      bestDistance = total;
      bestPerm = perm;
    }
  }

  final p = bestPerm!;
  return (
    quad: Quad(
      topLeft: points[p[0]],
      topRight: points[p[1]],
      bottomRight: points[p[2]],
      bottomLeft: points[p[3]],
    ),
    totalDistance: bestDistance,
  );
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

/// Minimum quad area as a fraction of the frame it was detected in.
/// Rejects noise-sized detections that happen to form a valid convex
/// quadrilateral but are too small to plausibly be the document.
const double kMinQuadAreaRatio = 0.05;

/// Minimum interior angle, in degrees, considered legal for a document
/// corner. A real document photographed at even a steep angle still has
/// four corners nowhere near collinear; a quad with an angle below this
/// (or, symmetrically, above `180 - kMinQuadAngleDegrees`) has one corner
/// that has effectively collapsed onto its neighbors — a sliver or
/// near-triangle, not a usable crop target.
const double kMinQuadAngleDegrees = 15.0;

/// Rejects degenerate quads before they're ever returned as a detection
/// result: too small relative to the frame, or so thin/sliver-shaped
/// that a corner has collapsed (near-triangular). Used by
/// [findDocumentQuad] itself, and public so any quad — e.g. one that's
/// been scaled or otherwise transformed after detection — can be
/// re-validated with the same rule.
bool isPlausibleQuad(Quad quad, int width, int height) {
  final pts = quad.points;

  final area = _polygonArea(pts);
  if (width <= 0 || height <= 0) return false;
  if (area / (width * height) < kMinQuadAreaRatio) return false;

  for (int i = 0; i < pts.length; i++) {
    final a = pts[(i - 1 + pts.length) % pts.length];
    final b = pts[i];
    final c = pts[(i + 1) % pts.length];
    final angle = _angleAtVertexDegrees(a, b, c);
    if (angle < kMinQuadAngleDegrees || angle > 180 - kMinQuadAngleDegrees) {
      return false;
    }
  }
  return true;
}

/// Interior angle at vertex [b], in degrees, formed by rays b->a and
/// b->c. Returns 0 if either ray has zero length (two corners coincide),
/// which callers should treat as maximally degenerate.
double _angleAtVertexDegrees(Pt a, Pt b, Pt c) {
  final abx = a.x - b.x, aby = a.y - b.y;
  final cbx = c.x - b.x, cby = c.y - b.y;
  final magAB = sqrt(abx * abx + aby * aby);
  final magCB = sqrt(cbx * cbx + cby * cby);
  if (magAB == 0 || magCB == 0) return 0;
  final cosAngle =
      ((abx * cbx + aby * cby) / (magAB * magCB)).clamp(-1.0, 1.0);
  return acos(cosAngle) * 180 / pi;
}

/// Canonical corner order: top-left / top-right / bottom-right /
/// bottom-left, via the classic sum/difference sort (same math OpenCV's
/// `Imgproc`-based `sortPoints` used, but defined exactly once and shared
/// by every consumer instead of being re-implemented per platform).
Quad sortCorners(List<Pt> pts) {
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
