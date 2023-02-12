import 'package:flutter/material.dart';
import 'package:openscan/core/theme/appTheme.dart';

class PolygonPainter extends CustomPainter {
  final Offset? tl, tr, bl, br, t, l, r, b;
  final double dotRadius = 11.0;

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
    canvas.drawCircle(t!, dotRadius, innerDot);
    canvas.drawCircle(b!, dotRadius, innerDot);
    canvas.drawCircle(l!, dotRadius, innerDot);
    canvas.drawCircle(r!, dotRadius, innerDot);

    canvas.drawCircle(t!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(b!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(l!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(r!, dotRadius, linesConnectingDotsOutline);

    canvas.drawCircle(tl!, dotRadius, innerDot);
    canvas.drawCircle(tr!, dotRadius, innerDot);
    canvas.drawCircle(bl!, dotRadius, innerDot);
    canvas.drawCircle(br!, dotRadius, innerDot);

    canvas.drawCircle(tl!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(tr!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(bl!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(br!, dotRadius, linesConnectingDotsOutline);

    canvas.drawLine(tl!, tr!, linesConnectingDots);
    canvas.drawLine(tr!, br!, linesConnectingDots);
    canvas.drawLine(br!, bl!, linesConnectingDots);
    canvas.drawLine(bl!, tl!, linesConnectingDots);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
