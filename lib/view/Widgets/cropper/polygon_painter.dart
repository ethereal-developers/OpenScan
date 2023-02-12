import 'package:flutter/material.dart';
import 'package:openscan/core/theme/appTheme.dart';

class PolygonPainter extends CustomPainter {
  final Offset? tl, tr, bl, br, t, l, r, b;
  final double cornerDotRadius = 12.0;
  final double centerDotRadius = 9.0;

  PolygonPainter({
    this.tl,
    this.tr,
    this.bl,
    this.br,
    this.t,
    this.l,
    this.r,
    this.b,
  });

  Paint innerDot = Paint()
    ..color = AppTheme.secondaryColor.withOpacity(0.4)
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill;

  Paint linesConnectingDotsOutline = Paint()
    ..color = AppTheme.secondaryColor.withOpacity(0.9)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  Paint linesConnectingDots = Paint()
    ..color = AppTheme.secondaryColor.withOpacity(0.7)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(t!, centerDotRadius, innerDot);
    canvas.drawCircle(b!, centerDotRadius, innerDot);
    canvas.drawCircle(l!, centerDotRadius, innerDot);
    canvas.drawCircle(r!, centerDotRadius, innerDot);

    canvas.drawCircle(t!, centerDotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(b!, centerDotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(l!, centerDotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(r!, centerDotRadius, linesConnectingDotsOutline);

    canvas.drawCircle(tl!, cornerDotRadius, innerDot);
    canvas.drawCircle(tr!, cornerDotRadius, innerDot);
    canvas.drawCircle(bl!, cornerDotRadius, innerDot);
    canvas.drawCircle(br!, cornerDotRadius, innerDot);

    canvas.drawCircle(tl!, cornerDotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(tr!, cornerDotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(bl!, cornerDotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(br!, cornerDotRadius, linesConnectingDotsOutline);

    canvas.drawLine(tl!, tr!, linesConnectingDots);
    canvas.drawLine(tr!, br!, linesConnectingDots);
    canvas.drawLine(br!, bl!, linesConnectingDots);
    canvas.drawLine(bl!, tl!, linesConnectingDots);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
