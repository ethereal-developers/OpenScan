import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openscan/view/Widgets/cropper/polygon_painter.dart';

class PolygonBuilder extends StatefulWidget {
  final Size canvasSize;
  const PolygonBuilder({
    Key? key,
    required this.canvasSize,
  }) : super(key: key);

  @override
  State<PolygonBuilder> createState() => _PolygonBuilderState();
}

class _PolygonBuilderState extends State<PolygonBuilder> {
  int crossoverThreshold = 5;
  int crossoverAdjust = 6;
  Offset? tl, tr, bl, br, t, l, b, r;
  double? prevWidth, prevHeight = 0;
  late double width, height;

  /// Sets the points to corners of the image
  void setPolygonPoints() async {
    // setState(() {
    //   isLoading = true;
    // });

    // TODO: Change Logic- Doesn't work for square images
    // if ((width == 0 && height == 0) ||
    //     (width == prevWidth && height == prevHeight)) {
    //   Timer(Duration(milliseconds: 100), () => setPolygonPoints());
    // } else {
    //   isRenderBoxValuesCorrect = true;
    //   prevHeight = height;
    //   prevWidth = width;
    // }

    t = Offset(width / 2, 0);
    b = Offset(width / 2, height);
    l = Offset(0, height / 2);
    r = Offset(width, height / 2);
    tl = Offset(0, 0);
    tr = Offset(width, 0);
    bl = Offset(0, height);
    br = Offset(width, height);

    setState(() {
      // isLoading = false;
      // hasWidgetLoaded = true;
    });

    // scaleFactor = width / height;

    // if (isRenderBoxValuesCorrect) return;
  }

  /// Checks if the points form a closed convex polygon
  bool checkPolygon(Offset p1, Offset q1, Offset p2, Offset q2) {
    bool onSegment(Offset p, Offset q, Offset r) {
      if (q.dx <= max(p.dx, r.dx) &&
          q.dx >= min(p.dx, r.dx) &&
          q.dy <= max(p.dy, r.dy) &&
          q.dy >= min(p.dy, r.dy)) return true;
      return false;
    }

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

  /// Updates the points in the polygon
  void updatePolygon(points) {
    double x1 = points.localPosition.dx;
    double y1 = points.localPosition.dy;
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

    if (sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2)) < 15 &&
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
            tl = points.localPosition;
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
    } else if (sqrt(pow((x3 - x1), 2) + pow((y3 - y1), 2)) < 15 &&
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
            tr = points.localPosition;
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
    } else if (sqrt(pow((x4 - x1), 2) + pow((y4 - y1), 2)) < 15 &&
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
            bl = points.localPosition;
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
    } else if (sqrt(pow((x5 - x1), 2) + pow((y5 - y1), 2)) < 15 &&
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
            br = points.localPosition;
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
    } else if (sqrt(pow((x6 - x1), 2) + pow((y6 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        if (t!.dy + crossoverThreshold < b!.dy) {
          t = Offset(t!.dx, points.localPosition.dy);
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
    } else if (sqrt(pow((x7 - x1), 2) + pow((y7 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        if (t!.dy < b!.dy - crossoverThreshold) {
          b = Offset(b!.dx, points.localPosition.dy);
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
    } else if (sqrt(pow((x8 - x1), 2) + pow((y8 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        if (l!.dx < r!.dx - crossoverThreshold) {
          l = Offset(points.localPosition.dx, l!.dy);
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
    } else if (sqrt(pow((x9 - x1), 2) + pow((y9 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        if (l!.dx < r!.dx - crossoverThreshold) {
          r = Offset(points.localPosition.dx, r!.dy);
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
  }

  @override
  Widget build(BuildContext context) {
    print('building polygon=> ${widget.canvasSize}');
    width = widget.canvasSize.width;
    height = widget.canvasSize.height;
    setPolygonPoints();
    return Container(
      // constraints: BoxConstraints(
      //   maxWidth: MediaQuery.of(context).size.width - 20,
      // ),
      child: CustomPaint(
        painter: PolygonPainter(
          tl: tl,
          tr: tr,
          bl: bl,
          br: br,
          t: t,
          l: l,
          b: b,
          r: r,
        ),
      ),
    );
  }
}
