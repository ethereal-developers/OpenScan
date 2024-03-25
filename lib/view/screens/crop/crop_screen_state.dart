import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:openscan/core/data/native_android_util.dart';
import 'package:path/path.dart';

class CropScreenState {
  GlobalKey imageKey = GlobalKey();
  GlobalKey bodyKey = GlobalKey();
  File? srcImage;
  File? destImage;
  Size? imageSize;
  List detectedPointsData = [];
  late Size canvasSize;
  late Size screenSize;
  double aspectRatio = 1;
  double verticalScaleFactor = 1;
  double horizontalScaleFactor = 1;
  Offset canvasOffset = Offset.zero;
  late Offset tl, tr, bl, br, t, l, b, r;
  MovingPoint movingPoint = MovingPoint();
  Size imageSizeNative = Size(600.0, 600.0);
  late double tSlope, bSlope, rSlope, lSlope;
  bool isReset = false;
  bool isCroppingLoading = false;
  bool autoDetectTriggered = false;

  int errorOffset = 92;

  /// Scales image up or down while rotating
  bool scaleImage = false;

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

  /// Notifies canvas when edge detection is completed
  late ValueNotifier<bool> detectionCompleted = ValueNotifier(false);

  /// Notifies polygon when points are moved
  ValueNotifier<DragUpdateDetails> updatedPoint =
      ValueNotifier(DragUpdateDetails(globalPosition: Offset.zero));

