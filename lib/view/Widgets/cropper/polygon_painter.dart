import 'package:flutter/material.dart';

class PolygonPainter extends CustomPainter {
  final Offset? tl, tr, bl, br, t, l, r, b;
  final double cornerDotRadius = 10.0;
  final double centerDotRadius = 8.0;

  /// The accent to draw the quad in. Passed in rather than read from a
  /// constant so the crop overlay follows the user's chosen accent colour.
  final Color accent;

  PolygonPainter({
    required this.accent,
    this.tl,
    this.tr,
    this.bl,
    this.br,
    this.t,
    this.l,
    this.r,
    this.b,
  })  : dotInnerShade = Paint()
          ..color = accent.withValues(alpha: 0.2)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.fill,
        dotOutline = Paint()
          ..color = accent.withValues(alpha: 0.9)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
        linesConnectingDots = Paint()
          ..color = accent.withValues(alpha: 0.8)
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round;

  final Paint dotInnerShade;
  final Paint dotOutline;
  final Paint linesConnectingDots;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(t!, centerDotRadius, dotInnerShade);
    canvas.drawCircle(b!, centerDotRadius, dotInnerShade);
    canvas.drawCircle(l!, centerDotRadius, dotInnerShade);
    canvas.drawCircle(r!, centerDotRadius, dotInnerShade);

    canvas.drawCircle(t!, centerDotRadius, dotOutline);
    canvas.drawCircle(b!, centerDotRadius, dotOutline);
    canvas.drawCircle(l!, centerDotRadius, dotOutline);
    canvas.drawCircle(r!, centerDotRadius, dotOutline);

    canvas.drawCircle(tl!, cornerDotRadius, dotInnerShade);
    canvas.drawCircle(tr!, cornerDotRadius, dotInnerShade);
    canvas.drawCircle(bl!, cornerDotRadius, dotInnerShade);
    canvas.drawCircle(br!, cornerDotRadius, dotInnerShade);

    canvas.drawCircle(tl!, cornerDotRadius, dotOutline);
    canvas.drawCircle(tr!, cornerDotRadius, dotOutline);
    canvas.drawCircle(bl!, cornerDotRadius, dotOutline);
    canvas.drawCircle(br!, cornerDotRadius, dotOutline);

    canvas.drawLine(tl!, tr!, linesConnectingDots);
    canvas.drawLine(tr!, br!, linesConnectingDots);
    canvas.drawLine(br!, bl!, linesConnectingDots);
    canvas.drawLine(bl!, tl!, linesConnectingDots);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
