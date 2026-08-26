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

/// How far apart (average per-corner distance, as a fraction of the
/// frame diagonal) two candidates may sit and still be treated as the
/// same detection by [pickBestQuad]'s clustering.
const double kCandidateClusterFraction = 0.03;

/// Weight given to how many candidates back a cluster. A shape that
/// several thresholds and several RDP epsilons all independently agree on
/// is far more likely to be the real document edge than one that only a
/// single parameter combination produced — and, crucially, it is the one
/// that will still be there next frame.
const double kCandidateSupportWeight = 0.12;

/// Picks the best detection from [candidates] (as gathered by
/// [findDocumentQuadCandidates], possibly pooled from multiple masks).
///
/// The pool is first *clustered*: candidates whose corners all sit within
/// [kCandidateClusterFraction] of each other are the same shape found
/// several times over — once per threshold multiplier, once per RDP
/// epsilon — and are averaged into one consensus quad. This matters more
/// than it sounds. Taking the single highest-scoring candidate meant that
/// two near-identical shapes differing by a hair in score could trade
/// places from frame to frame, and each swap moved the overlay by however
/// far apart those two shapes happened to be; averaging the cluster
/// removes that coin-flip entirely, and cancels most of the per-epsilon
/// corner jitter along with it.
///
/// Clusters are then scored the way the reference document-scanner app's
/// native detector scores contours — area weighted by how close the
/// corners are to 90 degrees (`getContourSortFactor` in its
/// `DocumentDetector.cpp`) — plus a bonus for how many candidates back the
/// cluster ([kCandidateSupportWeight]), plus, if [previousQuad] is
/// supplied, a small proximity bonus ([kPreviousQuadProximityWeight])
/// toward whatever was detected last frame.
Quad? pickBestQuad(
  List<Quad> candidates,
  int width,
  int height, {
  Quad? previousQuad,
}) {
  if (candidates.isEmpty) return null;

  final diagonal = sqrt(width * width + height * height).toDouble();
  final clusters = _clusterCandidates(candidates, diagonal);

  Quad? best;
  double bestScore = double.negativeInfinity;
  for (final cluster in clusters) {
    var score = _qualityScore(cluster.quad, width, height) +
        kCandidateSupportWeight * (cluster.support / candidates.length);
    var result = cluster.quad;

    if (previousQuad != null) {
      final match = bestCornerAssignment(result.points, previousQuad);
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

/// Groups candidates that describe the same shape and averages each group
/// corner-wise, returning one quad per group along with how many
/// candidates it was built from.
///
/// Greedy single-pass clustering against each group's running mean: the
/// pool is a handful of quads at most (5 components x 5 epsilons x 3
/// thresholds, before plausibility filtering), so this stays trivial
/// per frame.
List<({Quad quad, int support})> _clusterCandidates(
  List<Quad> candidates,
  double diagonal,
) {
  final tolerance = diagonal * kCandidateClusterFraction;
  final means = <Quad>[];
  final sums = <List<double>>[];
  final counts = <int>[];

  for (final candidate in candidates) {
    int? matched;
    Quad aligned = candidate;
    for (int i = 0; i < means.length; i++) {
      // Align corner labels to the cluster before averaging: two
      // detections of the same physical shape can carry different labels
      // (a near-45-degree document), and averaging those slot-wise would
      // produce a quad that is in neither of them.
      final match = bestCornerAssignment(candidate.points, means[i]);
      if (match.totalDistance / 4 <= tolerance) {
        matched = i;
        aligned = match.quad;
        break;
      }
    }

    if (matched == null) {
      means.add(candidate);
      sums.add(_scalars(candidate));
      counts.add(1);
      continue;
    }

    final sum = sums[matched];
    final scalars = _scalars(aligned);
    for (int i = 0; i < 8; i++) {
      sum[i] += scalars[i];
    }
    counts[matched]++;
    means[matched] = _quadOfScalars(sum, counts[matched]);
  }

  return [
    for (int i = 0; i < means.length; i++)
      (quad: means[i], support: counts[i]),
  ];
}

List<double> _scalars(Quad q) => [
      q.topLeft.x, q.topLeft.y,
      q.topRight.x, q.topRight.y,
      q.bottomRight.x, q.bottomRight.y,
      q.bottomLeft.x, q.bottomLeft.y,
    ];

Quad _quadOfScalars(List<double> sums, int count) => Quad(
      topLeft: Pt(sums[0] / count, sums[1] / count),
      topRight: Pt(sums[2] / count, sums[3] / count),
      bottomRight: Pt(sums[4] / count, sums[5] / count),
      bottomLeft: Pt(sums[6] / count, sums[7] / count),
    );

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
/// bottom-left, clockwise as seen on screen (y grows downward).
///
/// Works in two steps, rather than by the classic sum/difference sort this
/// replaces. That sort picked each slot independently — `min(x+y)` for
/// top-left, `min(y-x)` for top-right and so on — which for a tilted or
/// slightly irregular quad can hand the *same* physical point to two
/// slots, leaving one corner duplicated and one dropped: a bow-tie shape
/// that flips as the document rotates, which is exactly the kind of
/// frame-to-frame corner swap that makes an overlay jump around.
///
/// Instead:
///
/// 1. The four points are put in convex cyclic order by angle around
///    their centroid, so whatever labels are applied, the polygon is a
///    simple (non-self-intersecting) quadrilateral wound clockwise.
/// 2. Of the four rotations of that cycle, the one whose labels best fit
///    their names wins — top corners above bottom ones, right corners to
///    the right of left ones. Rotating a cycle can never duplicate or drop
///    a point, so the result is always a permutation of the input.
Quad sortCorners(List<Pt> pts) {
  assert(pts.length == 4);
  final cx = (pts[0].x + pts[1].x + pts[2].x + pts[3].x) / 4;
  final cy = (pts[0].y + pts[1].y + pts[2].y + pts[3].y) / 4;

  // Ascending angle around the centroid is clockwise on screen, since y
  // grows downward: a point above the centre has a negative dy and so
  // comes before one to its right.
  final ordered = List<Pt>.from(pts)
    ..sort((a, b) =>
        atan2(a.y - cy, a.x - cx).compareTo(atan2(b.y - cy, b.x - cx)));

  int bestStart = 0;
  double bestScore = double.negativeInfinity;
  for (int start = 0; start < 4; start++) {
    final tl = ordered[start];
    final tr = ordered[(start + 1) % 4];
    final br = ordered[(start + 2) % 4];
    final bl = ordered[(start + 3) % 4];
    // How well this labelling agrees with what the names claim: the two
    // "right" corners right of their "left" counterparts, the two
    // "bottom" corners below their "top" ones. The rotation that agrees
    // most is the one a person would have drawn.
    final score =
        (tr.x - tl.x) + (br.x - bl.x) + (bl.y - tl.y) + (br.y - tr.y);
    if (score > bestScore) {
      bestScore = score;
      bestStart = start;
    }
  }

  return Quad(
    topLeft: ordered[bestStart],
    topRight: ordered[(bestStart + 1) % 4],
    bottomRight: ordered[(bestStart + 2) % 4],
    bottomLeft: ordered[(bestStart + 3) % 4],
  );
}
