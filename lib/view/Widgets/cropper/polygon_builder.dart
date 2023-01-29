import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openscan/view/Widgets/cropper/polygon_painter.dart';
import 'package:vector_math/vector_math.dart' as vector;

class PolygonBuilder extends StatefulWidget {
  final Size canvasSize;
  final Size originalCanvasSize;
  final dynamic updatedPoints;
  final bool documentDetected;
  final Offset? tl, tr, bl, br;
  final double rotationAngle;

  const PolygonBuilder({
    Key? key,
    required this.canvasSize,
    required this.rotationAngle,
    required this.updatedPoints,
    required this.documentDetected,
    required this.originalCanvasSize,
    this.tl,
    this.tr,
    this.bl,
    this.br,
  }) : super(key: key);

  @override
  State<PolygonBuilder> createState() => _PolygonBuilderState();
}

class _PolygonBuilderState extends State<PolygonBuilder> {
  int crossoverThreshold = 5;
  int crossoverAdjust = 6;
  Offset? tl, tr, bl, br, t, l, b, r;
  double? prevWidth, prevHeight = 0;
  GlobalKey canvasKey = GlobalKey();

  /// Canvas dimensions
  late double width, height;

  /// Sets the points to the document if detected
  /// else to corners of the image
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
      canvasArea = widget.canvasSize.width * widget.canvasSize.height;
    }

    print('Document detected: $documentDetected');
    if (documentDetected &&
        topLeft != null &&
        polygonArea! / canvasArea! > 0.2) {
      // getPointsAfterRotation(topLeft, topRight!, bottomLeft!, bottomRight!);

      tl = topLeft;
      tr = topRight;
      bl = bottomLeft;
      br = bottomRight;
    } else {
      tl = Offset(0, 0);
      tr = Offset(width, 0);
      bl = Offset(0, height);
      br = Offset(width, height);
    }

    t = Offset((tl!.dx + tr!.dx) / 2, (tl!.dy + tr!.dy) / 2);
    b = Offset((bl!.dx + br!.dx) / 2, (bl!.dy + br!.dy) / 2);
    l = Offset((tl!.dx + bl!.dx) / 2, (tl!.dy + bl!.dy) / 2);
    r = Offset((tr!.dx + br!.dx) / 2, (tr!.dy + br!.dy) / 2);

    // setState(() {
    // isLoading = false;
    // hasWidgetLoaded = true;
    // });
    // scaleFactor = width / height;
    // if (isRenderBoxValuesCorrect) return;
  }

  /// Detected points are rotated to 90*, 180* and 270* angles
  // getPointsAfterRotation(
  //   Offset topLeft,
  //   Offset topRight,
  //   Offset bottomLeft,
  //   Offset bottomRight,
  // ) {
  //   // Canvas scaling
  //   double w_h = widget.canvasSize.width / widget.originalCanvasSize.height;
  //   double h_w = widget.canvasSize.height / widget.originalCanvasSize.width;
  //   double w_w = widget.canvasSize.width / widget.originalCanvasSize.width;
  //   double h_h = widget.canvasSize.height / widget.originalCanvasSize.height;
  //   if (vector.degrees(widget.rotationAngle) == 90) {
  //     //     (height - y)
  //     // x = ------------ * width_new
  //     //         height
  //     //
  //     //        x
  //     // y = -------- * width_new
  //     //      height
  //     // Focal point --> bl
  //     tl = Offset((widget.canvasSize.height - bottomLeft.dy) * w_h,
  //         bottomLeft.dx * h_w);
  //     tr = Offset(
  //         (widget.canvasSize.height - topLeft.dy) * w_h, topLeft.dx * h_w);
  //     bl = Offset((widget.canvasSize.height - bottomRight.dy) * w_h,
  //         bottomRight.dx * h_w);
  //     br = Offset(
  //         (widget.canvasSize.height - topRight.dy) * w_h, topRight.dx * h_w);
  //   } else if (vector.degrees(widget.rotationAngle) == 180) {
  //     //     (width - x)
  //     // x = ------------ * width_new
  //     //         width
  //     //
  //     //     (height - y)
  //     // y = ------------ * height_new
  //     //         height
  //     // Focal point --> br
  //     tl = Offset((widget.canvasSize.width - bottomRight.dx) * w_w,
  //         (widget.canvasSize.height - bottomRight.dy) * h_h);
  //     tr = Offset((widget.canvasSize.width - bottomLeft.dx) * w_w,
  //         (widget.canvasSize.height - bottomLeft.dy) * h_h);
  //     bl = Offset((widget.canvasSize.width - topRight.dx) * w_w,
  //         (widget.canvasSize.height - topRight.dy) * h_h);
  //     br = Offset((widget.canvasSize.width - topLeft.dx) * w_w,
  //         (widget.canvasSize.height - topLeft.dy) * h_h);
  //   } else if (vector.degrees(widget.rotationAngle) == 270) {
  //     //        y
  //     // x = -------- * width_new
  //     //      height
  //     //
  //     //     (width - x)
  //     // y = ------------ * height_new
  //     //         width
  //     // Focal point --> tr
  //     tl = Offset(
  //         topRight.dy * w_h, (widget.canvasSize.width - topRight.dx) * h_w);
  //     tr = Offset(bottomRight.dy * w_h,
  //         (widget.canvasSize.width - bottomRight.dx) * h_w);
  //     bl = Offset(
  //         topLeft.dy * w_h, (widget.canvasSize.width - topLeft.dx) * h_w);
  //     br = Offset(
  //         bottomLeft.dy * w_h, (widget.canvasSize.width - bottomLeft.dx) * h_w);
  //   } else {
  //     // rotationAngle = 0*
  //     tl = topLeft;
  //     tr = topRight;
  //     bl = bottomLeft;
  //     br = bottomRight;
  //   }
  // }

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

  /// Updates the points in the polygon when changed manually
  updatePolygon() {
    double x1 = widget.updatedPoints.localPosition.dx;
    double y1 = widget.updatedPoints.localPosition.dy;
    double x2 = tl!.dx;
    double y2 = tl!.dy;
    double x3 = tr!.dx;
    double y3 = tr!.dy;
    double x4 = bl!.dx;
    double y4 = bl!.dy;
    double x5 = br!.dx;
    double y5 = br!.dy;
    double x6 = t!.dx;
    double y6 = t!.dy;
    double x7 = b!.dx;
    double y7 = b!.dy;
    double x8 = l!.dx;
    double y8 = l!.dy;
    double x9 = r!.dx;
    double y9 = r!.dy;

    if (getDistance(x1, y1, x2, y2) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        bool isConvexPolygon = checkPolygon(
            Offset(tl!.dx - crossoverThreshold, tl!.dy + crossoverThreshold),
            br!,
            tr!,
            bl!);
        if (tl!.dx < tr!.dx - crossoverThreshold) {
          if (!isConvexPolygon) {
            tl = Offset(tl!.dx - crossoverAdjust, tl!.dy - crossoverAdjust);
          } else {
            tl = widget.updatedPoints.localPosition;
          }
        } else {
          tl = Offset(tr!.dx - crossoverAdjust, tl!.dy);
        }
        if (tl!.dy + crossoverThreshold > bl!.dy) {
          tl = Offset(tl!.dx, bl!.dy - crossoverAdjust);
        }
        t = Offset((tr!.dx + tl!.dx) / 2, (tr!.dy + tl!.dy) / 2);
        l = Offset((tl!.dx + bl!.dx) / 2, (tl!.dy + bl!.dy) / 2);
      });
    } else if (getDistance(x1, y1, x3, y3) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        bool isConvexPolygon = checkPolygon(
            tl!,
            br!,
            Offset(tr!.dx - crossoverThreshold, tr!.dy - crossoverThreshold),
            bl!);
        if (tr!.dx > tl!.dx + crossoverThreshold) {
          if (!isConvexPolygon) {
            tr = Offset(tr!.dx + crossoverAdjust, tr!.dy - crossoverAdjust);
          } else {
            tr = widget.updatedPoints.localPosition;
          }
        } else {
          tr = Offset(tr!.dx + crossoverAdjust, tr!.dy);
        }
        if (tr!.dy + crossoverThreshold > br!.dy) {
          tr = Offset(tr!.dx, br!.dy - crossoverAdjust);
        }
        t = Offset((tr!.dx + tl!.dx) / 2, (tr!.dy + tl!.dy) / 2);
        r = Offset((tr!.dx + br!.dx) / 2, (tr!.dy + br!.dy) / 2);
      });
    } else if (getDistance(x1, y1, x4, y4) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        bool isConvexPolygon = checkPolygon(tl!, br!, tr!,
            Offset(bl!.dx + crossoverThreshold, bl!.dy - crossoverThreshold));
        if (bl!.dx < br!.dx - crossoverThreshold) {
          if (!isConvexPolygon) {
            bl = Offset(bl!.dx - crossoverAdjust, bl!.dy + crossoverAdjust);
          } else {
            bl = widget.updatedPoints.localPosition;
          }
        } else {
          bl = Offset(br!.dx - crossoverAdjust, bl!.dy);
        }
        if (bl!.dy - crossoverThreshold < tl!.dy) {
          bl = Offset(bl!.dx, tl!.dy + crossoverAdjust);
        }
        l = Offset((tl!.dx + bl!.dx) / 2, (tl!.dy + bl!.dy) / 2);
        b = Offset((br!.dx + bl!.dx) / 2, (br!.dy + bl!.dy) / 2);
      });
    } else if (getDistance(x1, y1, x5, y5) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        bool isConvexPolygon = checkPolygon(
            tl!,
            Offset(br!.dx - crossoverThreshold, br!.dy - crossoverThreshold),
            tr!,
            bl!);
        if (br!.dx > bl!.dx + crossoverThreshold) {
          if (!isConvexPolygon) {
            br = Offset(br!.dx + crossoverAdjust, br!.dy + crossoverAdjust);
          } else {
            br = widget.updatedPoints.localPosition;
          }
        } else {
          br = Offset(br!.dx + crossoverAdjust, br!.dy);
        }
        if (br!.dy - crossoverThreshold < tr!.dy) {
          br = Offset(br!.dx, tr!.dy + crossoverAdjust);
        }
        b = Offset((br!.dx + bl!.dx) / 2, (br!.dy + bl!.dy) / 2);
        r = Offset((tr!.dx + br!.dx) / 2, (tr!.dy + br!.dy) / 2);
      });
    } else if (getDistance(x1, y1, x6, y6) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        if (t!.dy + crossoverThreshold < b!.dy) {
          t = Offset(t!.dx, widget.updatedPoints.localPosition.dy);
        } else {
          t = Offset(t!.dx, t!.dy - crossoverAdjust);
        }
        double displacement = t!.dy - y6;
        if (tl!.dy + displacement > 0) {
          tl = Offset(tl!.dx, tl!.dy + displacement);
        }
        if (tr!.dy + displacement > 0) {
          tr = Offset(tr!.dx, tr!.dy + displacement);
        }
        l = Offset((tl!.dx + bl!.dx) / 2, (tl!.dy + bl!.dy) / 2);
        r = Offset((tr!.dx + br!.dx) / 2, (tr!.dy + br!.dy) / 2);
      });
    } else if (getDistance(x1, y1, x7, y7) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        if (t!.dy < b!.dy - crossoverThreshold) {
          b = Offset(b!.dx, widget.updatedPoints.localPosition.dy);
        } else {
          b = Offset(b!.dx, b!.dy + crossoverAdjust);
        }
        double displacement = y7 - b!.dy;
        if (bl!.dy - displacement < height) {
          bl = Offset(bl!.dx, bl!.dy - displacement);
        }
        if (br!.dy - displacement < height) {
          br = Offset(br!.dx, br!.dy - displacement);
        }
        l = Offset((tl!.dx + bl!.dx) / 2, (tl!.dy + bl!.dy) / 2);
        r = Offset((tr!.dx + br!.dx) / 2, (tr!.dy + br!.dy) / 2);
      });
    } else if (getDistance(x1, y1, x8, y8) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        if (l!.dx < r!.dx - crossoverThreshold) {
          l = Offset(widget.updatedPoints.localPosition.dx, l!.dy);
        } else {
          l = Offset(l!.dx, l!.dy - crossoverAdjust);
        }
        double displacement = l!.dx - x8;
        if (tl!.dx + displacement > 0) {
          tl = Offset(tl!.dx + displacement, tl!.dy);
        }
        if (bl!.dx + displacement > 0) {
          bl = Offset(bl!.dx + displacement, bl!.dy);
        }
        t = Offset((tr!.dx + tl!.dx) / 2, (tr!.dy + tl!.dy) / 2);
        b = Offset((br!.dx + bl!.dx) / 2, (br!.dy + bl!.dy) / 2);
      });
    } else if (getDistance(x1, y1, x9, y9) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        if (l!.dx < r!.dx - crossoverThreshold) {
          r = Offset(widget.updatedPoints.localPosition.dx, r!.dy);
        } else {
          r = Offset(r!.dx, r!.dy + crossoverAdjust);
        }
        double displacement = x9 - r!.dx;
        if (tr!.dx - displacement < width) {
          tr = Offset(tr!.dx - displacement, tr!.dy);
        }
        if (br!.dx - displacement < width) {
          br = Offset(br!.dx - displacement, br!.dy);
        }
        t = Offset((tr!.dx + tl!.dx) / 2, (tr!.dy + tl!.dy) / 2);
        b = Offset((br!.dx + bl!.dx) / 2, (br!.dy + bl!.dy) / 2);
      });
    }

    setState(() {
      if (tl!.dx < 0) tl = Offset(0, tl!.dy);
      if (tl!.dy < 0) tl = Offset(tl!.dx, 0);
      if (tr!.dx > width) tr = Offset(width, tr!.dy);
      if (tr!.dy < 0) tr = Offset(tr!.dx, 0);
      if (bl!.dx < 0) bl = Offset(0, bl!.dy);
      if (bl!.dy > height) bl = Offset(bl!.dx, height);
      if (br!.dx > width) br = Offset(width, br!.dy);
      if (br!.dy > height) br = Offset(br!.dx, height);
    });
  }

  @override
  void initState() {
    super.initState();
    width = widget.canvasSize.width;
    height = widget.canvasSize.height;
    print('polygon => ${widget.canvasSize}');
    setPolygonPoints(
      widget.documentDetected,
      topLeft: widget.tl,
      topRight: widget.tr,
      bottomLeft: widget.bl,
      bottomRight: widget.br,
    );
  }

  @override
  Widget build(BuildContext context) {
    updatePolygon();
    print('Corners => $tl $tr $bl $br');
    print('Centers => $t $b $l $r');

    return CustomPaint(
      painter: PolygonPainter(
        tl: tl,
        tr: tr,
        bl: bl,
        br: br,
        t: t,
        l: l,
        b: b,
        r: r,
        // points: widget.points,
      ),
    );
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
