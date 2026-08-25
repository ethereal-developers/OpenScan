import 'package:flutter/material.dart';

/// Read-only guidance overlay for the live-scan preview: paints a stroked
/// quad wherever the detector currently thinks the document edges are, or
/// nothing when no quad is detected. Unlike
/// `lib/view/Widgets/cropper/polygon_painter.dart` (which the static crop
/// screen uses), this has no drag handles or magnifier — it's purely a
/// visual aid to help the user frame the document before capturing.
class LiveQuadPainter extends CustomPainter {
  final List<Offset>? points; // [topLeft, topRight, bottomRight, bottomLeft]

  /// Whether auto-capture is about to fire (document held stable long
  /// enough), used to give the overlay a distinct "capturing soon" look.
  final bool isImminent;

  /// The accent the resting quad is stroked in, so the overlay follows the
  /// user's chosen accent rather than a fixed brand orange.
  final Color accent;

  LiveQuadPainter({
    required this.points,
    required this.accent,
    this.isImminent = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pts = points;
    if (pts == null || pts.length != 4) return;

    final color = isImminent ? Colors.greenAccent : accent;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = isImminent ? 5.0 : 3.0
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..addPolygon(pts, true);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant LiveQuadPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.isImminent != isImminent;
}
