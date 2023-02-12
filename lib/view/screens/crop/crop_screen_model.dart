import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openscan/core/data/native_android_util.dart';

class CropScreenModel {
  GlobalKey imageKey = GlobalKey();
  File? imageFile;
  Size? imageSize;
  late Size canvasSize;
  late Size screenSize;
  bool isLoading = false;
  double aspectRatio = 1;
  late RenderBox imageBox;
  late double rotationAngle;
  String movingPoint = 'none';
  late Size originalCanvasSize;
  double verticalScaleFactor = 1;
  double horizontalScaleFactor = 1;
  late Offset tl, tr, bl, br, t, l, b, r;
  Size imageSizeNative = Size(600.0, 600.0);
  late double tSlope, bSlope, rSlope, lSlope;

  /// Scales image up or down while rotating
  bool scaleImage = false;

  /// Closest distance that neighbor point can exist: 10
  int crossoverThreshold = 10;

  /// Reverse step when neighbor crosses over: 11
  int crossoverAdjust = 11;

  /// Detects point from a distance: 20
  int pickupDistance = 20;

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

    List pointsData = await NativeAndroidUtil.detectDocument(imageFile!.path);
    print('Points => $pointsData');

    if (pointsData.isEmpty) {
      /// Setting corner points to boundary
      tl = Offset(0, 0);
      tr = Offset(canvasSize.width, 0);
      bl = Offset(0, canvasSize.height);
      br = Offset(canvasSize.width, canvasSize.height);
    } else {
      /// Setting corner points to detected location
      /// PointsData: [br,tr,tl,bl]: (width, height)
      tl = Offset((pointsData[0][0] / imageSize!.width) * canvasSize.width,
          (pointsData[0][1] / imageSize!.height) * canvasSize.height);
      tr = Offset((pointsData[1][0] / imageSize!.width) * canvasSize.width,
          (pointsData[1][1] / imageSize!.height) * canvasSize.height);
      br = Offset((pointsData[2][0] / imageSize!.width) * canvasSize.width,
          (pointsData[2][1] / imageSize!.height) * canvasSize.height);
      bl = Offset((pointsData[3][0] / imageSize!.width) * canvasSize.width,
          (pointsData[3][1] / imageSize!.height) * canvasSize.height);
    }

