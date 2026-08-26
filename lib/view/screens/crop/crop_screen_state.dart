import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:openscan/core/cv/document_detector.dart';
import 'package:openscan/core/cv/models/detection_result.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/core/cv/perspective_crop.dart';

/// UI-facing detection state: loading while the isolate is running,
/// detected once a quad was found, notFound when detection completed
/// without finding a suitable quad OR threw/timed out (both cases fall
/// back to the same "adjust manually" UI rather than spinning forever).
enum CropDetectionState { loading, detected, notFound }

class CropScreenState {
  GlobalKey imageKey = GlobalKey();
  GlobalKey bodyKey = GlobalKey();
  File? imageFile;
  Size? imageSize;
  Quad? detectedQuad;
  late Size canvasSize;
  late Size screenSize;
  bool isLoading = false;
  double aspectRatio = 1;
  late RenderBox imageBox;

  /// Quarter turns applied by the user, counted up rather than wrapped, so
  /// the display can animate 3 -> 4 forwards instead of unwinding 3 -> 0.
  int turns = 0;
  late Size originalCanvasSize;
  double verticalScaleFactor = 1;
  double horizontalScaleFactor = 1;
  Offset canvasOffset = Offset.zero;
  late Offset tl, tr, bl, br, t, l, b, r;
  MovingPoint movingPoint = MovingPoint();
  Size imageSizeNative = Size(600.0, 600.0);
  late double tSlope, bSlope, rSlope, lSlope;

  /// The rotation the page is being shown at, in radians.
  double get rotationAngle => turns * pi / 2;

  /// The same rotation as a count of quarter turns clockwise, which is
  /// what the crop itself applies to the output image.
  int get quarterTurns => turns % 4;

  /// How much a quarter-turned page has to shrink to keep fitting the box
  /// it was laid out in: turning a w x h box on its side makes it h x w,
  /// and the smaller of the two ratios is what fits either way round.
  double get rotatedScale =>
      aspectRatio <= 0 ? 1.0 : min(aspectRatio, 1 / aspectRatio);

  /// Scale for a rotation [turns] of the way through — a whole number of
  /// turns is a quarter turn's scale on the odd ones and none on the even,
  /// and everything between eases across.
  double scaleForTurns(double turns) =>
      1 + (rotatedScale - 1) * sin(turns * pi / 2).abs();

  /// Centre of the laid-out page, in the body's coordinates: everything
  /// the rotation does, it does around this point.
  Offset get displayCentre => Offset(
        canvasOffset.dx + canvasSize.width / 2,
        canvasOffset.dy + canvasSize.height / 2,
      );

  /// Where a point of the *unrotated* page — which is what every corner,
  /// slope and constraint in this class is expressed in — ends up on
  /// screen once the page has been turned.
  ///
  /// Keeping the geometry unrotated and transforming only at the edges is
  /// what lets rotation stay a display concern for the whole screen: the
  /// crop still maps canvas points onto the original photo exactly as it
  /// did before, and the turn is applied to the result instead.
  Offset toDisplay(Offset p, {double? turns}) {
    final t = turns ?? this.turns.toDouble();
    final angle = t * pi / 2;
    final scale = scaleForTurns(t);
    final centre = displayCentre;
    final v = p - centre;
    final c = cos(angle), s = sin(angle);
    return centre +
        Offset((v.dx * c - v.dy * s) * scale, (v.dx * s + v.dy * c) * scale);
  }