  /// Edges of document is detected and plotted on canvas
  detectDocument() async {
    await getSize();

    detectedPointsData = await NativeAndroidUtil.detectDocument(srcImage!.path);
    // debugPrint('Points => $detectedPointsData');

    detectionCompleted.value = true;
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

    if (isReset || detectedPointsData.isEmpty) {
      setPointsToCorner();
      if (isReset) {
        isReset = false;
      } else if (autoDetectTriggered) {
        Fluttertoast.showToast(
          // TODO: need to do i18n
          msg: "Document not detected",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        autoDetectTriggered = false;
      }
    } else {
      /// Setting corner points to detected location
      /// PointsData: [br,tr,tl,bl]: (width, height)
      tl = Offset(
          (detectedPointsData[0][0] / imageSize!.width) * canvasSize.width +
              canvasOffset.dx,
          (detectedPointsData[0][1] / imageSize!.height) * canvasSize.height +
              canvasOffset.dy);
      tr = Offset(
          (detectedPointsData[1][0] / imageSize!.width) * canvasSize.width +
              canvasOffset.dx,
          (detectedPointsData[1][1] / imageSize!.height) * canvasSize.height +
              canvasOffset.dy);
      br = Offset(
          (detectedPointsData[2][0] / imageSize!.width) * canvasSize.width +
              canvasOffset.dx,
          (detectedPointsData[2][1] / imageSize!.height) * canvasSize.height +
              canvasOffset.dy);
      bl = Offset(
          (detectedPointsData[3][0] / imageSize!.width) * canvasSize.width +
              canvasOffset.dx,
          (detectedPointsData[3][1] / imageSize!.height) * canvasSize.height +
              canvasOffset.dy);

      polygonArea = areaOfQuadrilateral(tl, tr, bl, br);
      canvasArea = canvasSize.width * canvasSize.height;

      if (polygonArea / canvasArea < 0.2) {
        setPointsToCorner();
        if (autoDetectTriggered) {
          Fluttertoast.showToast(
            msg: "Document not detected",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          autoDetectTriggered = false;
        }
      }
    }

    /// Computing center points
    t = Offset((tl.dx + tr.dx) / 2, (tl.dy + tr.dy) / 2);
    b = Offset((bl.dx + br.dx) / 2, (bl.dy + br.dy) / 2);
    l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
    r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
  }

  /// Updates the points in the polygon when changed manually
  updatePolygon() {
    // debugPrint('Updated Point (local) => ${updatedPoint.value.localPosition}');
    // debugPrint(
    //     'Updated Point (global) => ${updatedPoint.value.globalPosition}');
    // debugPrint('TL => $tl');
    // debugPrint('TR => $tr');
    // debugPrint('BL => $bl');
    // debugPrint('BR => $br');

    if (movingPoint.name == 'tl') {
      Offset tlTemp =
          constraintPointToBoundary(updatedPoint.value.globalPosition);

      // localToGlobal(updatedPoint.value.globalPosition)
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
          constraintPointToBoundary(updatedPoint.value.globalPosition);
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
          constraintPointToBoundary(updatedPoint.value.globalPosition);
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
          constraintPointToBoundary(updatedPoint.value.globalPosition);
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
          constraintPointToBoundary(updatedPoint.value.globalPosition).dy -
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
          constraintPointToBoundary(updatedPoint.value.globalPosition).dy -
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
          constraintPointToBoundary(updatedPoint.value.globalPosition).dx -
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
          constraintPointToBoundary(updatedPoint.value.globalPosition).dx -
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

  /// Crops and returns the image
  crop() async {
    bool result = await NativeAndroidUtil.cropImage(
      srcPath: srcImage!.path,
      destPath: destImage!.path,
      tlX: (imageSize!.width / canvasSize.width) * (tl.dx - canvasOffset.dx),
      tlY: (imageSize!.height / canvasSize.height) * (tl.dy - canvasOffset.dy),
      trX: (imageSize!.width / canvasSize.width) * (tr.dx - canvasOffset.dx),
      trY: (imageSize!.height / canvasSize.height) * (tr.dy - canvasOffset.dy),
      blX: (imageSize!.width / canvasSize.width) * (bl.dx - canvasOffset.dx),
      blY: (imageSize!.height / canvasSize.height) * (bl.dy - canvasOffset.dy),
      brX: (imageSize!.width / canvasSize.width) * (br.dx - canvasOffset.dx),
      brY: (imageSize!.height / canvasSize.height) * (br.dy - canvasOffset.dy),
    );

    // debugPrint('cropper: ${srcImage!.path}');
  }

  /// Gets the current moving point
  getMovingPoint(DragStartDetails startDetails) {
    if (getDistance(startDetails.globalPosition.dx,
            startDetails.globalPosition.dy, tl.dx, tl.dy + errorOffset) <
        pickupDistance)
      movingPoint.name = 'tl';
    else if (getDistance(startDetails.globalPosition.dx,
            startDetails.globalPosition.dy, tr.dx, tr.dy + errorOffset) <
        pickupDistance)
      movingPoint.name = 'tr';
    else if (getDistance(startDetails.globalPosition.dx,
            startDetails.globalPosition.dy, bl.dx, bl.dy + errorOffset) <
        pickupDistance)
      movingPoint.name = 'bl';
    else if (getDistance(startDetails.globalPosition.dx,
            startDetails.globalPosition.dy, br.dx, br.dy + errorOffset) <
        pickupDistance)
      movingPoint.name = 'br';
    else if (getDistance(startDetails.globalPosition.dx,
            startDetails.globalPosition.dy, t.dx, t.dy + errorOffset) <
        pickupDistance)
      movingPoint.name = 't';
    else if (getDistance(startDetails.globalPosition.dx,
            startDetails.globalPosition.dy, b.dx, b.dy + errorOffset) <
        pickupDistance)
      movingPoint.name = 'b';
    else if (getDistance(startDetails.globalPosition.dx,
            startDetails.globalPosition.dy, l.dx, l.dy + errorOffset) <
        pickupDistance)
      movingPoint.name = 'l';
    else if (getDistance(startDetails.globalPosition.dx,
            startDetails.globalPosition.dy, r.dx, r.dy + errorOffset) <
        pickupDistance)
      movingPoint.name = 'r';
    else
      movingPoint.name = 'none';
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
      p1 = Offset(x1, p1.dy + displacement + errorOffset);
    } else if (updateAxis == 'y') {
      double y1 = p2.dy - ((p2.dx - p1.dx + displacement) * slope);
      p1 = Offset(p1.dx + displacement, y1 + errorOffset);
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
    // double topBoundary = 0;
    // double bottomBoundary = canvasSize.height;
    // double leftBoundary = 0;
    // double rightBoundary = canvasSize.width;
    double topBoundary = canvasOffset.dy + errorOffset;
    double bottomBoundary = canvasOffset.dy + errorOffset + canvasSize.height;
    double leftBoundary = canvasOffset.dx;
    double rightBoundary = canvasOffset.dx + canvasSize.width;

    point =
        Offset((point.dx < leftBoundary) ? leftBoundary : point.dx, point.dy);
    point =
        Offset((point.dx > rightBoundary) ? rightBoundary : point.dx, point.dy);
    point = Offset(point.dx, (point.dy < topBoundary) ? topBoundary : point.dy);
    point = Offset(
        point.dx, (point.dy > bottomBoundary) ? bottomBoundary : point.dy);

    point = Offset(point.dx, point.dy - errorOffset);
    return point;
  }

  /// Check if points cross-over eachother
  ///
  /// Returns: [true] if points cross-over eachother, else [false]
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
    var decodedImage = await decodeImageFromList(srcImage!.readAsBytesSync());
    imageSize =
        Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
    aspectRatio = imageSize!.width / imageSize!.height;
    getRenderedBoxSize();
    // debugPrint(
    //     'Orginal Image=> ${imageSize!.width} / ${imageSize!.height} = $aspectRatio');
  }

  /// Gets the size of image canvas
  getRenderedBoxSize() {
    RenderBox imageBox =
        imageKey.currentContext!.findRenderObject() as RenderBox;
    canvasSize = imageBox.size;
    debugPrint(
        'Renderbox=> $canvasSize=> ${canvasSize.width / canvasSize.height}');

    canvasOffset = imageBox.localToGlobal(
      Offset.zero,
      ancestor: bodyKey.currentContext!.findRenderObject() as RenderBox,
    );
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