    /// Computing center points
    t = Offset((tl.dx + tr.dx) / 2, (tl.dy + tr.dy) / 2);
    b = Offset((bl.dx + br.dx) / 2, (bl.dy + br.dy) / 2);
    l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
    r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);

    detectionCompleted.value = true;
  }

  /// Updates the points in the polygon when changed manually
  updatePolygon() {
    if (movingPoint == 'tl') {
      Offset tlTemp =
          constraintPointToBoundary(updatedPoint.value.localPosition);
      if (checkPolygon(tlTemp, br, tr, bl)) {
        if (!checkCrossover(tlTemp, tr, bl, br, t, b, l, r)) {
          tl = tlTemp;
          t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
          l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
        }
      }
    } else if (movingPoint == 'tr') {
      Offset trTemp =
          constraintPointToBoundary(updatedPoint.value.localPosition);
      if (checkPolygon(tl, br, trTemp, bl)) {
        if (!checkCrossover(tl, trTemp, bl, br, t, b, l, r)) {
          tr = trTemp;
          t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
          r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
        }
      }
    } else if (movingPoint == 'bl') {
      Offset blTemp =
          constraintPointToBoundary(updatedPoint.value.localPosition);
      if (checkPolygon(tl, br, tr, blTemp)) {
        if (!checkCrossover(tl, tr, blTemp, br, t, b, l, r)) {
          bl = blTemp;
          l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
          b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
        }
      }
    } else if (movingPoint == 'br') {
      Offset brTemp =
          constraintPointToBoundary(updatedPoint.value.localPosition);
      if (checkPolygon(tl, brTemp, tr, bl)) {
        if (!checkCrossover(tl, tr, bl, brTemp, t, b, l, r)) {
          br = brTemp;
          b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
          r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
        }
      }
    } else if (movingPoint == 't') {
      double yDisplacement =
          constraintPointToBoundary(updatedPoint.value.localPosition).dy - t.dy;

      Offset tlTemp = updatePoint(tl, bl, yDisplacement, 'x', lSlope);
      Offset trTemp = updatePoint(tr, br, yDisplacement, 'x', rSlope);

      tlTemp = constraintPointToBoundary(tlTemp);
      trTemp = constraintPointToBoundary(trTemp);

      if (checkPolygon(tlTemp, br, trTemp, bl)) {
        if (!checkCrossover(tlTemp, trTemp, bl, br, t, b, l, r)) {
          tl = tlTemp;
          tr = trTemp;
          t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
          l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
          r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
        }
      }
    } else if (movingPoint == 'b') {
      double yDisplacement =
          constraintPointToBoundary(updatedPoint.value.localPosition).dy - b.dy;

      Offset blTemp = updatePoint(bl, tl, yDisplacement, 'x', lSlope);
      Offset brTemp = updatePoint(br, tr, yDisplacement, 'x', rSlope);

      blTemp = constraintPointToBoundary(blTemp);
      brTemp = constraintPointToBoundary(brTemp);

      if (checkPolygon(tl, brTemp, tr, blTemp)) {
        if (!checkCrossover(tl, tr, blTemp, brTemp, t, b, l, r)) {
          bl = blTemp;
          br = brTemp;
          b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
          l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
          r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
        }
      }
    } else if (movingPoint == 'l') {
      double xDisplacement =
          constraintPointToBoundary(updatedPoint.value.localPosition).dx - l.dx;

      Offset tlTemp = updatePoint(tl, tr, xDisplacement, 'y', tSlope);
      Offset blTemp = updatePoint(bl, br, xDisplacement, 'y', bSlope);

      tlTemp = constraintPointToBoundary(tlTemp);
      blTemp = constraintPointToBoundary(blTemp);

      if (checkPolygon(tlTemp, br, tr, blTemp)) {
        if (!checkCrossover(tlTemp, tr, blTemp, br, t, b, l, r)) {
          tl = tlTemp;
          bl = blTemp;
          l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
          t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
          b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
        }
      }
    } else if (movingPoint == 'r') {
      double xDisplacement =
          constraintPointToBoundary(updatedPoint.value.localPosition).dx - r.dx;

      Offset trTemp = updatePoint(tr, tl, xDisplacement, 'y', tSlope);
      Offset brTemp = updatePoint(br, bl, xDisplacement, 'y', bSlope);

      trTemp = constraintPointToBoundary(trTemp);
      brTemp = constraintPointToBoundary(brTemp);

      if (checkPolygon(tl, brTemp, trTemp, bl)) {
        if (!checkCrossover(tl, trTemp, bl, br, t, b, l, r)) {
          tr = trTemp;
          br = brTemp;
          r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
          t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
          b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
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
    Map imageSize = await NativeAndroidUtil.getImageSize(imageFile!.path);

    imageSizeNative =
        Size(imageSize['width']!.toDouble(), imageSize['height']!.toDouble());

    print(
        'Android Image size => ${imageSizeNative.width}/${imageSizeNative.height}');

    // TODO: Rotate [rotationAngle] and crop image

    // double tlX = (imageBitmapSize.width / width!) * tl!.dx;
    // double trX = (imageBitmapSize.width / width!) * tr!.dx;
    // double blX = (imageBitmapSize.width / width!) * bl!.dx;
    // double brX = (imageBitmapSize.width / width!) * br!.dx;

    // double tlY = (imageBitmapSize.height / height!) * tl!.dy;
    // double trY = (imageBitmapSize.height / height!) * tr!.dy;
    // double blY = (imageBitmapSize.height / height!) * bl!.dy;
    // double brY = (imageBitmapSize.height / height!) * br!.dy;

    // await channel.invokeMethod('cropImage', {
    //   'path': imageFile!.path,
    //   'tl_x': tlX,
    //   'tl_y': tlY,
    //   'tr_x': trX,
    //   'tr_y': trY,
    //   'bl_x': blX,
    //   'bl_y': blY,
    //   'br_x': brX,
    //   'br_y': brY,
    // });

    print('cropper: ${imageFile!.path}');
  }

  /// Sets the points to the document if detected else to corners of the image
  setPolygonPoints(
    bool documentDetected, {
    Offset? topLeft,
    Offset? topRight,
    Offset? bottomLeft,
    Offset? bottomRight,
  }) async {
    double? polygonArea;
    double? canvasArea;

    if (topLeft != null &&
        topRight != null &&
        bottomLeft != null &&
        bottomRight != null) {
      polygonArea =
          areaOfQuadrilateral(topLeft, topRight, bottomLeft, bottomRight);
      canvasArea = canvasSize.width * canvasSize.height;
    }

    print('Document detected: $documentDetected');
    if (documentDetected &&
        topLeft != null &&
        polygonArea! / canvasArea! > 0.2) {
      // getPointsAfterRotation(topLeft, topRight!, bottomLeft!, bottomRight!);

      tl = topLeft;
      tr = topRight!;
      bl = bottomLeft!;
      br = bottomRight!;
    } else {
      tl = Offset(0, 0);
      tr = Offset(canvasSize.width, 0);
      bl = Offset(0, canvasSize.height);
      br = Offset(canvasSize.width, canvasSize.height);
    }

    t = Offset((tl.dx + tr.dx) / 2, (tl.dy + tr.dy) / 2);
    b = Offset((bl.dx + br.dx) / 2, (bl.dy + br.dy) / 2);
    l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
    r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
  }

  /// Gets the current moving point
  getMovingPoint(DragStartDetails startDetails) {
    if (getDistance(startDetails.localPosition.dx,
            startDetails.localPosition.dy, tl.dx, tl.dy) <
        pickupDistance)
      movingPoint = 'tl';
    else if (getDistance(startDetails.localPosition.dx,
            startDetails.localPosition.dy, tr.dx, tr.dy) <
        pickupDistance)
      movingPoint = 'tr';
    else if (getDistance(startDetails.localPosition.dx,
            startDetails.localPosition.dy, bl.dx, bl.dy) <
        pickupDistance)
      movingPoint = 'bl';
    else if (getDistance(startDetails.localPosition.dx,
            startDetails.localPosition.dy, br.dx, br.dy) <
        pickupDistance)
      movingPoint = 'br';
    else if (getDistance(startDetails.localPosition.dx,
            startDetails.localPosition.dy, t.dx, t.dy) <
        pickupDistance)
      movingPoint = 't';
    else if (getDistance(startDetails.localPosition.dx,
            startDetails.localPosition.dy, b.dx, b.dy) <
        pickupDistance)
      movingPoint = 'b';
    else if (getDistance(startDetails.localPosition.dx,
            startDetails.localPosition.dy, l.dx, l.dy) <
        pickupDistance)
      movingPoint = 'l';
    else if (getDistance(startDetails.localPosition.dx,
            startDetails.localPosition.dy, r.dx, r.dy) <
        pickupDistance)
      movingPoint = 'r';
    else
      movingPoint = 'none';
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
    double topBoundary = 0;
    double bottomBoundary = canvasSize.height;
    double leftBoundary = 0;
    double rightBoundary = canvasSize.width;

    if (updateAxis == 'x') {
      double x1 = p2.dx - ((p2.dy - p1.dy + displacement) / slope);

      if (x1 < leftBoundary) x1 = leftBoundary;
      if (x1 > rightBoundary) x1 = rightBoundary;

      p1 = Offset(x1, p1.dy + displacement);
    } else if (updateAxis == 'y') {
      double y1 = p2.dy - ((p2.dx - p1.dx + displacement) * slope);

      if (y1 < topBoundary) y1 = topBoundary;
      if (y1 > bottomBoundary) y1 = bottomBoundary;

      p1 = Offset(p1.dx + displacement, y1);
    }
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

  /// Check if all tlbr points are inside the boundary of image
  ///
  /// Returns: [True] if points are inside the boundary, else [False]
  bool checkAllInsideBoundary(Offset tl, Offset tr, Offset bl, Offset br) {
    double topBoundary = 0;
    double bottomBoundary = canvasSize.height;
    double leftBoundary = 0;
    double rightBoundary = canvasSize.width;

    if (tl.dx < leftBoundary || tl.dx > rightBoundary) return false;
    if (tl.dy < topBoundary || tl.dy > bottomBoundary) return false;

    if (tr.dx < leftBoundary || tr.dx > rightBoundary) return false;
    if (tr.dy < topBoundary || tr.dy > bottomBoundary) return false;

    if (bl.dx < leftBoundary || bl.dx > rightBoundary) return false;
    if (bl.dy < topBoundary || bl.dy > bottomBoundary) return false;

    if (br.dx < leftBoundary || br.dx > rightBoundary) return false;
    if (br.dy < topBoundary || br.dy > bottomBoundary) return false;

    return true;
  }

  /// Checks if point is inside the boundary of image,
  /// else contraints the point to the boundary
  ///
  /// Returns: Corrected Point [Offset]
  Offset constraintPointToBoundary(Offset point) {
    double topBoundary = 0;
    double bottomBoundary = canvasSize.height;
    double leftBoundary = 0;
    double rightBoundary = canvasSize.width;

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
    getRenderedBoxSize();
    print(
        'Orginal Image=> ${imageSize!.width} / ${imageSize!.height} = $aspectRatio');
  }

  /// Gets the size of image canvas
  getRenderedBoxSize() {
    imageBox = imageKey.currentContext!.findRenderObject() as RenderBox;
    originalCanvasSize = imageBox.size;
    canvasSize = originalCanvasSize;
    print('Renderbox=> $canvasSize=> ${canvasSize.width / canvasSize.height}');

    verticalScaleFactor = screenSize.height / imageBox.size.width;
    print('VerticalScaleFactor=> $verticalScaleFactor');

    horizontalScaleFactor = screenSize.width / imageBox.size.height;
    print('HorizontalScaleFactor=> $horizontalScaleFactor');

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
