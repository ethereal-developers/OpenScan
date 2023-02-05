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
  late Size originalCanvasSize;
  double verticalScaleFactor = 1;
  double horizontalScaleFactor = 1;
  late Offset tl, tr, bl, br, t, l, b, r;
  Size imageSizeNative = Size(600.0, 600.0);
  late DragStartDetails startPoint = DragStartDetails();

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

  /// Crops the image and returns the image
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
    ///
    /// Return: 0 if
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

  /// Check if points cross the boundary of image
  bool checkBoundary(Offset tl, Offset tr, Offset bl, Offset br) {
    double topBoundary = 0;
    double bottomBoundary = canvasSize.height;
    double leftBoundary = 0;
    double rightBoundary = canvasSize.width;

    if (tl.dx < leftBoundary || tl.dx > rightBoundary) return true;
    if (tl.dx < topBoundary || tl.dx > bottomBoundary) return true;

    if (tr.dx < leftBoundary || tr.dx > rightBoundary) return true;
    if (tr.dx < topBoundary || tr.dx > bottomBoundary) return true;

    if (bl.dx < leftBoundary || bl.dx > rightBoundary) return true;
    if (bl.dx < topBoundary || bl.dx > bottomBoundary) return true;

    if (br.dx < leftBoundary || br.dx > rightBoundary) return true;
    if (br.dx < topBoundary || br.dx > bottomBoundary) return true;

    return false;
  }

  /// Check if points cross-over eachother
  bool checkCrossover(Offset tl, Offset tr, Offset bl, Offset br) {
    if (tl.dx > tr.dx - crossoverThreshold) return true;
    if (bl.dx > br.dx - crossoverThreshold) return true;
    if (tl.dy > bl.dy - crossoverThreshold) return true;
    if (tr.dy > br.dy - crossoverThreshold) return true;

    if (t.dy > b.dy - crossoverThreshold) return true;
    if (l.dx > r.dx - crossoverThreshold) return true;

    return false;
  }

  /// Updates the points in the polygon when changed manually
  updatePolygon() {
    print('Start Point => ${startPoint.localPosition}');
    print('Update Point => ${updatedPoint.value.localPosition}');

    double x1 = startPoint.localPosition.dx;
    double y1 = startPoint.localPosition.dy;
    double x2 = tl.dx;
    double y2 = tl.dy;
    double x3 = tr.dx;
    double y3 = tr.dy;
    double x4 = bl.dx;
    double y4 = bl.dy;
    double x5 = br.dx;
    double y5 = br.dy;
    double x6 = t.dx;
    double y6 = t.dy;
    double x7 = b.dx;
    double y7 = b.dy;
    double x8 = l.dx;
    double y8 = l.dy;
    double x9 = r.dx;
    double y9 = r.dy;

    if (getDistance(x1, y1, x2, y2) < pickupDistance) {
      // bool isConvexPolygon = checkPolygon(
      //     Offset(tl.dx - crossoverThreshold, tl.dy + crossoverThreshold),
      //     br,
      //     tr,
      //     bl);

      // if (checkPolygon(updatedPoint.localPosition, br, tr, bl)) {
      // if (!checkBoundary(updatedPoint.localPosition, tr, bl, br)) {
      //   if (!checkCrossover(
      //       updatedPoint.localPosition, tr, bl, br)) {
      tl = updatedPoint.value.localPosition;
      //   }
      // }
      // }

      /// Check if TL has not crossed over TR
      /// then update TL with new position

      // if (tl.dx < tr.dx - crossoverThreshold) {
      //   if (!isConvexPolygon) {
      //     tl = Offset(tl.dx - crossoverAdjust, tl.dy - crossoverAdjust);
      //   } else {
      //     tl = updatedPoint.value.localPosition;
      //   }
      // } else {
      //   tl = Offset(tr.dx - crossoverAdjust, tl.dy);
      // }

      // if (tl.dy + crossoverThreshold > bl.dy) {
      //   tl = Offset(tl.dx, bl.dy - crossoverAdjust);
      // }

      t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
      l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
    } else if (getDistance(x1, y1, x3, y3) < 15 &&
        y1 >= 0 &&
        y1 <= canvasSize.height &&
        x1 < canvasSize.width &&
        x1 >= 0) {
      bool isConvexPolygon = checkPolygon(tl, br,
          Offset(tr.dx - crossoverThreshold, tr.dy - crossoverThreshold), bl);
      if (tr.dx > tl.dx + crossoverThreshold) {
        if (!isConvexPolygon) {
          tr = Offset(tr.dx + crossoverAdjust, tr.dy - crossoverAdjust);
        } else {
          tr = updatedPoint.value.localPosition;
        }
      } else {
        tr = Offset(tr.dx + crossoverAdjust, tr.dy);
      }
      if (tr.dy + crossoverThreshold > br.dy) {
        tr = Offset(tr.dx, br.dy - crossoverAdjust);
      }
      t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
      r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
    } else if (getDistance(x1, y1, x4, y4) < 15 &&
        y1 >= 0 &&
        y1 <= canvasSize.height &&
        x1 < canvasSize.width &&
        x1 >= 0) {
      bool isConvexPolygon = checkPolygon(
        tl,
        br,
        tr,
        Offset(bl.dx + crossoverThreshold, bl.dy - crossoverThreshold),
      );
      if (bl.dx < br.dx - crossoverThreshold) {
        if (!isConvexPolygon) {
          bl = Offset(bl.dx - crossoverAdjust, bl.dy + crossoverAdjust);
        } else {
          bl = updatedPoint.value.localPosition;
        }
      } else {
        bl = Offset(br.dx - crossoverAdjust, bl.dy);
      }
      if (bl.dy - crossoverThreshold < tl.dy) {
        bl = Offset(bl.dx, tl.dy + crossoverAdjust);
      }
      l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
      b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
    } else if (getDistance(x1, y1, x5, y5) < 15 &&
        y1 >= 0 &&
        y1 <= canvasSize.height &&
        x1 < canvasSize.width &&
        x1 >= 0) {
      bool isConvexPolygon = checkPolygon(
          tl,
          Offset(br.dx - crossoverThreshold, br.dy - crossoverThreshold),
          tr,
          bl);

      if (br.dx > bl.dx + crossoverThreshold) {
        if (!isConvexPolygon) {
          br = Offset(br.dx + crossoverAdjust, br.dy + crossoverAdjust);
        } else {
          br = updatedPoint.value.localPosition;
        }
      } else {
        br = Offset(br.dx + crossoverAdjust, br.dy);
      }

      if (br.dy - crossoverThreshold < tr.dy) {
        br = Offset(br.dx, tr.dy + crossoverAdjust);
      }

      b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
      r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
    } else if (getDistance(x1, y1, x6, y6) < 15 &&
        y1 >= 0 &&
        y1 <= canvasSize.height &&
        x1 < canvasSize.width &&
        x1 >= 0) {
      double displacement = updatedPoint.value.localPosition.dy - y6;

      // bool isConvexPolygon = checkPolygon(
      //     Offset(tl!.dx, tl!.dy + displacement),
      //     br!,
      //     Offset(tr!.dx, tr!.dy + displacement),
      //     bl!);

      // bool outOfBounds =
      //     (tl!.dy + displacement > 0 && tr!.dy + displacement > 0);

      if (t.dy + crossoverThreshold < b.dy) {
        // if (!isConvexPolygon) {
        //   t = Offset(br!.dx, br!.dy + crossoverAdjust);
        // } else {
        t = Offset(t.dx, updatedPoint.value.localPosition.dy);
        // }
      } else {
        t = Offset(t.dx, t.dy - crossoverAdjust);
      }

      if (tl.dy + displacement > 0) {
        tl = Offset(tl.dx, tl.dy + displacement);
      }
      if (tr.dy + displacement > 0) {
        tr = Offset(tr.dx, tr.dy + displacement);
      }

      l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
      r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
    } else if (getDistance(x1, y1, x7, y7) < 15 &&
        y1 >= 0 &&
        y1 <= canvasSize.height &&
        x1 < canvasSize.width &&
        x1 >= 0) {
      if (t.dy < b.dy - crossoverThreshold) {
        b = Offset(b.dx, updatedPoint.value.localPosition.dy);
      } else {
        b = Offset(b.dx, b.dy + crossoverAdjust);
      }
      double displacement = y7 - b.dy;
      if (bl.dy - displacement < canvasSize.height) {
        bl = Offset(bl.dx, bl.dy - displacement);
      }
      if (br.dy - displacement < canvasSize.height) {
        br = Offset(br.dx, br.dy - displacement);
      }
      l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
      r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
    } else if (getDistance(x1, y1, x8, y8) < 15 &&
        y1 >= 0 &&
        y1 <= canvasSize.height &&
        x1 < canvasSize.width &&
        x1 >= 0) {
      if (l.dx < r.dx - crossoverThreshold) {
        l = Offset(updatedPoint.value.localPosition.dx, l.dy);
      } else {
        l = Offset(l.dx, l.dy - crossoverAdjust);
      }
      double displacement = l.dx - x8;
      if (tl.dx + displacement > 0) {
        tl = Offset(tl.dx + displacement, tl.dy);
      }
      if (bl.dx + displacement > 0) {
        bl = Offset(bl.dx + displacement, bl.dy);
      }
      t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
      b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
    } else if (getDistance(x1, y1, x9, y9) < 15 &&
        y1 >= 0 &&
        y1 <= canvasSize.height &&
        x1 < canvasSize.width &&
        x1 >= 0) {
      if (l.dx < r.dx - crossoverThreshold) {
        r = Offset(updatedPoint.value.localPosition.dx, r.dy);
      } else {
        r = Offset(r.dx, r.dy + crossoverAdjust);
      }
      double displacement = x9 - r.dx;
      if (tr.dx - displacement < canvasSize.width) {
        tr = Offset(tr.dx - displacement, tr.dy);
      }
      if (br.dx - displacement < canvasSize.width) {
        br = Offset(br.dx - displacement, br.dy);
      }
      t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
      b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
    }

    if (tl.dx < 0) tl = Offset(0, tl.dy);
    if (tl.dy < 0) tl = Offset(tl.dx, 0);
    if (tr.dx > canvasSize.width) tr = Offset(canvasSize.width, tr.dy);
    if (tr.dy < 0) tr = Offset(tr.dx, 0);
    if (bl.dx < 0) bl = Offset(0, bl.dy);
    if (bl.dy > canvasSize.height) bl = Offset(bl.dx, canvasSize.height);
    if (br.dx > canvasSize.width) br = Offset(canvasSize.width, br.dy);
    if (br.dy > canvasSize.height) br = Offset(br.dx, canvasSize.height);

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

  /// Reads image size
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