  /// The inverse of [toDisplay]: turns a touch on the rotated page back
  /// into the unrotated coordinates the polygon lives in.
  Offset fromDisplay(Offset p) {
    final angle = rotationAngle;
    final scale = scaleForTurns(turns.toDouble());
    final centre = displayCentre;
    final v = (p - centre) / (scale == 0 ? 1 : scale);
    final c = cos(-angle), s = sin(-angle);
    return centre + Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  /// Closest distance that neighbor point can exist: 10
  int crossoverThreshold = 10;

  /// Reverse step when neighbor crosses over: 11
  int crossoverAdjust = 11;

  /// Detects point from a distance: 20
  int pickupDistance = 20;

  /// Notifies magnifier when points move
  ValueNotifier<bool> showMagnifier = ValueNotifier(false);

  /// Notifies polygon when change occurs
  ValueNotifier<double> polygonUpdated = ValueNotifier(0);

  /// Notifies canvas when canvas image has rendered
  ValueNotifier<bool> imageRendered = ValueNotifier(false);

  /// Notifies canvas of the current detection state (loading / detected /
  /// notFound) so the UI always has a terminal state to render instead of
  /// spinning forever on a native exception.
  ValueNotifier<CropDetectionState> detectionState =
      ValueNotifier(CropDetectionState.loading);

  /// Notifies polygon when points are moved
  ValueNotifier<DragUpdateDetails> updatedPoint =
      ValueNotifier(DragUpdateDetails(globalPosition: Offset.zero));

  /// Detects the document boundary (pure-Dart, off the UI thread) and
  /// plots it on the canvas. Never leaves [detectionState] stuck on
  /// [CropDetectionState.loading]: any exception or timeout resolves to
  /// [CropDetectionState.notFound] so the user can still crop manually.
  Future<void> detectDocument() async {
    await getSize();

    try {
      final result = await compute(detectDocumentIsolateEntry, imageFile!.path)
          .timeout(const Duration(seconds: 8));

      if (result is DetectionSuccess) {
        detectedQuad = result.quad;
        detectionState.value = CropDetectionState.detected;
      } else {
        if (result is DetectionFailure) {
          debugPrint('Document detection failed: ${result.message}');
        }
        detectedQuad = null;
        detectionState.value = CropDetectionState.notFound;
      }
    } catch (e) {
      debugPrint('Document detection error: $e');
      detectedQuad = null;
      detectionState.value = CropDetectionState.notFound;
    }
  }

  /// Sets detected points on canvas
  initPoints() {
    double polygonArea = 0;
    double canvasArea = 1;

    /// Setting corner points to boundary
    setPointsToCorner() {
      tl = Offset(canvasOffset.dx, canvasOffset.dy);
      tr = Offset(canvasOffset.dx + canvasSize.width, canvasOffset.dy);
      bl = Offset(canvasOffset.dx, canvasOffset.dy + canvasSize.height);
      br = Offset(canvasOffset.dx + canvasSize.width,
          canvasOffset.dy + canvasSize.height);
    }

    /// Maps a detector point (in original-image pixel coordinates) to
    /// canvas coordinates.
    Offset toCanvas(Pt p) => Offset(
          (p.x / imageSize!.width) * canvasSize.width + canvasOffset.dx,
          (p.y / imageSize!.height) * canvasSize.height + canvasOffset.dy,
        );

    if (detectedQuad != null) {
      /// Setting corner points to detected location
      tl = toCanvas(detectedQuad!.topLeft);
      tr = toCanvas(detectedQuad!.topRight);
      br = toCanvas(detectedQuad!.bottomRight);
      bl = toCanvas(detectedQuad!.bottomLeft);

      polygonArea = areaOfQuadrilateral(tl, tr, bl, br);
      canvasArea = canvasSize.width * canvasSize.height;

      if (polygonArea / canvasArea < 0.2) setPointsToCorner();
    } else
      setPointsToCorner();

    /// Computing center points
    t = Offset((tl.dx + tr.dx) / 2, (tl.dy + tr.dy) / 2);
    b = Offset((bl.dx + br.dx) / 2, (bl.dy + br.dy) / 2);
    l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
    r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
  }

  /// Snaps the quad back to the full image, for the crop screen's "No
  /// crop" action. Distinct from [initPoints], which re-applies whatever
  /// the detector found.
  void resetPointsToCorners() {
    tl = Offset(canvasOffset.dx, canvasOffset.dy);
    tr = Offset(canvasOffset.dx + canvasSize.width, canvasOffset.dy);
    bl = Offset(canvasOffset.dx, canvasOffset.dy + canvasSize.height);
    br = Offset(
        canvasOffset.dx + canvasSize.width, canvasOffset.dy + canvasSize.height);

    t = Offset((tl.dx + tr.dx) / 2, (tl.dy + tr.dy) / 2);
    b = Offset((bl.dx + br.dx) / 2, (bl.dy + br.dy) / 2);
    l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
    r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
  }

  /// Updates the points in the polygon when changed manually
  updatePolygon() {
    debugPrint('Updated Point (local) => ${updatedPoint.value.localPosition}');
    debugPrint(
        'Updated Point (global) => ${updatedPoint.value.localPosition}');
    debugPrint('TL => $tl');
    debugPrint('TR => $tr');
    debugPrint('BL => $bl');
    debugPrint('BR => $br');

    if (movingPoint.name == 'tl') {
      Offset tlTemp =
          constraintPointToBoundary(updatedPoint.value.localPosition);

      // localToGlobal(updatedPoint.value.localPosition)
      if (checkPolygon(tlTemp, br, tr, bl)) {
        if (!checkCrossover(tlTemp, tr, bl, br, t, b, l, r)) {
          tl = tlTemp;
          t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
          l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
          movingPoint.offset = tl;
        }
      }
    } else if (movingPoint.name == 'tr') {
      Offset trTemp =
          constraintPointToBoundary(updatedPoint.value.localPosition);
      if (checkPolygon(tl, br, trTemp, bl)) {
        if (!checkCrossover(tl, trTemp, bl, br, t, b, l, r)) {
          tr = trTemp;
          t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
          r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
          movingPoint.offset = tr;
        }
      }
    } else if (movingPoint.name == 'bl') {
      Offset blTemp =
          constraintPointToBoundary(updatedPoint.value.localPosition);
      if (checkPolygon(tl, br, tr, blTemp)) {
        if (!checkCrossover(tl, tr, blTemp, br, t, b, l, r)) {
          bl = blTemp;
          l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
          b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
          movingPoint.offset = bl;
        }
      }
    } else if (movingPoint.name == 'br') {
      Offset brTemp =
          constraintPointToBoundary(updatedPoint.value.localPosition);
      if (checkPolygon(tl, brTemp, tr, bl)) {
        if (!checkCrossover(tl, tr, bl, brTemp, t, b, l, r)) {
          br = brTemp;
          b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
          r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
          movingPoint.offset = br;
        }
      }
    } else if (movingPoint.name == 't') {
      double yDisplacement =
          constraintPointToBoundary(updatedPoint.value.localPosition).dy -
              t.dy;

      Offset tlTemp = updatePoint(tl, bl, yDisplacement, 'x', lSlope);
      Offset trTemp = updatePoint(tr, br, yDisplacement, 'x', rSlope);

      // tlTemp = constraintPointToBoundary(tlTemp);
      // trTemp = constraintPointToBoundary(trTemp);

      if (checkPolygon(tlTemp, br, trTemp, bl)) {
        if (!checkCrossover(tlTemp, trTemp, bl, br, t, b, l, r)) {
          tl = tlTemp;
          tr = trTemp;
          t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
          l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
          r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
          movingPoint.offset = t;
        }
      }
    } else if (movingPoint.name == 'b') {
      double yDisplacement =
          constraintPointToBoundary(updatedPoint.value.localPosition).dy -
              b.dy;

      Offset blTemp = updatePoint(bl, tl, yDisplacement, 'x', lSlope);
      Offset brTemp = updatePoint(br, tr, yDisplacement, 'x', rSlope);

      // blTemp = constraintPointToBoundary(blTemp);
      // brTemp = constraintPointToBoundary(brTemp);

      if (checkPolygon(tl, brTemp, tr, blTemp)) {
        if (!checkCrossover(tl, tr, blTemp, brTemp, t, b, l, r)) {
          bl = blTemp;
          br = brTemp;
          b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
          l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
          r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
          movingPoint.offset = b;
        }
      }
    } else if (movingPoint.name == 'l') {
      double xDisplacement =
          constraintPointToBoundary(updatedPoint.value.localPosition).dx -
              l.dx;

      Offset tlTemp = updatePoint(tl, tr, xDisplacement, 'y', tSlope);
      Offset blTemp = updatePoint(bl, br, xDisplacement, 'y', bSlope);

      // tlTemp = constraintPointToBoundary(tlTemp);
      // blTemp = constraintPointToBoundary(blTemp);

      if (checkPolygon(tlTemp, br, tr, blTemp)) {
        if (!checkCrossover(tlTemp, tr, blTemp, br, t, b, l, r)) {
          tl = tlTemp;
          bl = blTemp;
          l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
          t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
          b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
          movingPoint.offset = l;
        }
      }
    } else if (movingPoint.name == 'r') {
      double xDisplacement =
          constraintPointToBoundary(updatedPoint.value.localPosition).dx -
              r.dx;

      Offset trTemp = updatePoint(tr, tl, xDisplacement, 'y', tSlope);
      Offset brTemp = updatePoint(br, bl, xDisplacement, 'y', bSlope);

      // trTemp = constraintPointToBoundary(trTemp);
      // brTemp = constraintPointToBoundary(brTemp);

      if (checkPolygon(tl, brTemp, trTemp, bl)) {
        if (!checkCrossover(tl, trTemp, bl, br, t, b, l, r)) {
          tr = trTemp;
          br = brTemp;
          r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
          t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
          b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
          movingPoint.offset = r;
        }
      }
    }

    polygonUpdated.value = tl.dx +
        tl.dy +
        tr.dx +
        tr.dy +
        bl.dx +
        bl.dy +
        br.dx +
        br.dy +
        t.dx +
        t.dy +
        l.dx +
        l.dy +
        r.dx +
        r.dy +
        l.dx +
        l.dy;
  }

  /// Crops the image to the current quad (pure-Dart, off the UI thread).
  /// Returns the [CropResult] so the caller can distinguish success from
  /// failure instead of the old code that discarded a `bool` result.
  Future<CropResult> crop() async {
    final scaleX = imageSize!.width / canvasSize.width;
    final scaleY = imageSize!.height / canvasSize.height;

    Pt scalePoint(Offset p) => Pt(
          scaleX * (p.dx - canvasOffset.dx),
          scaleY * (p.dy - canvasOffset.dy),
        );

    final quad = Quad(
      topLeft: scalePoint(tl),
      topRight: scalePoint(tr),
      bottomRight: scalePoint(br),
      bottomLeft: scalePoint(bl),
    );

    try {
      final result = await compute(cropImageIsolateEntry, {
        'path': imageFile!.path,
        'quad': quad,
        // The rotation is only ever shown, never applied to the file, so
        // it has to travel with the crop or it is lost on the way out.
        'quarterTurns': quarterTurns,
      }).timeout(const Duration(seconds: 15));
      debugPrint('cropper: ${imageFile!.path} => $result');
      return result;
    } catch (e) {
      debugPrint('Crop error: $e');
      return CropFailure(e.toString());
    }
  }

  /// Gets the current moving point
  getMovingPoint(DragStartDetails startDetails) {
    final pos = startDetails.localPosition;
    if (getDistance(pos.dx, pos.dy, tl.dx, tl.dy) < pickupDistance) {
      movingPoint.name = 'tl';
      movingPoint.offset = tl;
    } else if (getDistance(pos.dx, pos.dy, tr.dx, tr.dy) < pickupDistance) {
      movingPoint.name = 'tr';
      movingPoint.offset = tr;
    } else if (getDistance(pos.dx, pos.dy, bl.dx, bl.dy) < pickupDistance) {
      movingPoint.name = 'bl';
      movingPoint.offset = bl;
    } else if (getDistance(pos.dx, pos.dy, br.dx, br.dy) < pickupDistance) {
      movingPoint.name = 'br';
      movingPoint.offset = br;
    } else if (getDistance(pos.dx, pos.dy, t.dx, t.dy) < pickupDistance) {
      movingPoint.name = 't';
      movingPoint.offset = t;
    } else if (getDistance(pos.dx, pos.dy, b.dx, b.dy) < pickupDistance) {
      movingPoint.name = 'b';
      movingPoint.offset = b;
    } else if (getDistance(pos.dx, pos.dy, l.dx, l.dy) < pickupDistance) {
      movingPoint.name = 'l';
      movingPoint.offset = l;
    } else if (getDistance(pos.dx, pos.dy, r.dx, r.dy) < pickupDistance) {
      movingPoint.name = 'r';
      movingPoint.offset = r;
    } else {
      movingPoint.name = 'none';
    }
  }

  /// Calculates displacement of point wrt to slope
  ///
  /// The [updateAxis] in [p1] will be calculated with [slope] and [p2].
  ///
  /// The [displacement] is added to the other axis of [p1].
  ///
  /// Returns: Updated point [p1]
  Offset updatePoint(
    Offset p1,
    Offset p2,
    double displacement,
    String updateAxis,
    double slope,
  ) {
    if (updateAxis == 'x') {
      double x1 = p2.dx - ((p2.dy - p1.dy + displacement) / slope);
      p1 = Offset(x1, p1.dy + displacement);
    } else if (updateAxis == 'y') {
      double y1 = p2.dy - ((p2.dx - p1.dx + displacement) * slope);
      p1 = Offset(p1.dx + displacement, y1);
    }
    p1 = constraintPointToBoundary(p1);
    return p1;
  }

  /// Checks if the points form a closed convex polygon
  ///
  /// Returns: [True] if convex polygon, else [False]
  bool checkPolygon(Offset p1, Offset q1, Offset p2, Offset q2) {
    /// Checks if point q is between points p and r
    ///
    /// Returns: True if all lie on same line, else False
    bool onSegment(Offset p, Offset q, Offset r) {
      if (q.dx <= max(p.dx, r.dx) &&
          q.dx >= min(p.dx, r.dx) &&
          q.dy <= max(p.dy, r.dy) &&
          q.dy >= min(p.dy, r.dy)) return true;
      return false;
    }

    /// Finds the orientation of triangle
    int orientation(Offset p, Offset q, Offset r) {
      double val =
          (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);
      if (val == 0) return 0;
      return (val > 0) ? 1 : 2;
    }

    int o1 = orientation(p1, q1, p2);
    int o2 = orientation(p1, q1, q2);
    int o3 = orientation(p2, q2, p1);
    int o4 = orientation(p2, q2, q1);

    if (o1 != o2 && o3 != o4) return true;

    if (o1 == 0 && onSegment(p1, p2, q1)) return true;
    if (o2 == 0 && onSegment(p1, q2, q1)) return true;
    if (o3 == 0 && onSegment(p2, p1, q2)) return true;
    if (o4 == 0 && onSegment(p2, q1, q2)) return true;
    return false;
  }

  /// Checks if point is inside the boundary of image
  /// and returns a point constrained to the boundary
  ///
  /// Returns: Corrected Point [Offset]
  Offset constraintPointToBoundary(Offset point) {
    double topBoundary = canvasOffset.dy;
    double bottomBoundary = canvasOffset.dy + canvasSize.height;
    double leftBoundary = canvasOffset.dx;
    double rightBoundary = canvasOffset.dx + canvasSize.width;

    point =
        Offset((point.dx < leftBoundary) ? leftBoundary : point.dx, point.dy);
    point =
        Offset((point.dx > rightBoundary) ? rightBoundary : point.dx, point.dy);
    point = Offset(point.dx, (point.dy < topBoundary) ? topBoundary : point.dy);
    point = Offset(
        point.dx, (point.dy > bottomBoundary) ? bottomBoundary : point.dy);

    return point;
  }

  /// Check if points cross-over eachother
  ///
  /// Returns: [True] if points cross-over eachother, else [False]
  bool checkCrossover(Offset tl, Offset tr, Offset bl, Offset br, Offset t,
      Offset b, Offset l, Offset r) {
    if (tl.dx > tr.dx - crossoverThreshold) return true;
    if (bl.dx > br.dx - crossoverThreshold) return true;
    if (tl.dy > bl.dy - crossoverThreshold) return true;
    if (tr.dy > br.dy - crossoverThreshold) return true;

    if (t.dy > b.dy - crossoverThreshold) return true;
    if (l.dx > r.dx - crossoverThreshold) return true;

    return false;
  }

  /// Calculates the slope of all the edges of polygon
  calculateAllSlopes() {
    tSlope = getSlope(tl, tr);
    bSlope = getSlope(bl, br);
    lSlope = getSlope(tl, bl);
    rSlope = getSlope(tr, br);
  }

  /// Reads image size from file
  getSize() async {
    var decodedImage = await decodeImageFromList(imageFile!.readAsBytesSync());
    imageSize =
        Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
    aspectRatio = imageSize!.width / imageSize!.height;
    debugPrint(
        'Orginal Image=> ${imageSize!.width} / ${imageSize!.height} = $aspectRatio');
  }

  /// Gets the size of image canvas
  getRenderedBoxSize() {
    imageBox = imageKey.currentContext!.findRenderObject() as RenderBox;
    originalCanvasSize = imageBox.size;
    canvasSize = originalCanvasSize;
    debugPrint(
        'Renderbox=> $canvasSize=> ${canvasSize.width / canvasSize.height}');

    canvasOffset = imageBox.localToGlobal(
      Offset.zero,
      ancestor: bodyKey.currentContext!.findRenderObject() as RenderBox,
    );
    canvasOffset = Offset(canvasOffset.dx, canvasOffset.dy);
    debugPrint('Canvas Offset => $canvasOffset');

    verticalScaleFactor = screenSize.height / imageBox.size.width;
    debugPrint('VerticalScaleFactor=> $verticalScaleFactor');

    horizontalScaleFactor = screenSize.width / imageBox.size.height;
    debugPrint('HorizontalScaleFactor=> $horizontalScaleFactor');

    imageRendered.value = true;
  }

  /// Calculates slope from two points
  ///
  /// Return: Slope [double]
  double getSlope(Offset p1, Offset p2) {
    return (p2.dy - p1.dy) / (p2.dx - p1.dx);
  }

  /// Calculates the area of quadrilateral by
  /// adding the areas of 2 triangles
  ///
  /// Returns: Area of quadrilateral [double]
  double areaOfQuadrilateral(Offset tl, Offset tr, Offset bl, Offset br) {
    double top = getDistance(tl.dx, tl.dy, tr.dx, tr.dy);
    double right = getDistance(tr.dx, tr.dy, br.dx, br.dy);
    double bottom = getDistance(bl.dx, bl.dy, br.dx, br.dy);
    double left = getDistance(tl.dx, tl.dy, bl.dx, bl.dy);
    double middle = getDistance(tr.dx, tr.dy, bl.dx, bl.dy);

    double triangle1 = areaOfTriangle(top, left, middle);
    double triangle2 = areaOfTriangle(right, bottom, middle);

    return triangle1 + triangle2;
  }

  /// Calculates the area of a traingle from its sided (SSS)
  ///
  /// Returns: Area of triangle [double]
  double areaOfTriangle(double a, double b, double c) {
    double s = (a + b + c) / 2;
    return sqrt(s * (s - a) * (s - b) * (s - c));
  }

  /// Calculates the distance between two points
  ///
  /// Returns: Distance [double]
  double getDistance(double x1, double y1, double x2, double y2) {
    return sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2));
  }
}

class MovingPoint {
  String? name;
  Offset? offset;
  MovingPoint({this.name, this.offset = Offset.zero});
}
