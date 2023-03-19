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

  Paint dotInnerShade = Paint()
    ..color = AppTheme.secondaryColor.withOpacity(0.4)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill;

  Paint dotOutline = Paint()
    ..color = AppTheme.secondaryColor.withOpacity(0.9)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  Paint linesConnectingDots = Paint()
    ..color = AppTheme.secondaryColor.withOpacity(0.8)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

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
