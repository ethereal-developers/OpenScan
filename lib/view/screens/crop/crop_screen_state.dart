import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:openscan/core/data/native_android_util.dart';

enum CropScreenStatus { initial, loading, ready, error, processing }

class CropScreenState {
  // Constants
  static const double crossoverThreshold = 20.0;
  static const double pickupDistance = 20.0;

  // Status management
  final status = ValueNotifier<CropScreenStatus>(CropScreenStatus.initial);
  final renderBoxReady = ValueNotifier<bool>(false);
  final showMagnifier = ValueNotifier<bool>(false);
  final updatedPoint = ValueNotifier<DragUpdateDetails?>(null);
  final imageRendered = ValueNotifier<bool>(false);
  final polygonVersion = ValueNotifier<int>(0);
  final magnifierPosition = ValueNotifier<Offset?>(null);

  // Image properties
  File? srcImage;
  File? destImage;
  Size? imageSize;
  Size? screenSize;
  Size? canvasSize;
  Offset? canvasOffset;
  double? verticalScaleFactor;
  double? horizontalScaleFactor;
  double? aspectRatio;

  // Document corners
  Point<num> tl = Point(0, 0);
  Point<num> tr = Point(0, 0);
  Point<num> bl = Point(0, 0);
  Point<num> br = Point(0, 0);
  Point<num> t = Point(0, 0);
  Point<num> l = Point(0, 0);
  Point<num> b = Point(0, 0);
  Point<num> r = Point(0, 0);

  // UI elements
  final imageKey = GlobalKey();
  final bodyKey = GlobalKey();

  // Moving point state
  MovingPoint movingPoint = MovingPoint();
  String? errorMessage;
  bool autoDetectTriggered = false;
  List<dynamic> detectedPointsData = [];

  // Image dimensions and scaling
  double imageWidth = 0;
  double imageHeight = 0;
  double actualImageWidth = 0;
  double actualImageHeight = 0;
  double scaleX = 1.0;
  double scaleY = 1.0;

  // Slopes for point movement
  late double tSlope, bSlope, rSlope, lSlope;

