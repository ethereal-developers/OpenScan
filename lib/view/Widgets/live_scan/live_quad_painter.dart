import 'package:flutter/material.dart';
import 'package:openscan/core/theme/appTheme.dart';

/// Read-only guidance overlay for the live-scan preview: paints a stroked
/// quad wherever the detector currently thinks the document edges are, or
/// nothing when no quad is detected. Unlike
/// `lib/view/Widgets/cropper/polygon_painter.dart` (which the static crop
/// screen uses), this has no drag handles or magnifier — it's purely a
/// visual aid to help the user frame the document before capturing.
class LiveQuadPainter extends CustomPainter {
  final List<Offset>? points; // [topLeft, topRight, bottomRight, bottomLeft]

  LiveQuadPainter({required this.points});

  final Paint _fill = Paint()
    ..color = AppTheme.secondaryColor.withValues(alpha: 0.15)
    ..style = PaintingStyle.fill;

  final Paint _stroke = Paint()
    ..color = AppTheme.secondaryColor.withValues(alpha: 0.9)
    ..strokeWidth = 3.0
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = points;
    if (pts == null || pts.length != 4) return;

    final path = Path()..addPolygon(pts, true);
    canvas.drawPath(path, _fill);
    canvas.drawPath(path, _stroke);
  }

  @override
  bool shouldRepaint(covariant LiveQuadPainter oldDelegate) =>
      oldDelegate.points != points;
}