  final EdgeInsets canvasPadding = const EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 16.0,
  );

  Rect? displayedImageRect;

  Future<void> initialize(File srcImage, File destImage) async {
    try {
      status.value = CropScreenStatus.loading;
      errorMessage = null;

      this.srcImage = srcImage;
      this.destImage = destImage;

      // Get image dimensions from file first
      final dimensions = await NativeAndroidUtil.getImageSize(srcImage.path);
      actualImageWidth = dimensions['width']?.toDouble() ?? 0;
      actualImageHeight = dimensions['height']?.toDouble() ?? 0;

      // Initialize points with default values
      initPoints();

      // Mark as ready - size will be updated when image is rendered
      status.value = CropScreenStatus.ready;
    } catch (e) {
      developer.log('Error initializing crop screen: $e',
          name: 'CropScreenState');
      errorMessage = 'Failed to initialize crop screen: ${e.toString()}';
      status.value = CropScreenStatus.error;
    }
  }

  Future<void> getSize() async {
    try {
      if (imageKey.currentContext == null) {
        throw Exception('Image context not available yet');
      }

      final RenderBox? renderBox =
          imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        throw Exception('RenderBox not available');
      }

      final size = renderBox.size;
      if (size.isEmpty) {
        throw Exception('Image size is empty');
      }

      imageWidth = size.width;
      imageHeight = size.height;
      imageSize = size;
      canvasSize = size;
      canvasOffset = renderBox.localToGlobal(
        Offset.zero,
        ancestor: bodyKey.currentContext?.findRenderObject() as RenderBox?,
      );

      // Calculate scale factors
      scaleX = actualImageWidth / size.width;
      scaleY = actualImageHeight / size.height;

      // Respect padding for the canvas
      final Size totalSize = screenSize ?? size;

      final double paddedW = totalSize.width - canvasPadding.horizontal;
      final double paddedH = totalSize.height - canvasPadding.vertical;

      final Size availableSize = Size(
        paddedW.clamp(0, double.infinity),
        paddedH.clamp(0, double.infinity),
      );

      final double widgetAspect = availableSize.width / availableSize.height;
      final double imageAspect = actualImageWidth / actualImageHeight;

      double displayWidth, displayHeight, dx, dy;
      if (imageAspect > widgetAspect) {
        displayWidth = availableSize.width;
        displayHeight = availableSize.width / imageAspect;
        dx = 0;
        dy = (availableSize.height - displayHeight) / 2;
      } else {
        displayHeight = availableSize.height;
        displayWidth = availableSize.height * imageAspect;
        dx = (availableSize.width - displayWidth) / 2;
        dy = 0;
      }

      // Offset by padding so the rect sits inside the padded area
      displayedImageRect = Rect.fromLTWH(
        canvasPadding.left + dx,
        canvasPadding.top + dy,
        displayWidth,
        displayHeight,
      );

      // Set initial points to displayed image rect
      setPointsToDisplayedImageRect();

      renderBoxReady.value = true;
    } catch (e) {
      developer.log('Error getting size: $e', name: 'CropScreenState');
      throw Exception('Failed to get image size: $e');
    }
  }

  void initPoints() {
    tl = Point(0, 0);
    tr = Point(0, 0);
    bl = Point(0, 0);
    br = Point(0, 0);
    t = Point(0, 0);
    l = Point(0, 0);
    b = Point(0, 0);
    r = Point(0, 0);
  }

  void setPointsToDisplayedImageRect() {
    if (displayedImageRect == null) {
      developer.log('Cannot set points: displayedImageRect is null',
          name: 'CropScreenState');
      return;
    }
    final rect = displayedImageRect!;
    tl = Point(0, 0);
    tr = Point(rect.width, 0);
    bl = Point(0, rect.height);
    br = Point(rect.width, rect.height);
    t = Point(rect.width / 2, 0);
    b = Point(rect.width / 2, rect.height);
    l = Point(0, rect.height / 2);
    r = Point(rect.width, rect.height / 2);
    developer.log('Points set to displayed image rect:',
        name: 'CropScreenState');
    developer.log('tl: $tl, tr: $tr, bl: $bl, br: $br',
        name: 'CropScreenState');
    developer.log('t: $t, b: $b, l: $l, r: $r', name: 'CropScreenState');
  }

  Point<num> _convertToCanvasCoordinates(List<dynamic> point) {
    print(
        'Converting point with actualImageWidth: $actualImageWidth, actualImageHeight: $actualImageHeight');
    print('canvasSize: $canvasSize, canvasOffset: $canvasOffset');
    print('Input point: $point');
    var convertedPoint = Point<num>(
      (point[0].toDouble() / actualImageWidth) * canvasSize!.width +
          canvasOffset!.dx,
      (point[1].toDouble() / actualImageHeight) * canvasSize!.height +
          canvasOffset!.dy,
    );
    print('Converted point: $convertedPoint');
    return convertedPoint;
  }

  Future<void> detectDocument() async {
    print('detectDocument started');
    try {
      if (srcImage == null) {
        print('srcImage is null');
        throw Exception('Source image is null');
      }
      print('srcImage path: ${srcImage!.path}');
      print('imageSize: $imageSize');
      print('canvasSize: $canvasSize');
      print('canvasOffset: $canvasOffset');

      print('Calling NativeAndroidUtil.detectDocument');
      detectedPointsData =
          await NativeAndroidUtil.detectDocument(srcImage!.path);
      print('Detected points data: $detectedPointsData');

      if (detectedPointsData.isEmpty) {
        print('No points detected');
        if (autoDetectTriggered) {
          _showToast('No document detected');
        }
        setPointsToDisplayedImageRect();
      } else {
        print('Converting points to canvas coordinates');
        // Convert detected points to canvas coordinates
        List<Point<num>> points = [];
        for (var point in detectedPointsData) {
          print('Converting point: $point');
          var convertedPoint = _convertToCanvasCoordinates(point);
          print('Converted to: $convertedPoint');
          points.add(convertedPoint);
        }
        print('Converted points: $points');

        // Update corner points
        if (points.length >= 4) {
          print('Updating corner points');
          tl = points[0];
          tr = points[1];
          br = points[2];
          bl = points[3];

          // Calculate area of detected quadrilateral
          double detectedArea = areaOfQuadrilateral(tl, tr, bl, br);
          double totalArea = canvasSize!.width * canvasSize!.height;
          double areaRatio = detectedArea / totalArea;

          print(
              'Detected area: $detectedArea, Total area: $totalArea, Ratio: $areaRatio');

          // If area is too small (less than 10% of total area), set to corners
          if (areaRatio < 0.1) {
            print('Detected area too small, setting to corners');
            setPointsToDisplayedImageRect();
            return;
          }

          print('Updated corner points:');
          print('tl: $tl');
          print('tr: $tr');
          print('br: $br');
          print('bl: $bl');

          // Update midpoints
          t = Point<num>((tl.x + tr.x) / 2, (tl.y + tr.y) / 2);
          b = Point<num>((bl.x + br.x) / 2, (bl.y + br.y) / 2);
          l = Point<num>((tl.x + bl.x) / 2, (tl.y + bl.y) / 2);
          r = Point<num>((tr.x + br.x) / 2, (tr.y + br.y) / 2);

          print('Updated midpoints:');
          print('t: $t');
          print('b: $b');
          print('l: $l');
          print('r: $r');
        } else {
          print('Not enough points detected: ${points.length}');
          setPointsToDisplayedImageRect();
        }
      }
    } catch (e, stackTrace) {
      print('Error in detectDocument: $e');
      print('Stack trace: $stackTrace');
      setPointsToDisplayedImageRect();
    }
  }

  Future<void> handleAutoDetect() async {
    print('handleAutoDetect called');
    autoDetectTriggered = true;
    try {
      if (srcImage == null) {
        print('srcImage is null in handleAutoDetect');
        return;
      }
      print('srcImage path: ${srcImage!.path}');
      print('Starting document detection process');
      await detectDocument();
      print('detectDocument completed successfully');
    } catch (e, stackTrace) {
      print('Error in handleAutoDetect: $e');
      print('Stack trace: $stackTrace');
      _showToast('Failed to detect document: ${e.toString()}');
    }
  }

  Future<bool> crop() async {
    try {
      status.value = CropScreenStatus.processing;

      if (srcImage == null || destImage == null || displayedImageRect == null) {
        throw Exception(
            'Source, destination image, or displayedImageRect is null');
      }

      // Calculate the scale factors between the displayed image and the actual image
      final scaleX = actualImageWidth / displayedImageRect!.width;
      final scaleY = actualImageHeight / displayedImageRect!.height;

      // Convert the local cropper points to actual image pixel coordinates
      final tlX = tl.x * scaleX;
      final tlY = tl.y * scaleY;
      final trX = tr.x * scaleX;
      final trY = tr.y * scaleY;
      final blX = bl.x * scaleX;
      final blY = bl.y * scaleY;
      final brX = br.x * scaleX;
      final brY = br.y * scaleY;

      print('Converted crop coordinates:');
      print('tl: ($tlX, $tlY)');
      print('tr: ($trX, $trY)');
      print('bl: ($blX, $blY)');
      print('br: ($brX, $brY)');

      final success = await NativeAndroidUtil.cropImage(
        srcPath: srcImage!.path,
        destPath: destImage!.path,
        tlX: tlX,
        tlY: tlY,
        trX: trX,
        trY: trY,
        blX: blX,
        blY: blY,
        brX: brX,
        brY: brY,
      );

      status.value = CropScreenStatus.ready;
      return success;
    } catch (e) {
      developer.log('Error during crop: $e', name: 'CropScreenState');
      errorMessage = 'Failed to crop image: ${e.toString()}';
      status.value = CropScreenStatus.error;
      return false;
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Updates the points in the polygon when changed manually
  void updatePolygon() {
    if (movingPoint.name == 'none' || updatedPoint.value == null) return;

    final localPosition = Point<num>(updatedPoint.value!.localPosition.dx,
        updatedPoint.value!.localPosition.dy);

    print('Updating polygon - Local position: $localPosition');
    print('Moving point: ${movingPoint.name}');

    if (movingPoint.name == 'tl') {
      Point<num> tlTemp = constraintPointToBoundary(localPosition);
      if (checkPolygon(tlTemp, br, tr, bl)) {
        if (!checkCrossover(tlTemp, tr, bl, br, t, b, l, r)) {
          tl = tlTemp;
        }
      }
    } else if (movingPoint.name == 'tr') {
      Point<num> trTemp = constraintPointToBoundary(localPosition);
      if (checkPolygon(tl, br, trTemp, bl)) {
        if (!checkCrossover(tl, trTemp, bl, br, t, b, l, r)) {
          tr = trTemp;
        }
      }
    } else if (movingPoint.name == 'bl') {
      Point<num> blTemp = constraintPointToBoundary(localPosition);
      if (checkPolygon(tl, br, tr, blTemp)) {
        if (!checkCrossover(tl, tr, blTemp, br, t, b, l, r)) {
          bl = blTemp;
        }
      }
    } else if (movingPoint.name == 'br') {
      Point<num> brTemp = constraintPointToBoundary(localPosition);
      if (checkPolygon(tl, brTemp, tr, bl)) {
        if (!checkCrossover(tl, tr, bl, brTemp, t, b, l, r)) {
          br = brTemp;
        }
      }
    } else if (movingPoint.name == 't') {
      // Move both top corners vertically
      double yDisplacement = (localPosition.y - t.y).toDouble();
      Point<num> tlTemp =
          constraintPointToBoundary(Point<num>(tl.x, tl.y + yDisplacement));
      Point<num> trTemp =
          constraintPointToBoundary(Point<num>(tr.x, tr.y + yDisplacement));
      if (checkPolygon(tlTemp, br, trTemp, bl)) {
        if (!checkCrossover(tlTemp, trTemp, bl, br, t, b, l, r)) {
          tl = tlTemp;
          tr = trTemp;
        }
      }
    } else if (movingPoint.name == 'b') {
      // Move both bottom corners vertically
      double yDisplacement = (localPosition.y - b.y).toDouble();
      Point<num> blTemp =
          constraintPointToBoundary(Point<num>(bl.x, bl.y + yDisplacement));
      Point<num> brTemp =
          constraintPointToBoundary(Point<num>(br.x, br.y + yDisplacement));
      if (checkPolygon(tl, brTemp, tr, blTemp)) {
        if (!checkCrossover(tl, tr, blTemp, brTemp, t, b, l, r)) {
          bl = blTemp;
          br = brTemp;
        }
      }
    } else if (movingPoint.name == 'l') {
      // Move both left corners horizontally
      double xDisplacement = (localPosition.x - l.x).toDouble();
      Point<num> tlTemp =
          constraintPointToBoundary(Point<num>(tl.x + xDisplacement, tl.y));
      Point<num> blTemp =
          constraintPointToBoundary(Point<num>(bl.x + xDisplacement, bl.y));
      if (checkPolygon(tlTemp, br, tr, blTemp)) {
        if (!checkCrossover(tlTemp, tr, blTemp, br, t, b, l, r)) {
          tl = tlTemp;
          bl = blTemp;
        }
      }
    } else if (movingPoint.name == 'r') {
      // Move both right corners horizontally
      double xDisplacement = (localPosition.x - r.x).toDouble();
      Point<num> trTemp =
          constraintPointToBoundary(Point<num>(tr.x + xDisplacement, tr.y));
      Point<num> brTemp =
          constraintPointToBoundary(Point<num>(br.x + xDisplacement, br.y));
      if (checkPolygon(tl, brTemp, trTemp, bl)) {
        if (!checkCrossover(tl, trTemp, bl, brTemp, t, b, l, r)) {
          tr = trTemp;
          br = brTemp;
        }
      }
    }

    // Always recalculate all midpoints after any move
    t = Point<num>((tl.x + tr.x) / 2, (tl.y + tr.y) / 2);
    b = Point<num>((bl.x + br.x) / 2, (bl.y + br.y) / 2);
    l = Point<num>((tl.x + bl.x) / 2, (tl.y + bl.y) / 2);
    r = Point<num>((tr.x + br.x) / 2, (tr.y + br.y) / 2);

    print('Updated points:');
    print('tl: $tl, tr: $tr, bl: $bl, br: $br');
    print('t: $t, b: $b, l: $l, r: $r');
    polygonVersion.value++;
  }

  /// Gets the current moving point
  void onPanStart(DragStartDetails details) {
    final Offset tapPosition = details.localPosition;
    String closestPoint = "none";
    double minDistance = double.infinity;

    final points = {
      'tl': tl,
      'tr': tr,
      'bl': bl,
      'br': br,
      't': t,
      'l': l,
      'b': b,
      'r': r,
    };

    for (var entry in points.entries) {
      final point = entry.value;
      final distance =
          (tapPosition - Offset(point.x.toDouble(), point.y.toDouble()))
              .distance;
      if (distance < minDistance && distance < pickupDistance) {
        minDistance = distance;
        closestPoint = entry.key;
      }
    }

    movingPoint.name = closestPoint;
  }

  Offset getMovingPointOffset() {
    switch (movingPoint.name) {
      case 'tl':
        return Offset(tl.x.toDouble(), tl.y.toDouble());
      case 'tr':
        return Offset(tr.x.toDouble(), tr.y.toDouble());
      case 'bl':
        return Offset(bl.x.toDouble(), bl.y.toDouble());
      case 'br':
        return Offset(br.x.toDouble(), br.y.toDouble());
      case 't':
        return Offset(t.x.toDouble(), t.y.toDouble());
      case 'l':
        return Offset(l.x.toDouble(), l.y.toDouble());
      case 'b':
        return Offset(b.x.toDouble(), b.y.toDouble());
      case 'r':
        return Offset(r.x.toDouble(), r.y.toDouble());
      default:
        return Offset.zero;
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (movingPoint.name == 'none') return;
    updatedPoint.value = details;
    final localPosition =
        Point<num>(details.localPosition.dx, details.localPosition.dy);
    movingPoint.offset = localPosition;
    // Only update magnifier if a point is being dragged
    if (movingPoint.name != 'none') {
      magnifierPosition.value = details.localPosition;
    }
    showMagnifier.value = true;
    updatePolygon();
    polygonVersion.value++;
  }

  void onPanEnd(DragEndDetails details) {
    if (movingPoint.name == 'none') return;
    updatePolygon();
    movingPoint = MovingPoint(name: 'none', offset: Point<num>(0, 0));
    updatedPoint.value = null;
    showMagnifier.value = false;
    magnifierPosition.value = null;
  }

  /// Calculates displacement of point wrt to slope
  ///
  /// The [updateAxis] in [p1] will be calculated with [slope] and [p2].
  ///
  /// The [displacement] is added to the other axis of [p1].
  ///
  /// Returns: Updated point [p1]
  Point<num> updatePoint(
    Point<num> p1,
    Point<num> p2,
    double displacement,
    String updateAxis,
    double slope,
  ) {
    if (updateAxis == 'x') {
      // For horizontal movement, update x and calculate y based on slope
      return Point<num>(
        p1.x + displacement,
        p1.y + (displacement * slope),
      );
    } else {
      // For vertical movement, update y and calculate x based on inverse slope
      return Point<num>(
        p1.x + (displacement / slope),
        p1.y + displacement,
      );
    }
  }

  /// Checks if the points form a closed convex polygon
  ///
  /// Returns: [True] if convex polygon, else [False]
  bool checkPolygon(
      Point<num> p1, Point<num> q1, Point<num> p2, Point<num> q2) {
    bool onSegment(Point<num> p, Point<num> q, Point<num> r) {
      return q.x <= max(p.x, r.x) &&
          q.x >= min(p.x, r.x) &&
          q.y <= max(p.y, r.y) &&
          q.y >= min(p.y, r.y);
    }

    int orientation(Point<num> p, Point<num> q, Point<num> r) {
      double val = (q.y.toDouble() - p.y.toDouble()) *
              (r.x.toDouble() - q.x.toDouble()) -
          (q.x.toDouble() - p.x.toDouble()) * (r.y.toDouble() - q.y.toDouble());

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
  /// Returns: Corrected Point [Point]
  Point<num> constraintPointToBoundary(Point<num> point) {
    double topBoundary = 0;
    double bottomBoundary = displayedImageRect?.height ?? canvasSize!.height;
    double leftBoundary = 0;
    double rightBoundary = displayedImageRect?.width ?? canvasSize!.width;

    return Point<num>(
      point.x.clamp(leftBoundary, rightBoundary),
      point.y.clamp(topBoundary, bottomBoundary),
    );
  }

  /// Check if points cross-over eachother
  ///
  /// Returns: [true] if points cross-over eachother, else [false]
  bool checkCrossover(
    Point<num> tl,
    Point<num> tr,
    Point<num> bl,
    Point<num> br,
    Point<num> t,
    Point<num> b,
    Point<num> l,
    Point<num> r,
  ) {
    if (tl.x.toDouble() > tr.x.toDouble() - crossoverThreshold) return true;
    if (bl.x.toDouble() > br.x.toDouble() - crossoverThreshold) return true;
    if (tl.y.toDouble() > bl.y.toDouble() - crossoverThreshold) return true;
    if (tr.y.toDouble() > br.y.toDouble() - crossoverThreshold) return true;
    return false;
  }

  /// Calculates the slope of all the edges of polygon
  calculateAllSlopes() {
    tSlope = getSlope(tl, tr);
    bSlope = getSlope(bl, br);
    lSlope = getSlope(tl, bl);
    rSlope = getSlope(tr, br);
  }

  /// Calculates slope from two points
  ///
  /// Return: Slope [double]
  double getSlope(Point<num> p1, Point<num> p2) {
    return (p2.y.toDouble() - p1.y.toDouble()) /
        (p2.x.toDouble() - p1.x.toDouble());
  }

  /// Calculates the area of quadrilateral by
  /// adding the areas of 2 triangles
  ///
  /// Returns: Area of quadrilateral [double]
  double areaOfQuadrilateral(
      Point<num> tl, Point<num> tr, Point<num> bl, Point<num> br) {
    double top = getDistance(
        tl.x.toDouble(), tl.y.toDouble(), tr.x.toDouble(), tr.y.toDouble());
    double right = getDistance(
        tr.x.toDouble(), tr.y.toDouble(), br.x.toDouble(), br.y.toDouble());
    double bottom = getDistance(
        br.x.toDouble(), br.y.toDouble(), bl.x.toDouble(), bl.y.toDouble());
    double left = getDistance(
        bl.x.toDouble(), bl.y.toDouble(), tl.x.toDouble(), tl.y.toDouble());

    double diagonal = getDistance(
        tl.x.toDouble(), tl.y.toDouble(), br.x.toDouble(), br.y.toDouble());

    double s = (top + right + bottom + left) / 2;
    double area = sqrt((s - top) * (s - right) * (s - bottom) * (s - left));

    return area;
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
    // debugPrint("x1 $x1 -- y1 $y1 -- x2 $x2 -- y2 $y2 ==== ${sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2))}");
    return sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2));
  }
}

class MovingPoint {
  String? name;
  Point<num>? offset;
  MovingPoint({this.name, this.offset = const Point<num>(0, 0)});
}
