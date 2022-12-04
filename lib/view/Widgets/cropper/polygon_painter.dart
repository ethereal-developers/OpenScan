import 'package:flutter/material.dart';
import 'package:openscan/core/theme/appTheme.dart';

class PolygonPainter extends CustomPainter {
  final Offset? tl, tr, bl, br, t, l, r, b;
  // final List<Offset> points;
  final double dotRadius = 15.0;

  PolygonPainter({
    this.tl,
    this.tr,
    this.bl,
    this.br,
    this.t,
    this.l,
    this.r,
    this.b,
    // required this.points,
  });

  Paint linesConnectingDots = Paint()
    ..color = AppTheme.secondaryColor.withOpacity(0.4)
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill;

  Paint linesConnectingDotsOutline = Paint()
    ..color = AppTheme.secondaryColor.withOpacity(0.9)
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  Paint dots = Paint()
    ..color = AppTheme.secondaryColor.withOpacity(0.6)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(t!, dotRadius, linesConnectingDots);
    canvas.drawCircle(b!, dotRadius, linesConnectingDots);
    canvas.drawCircle(l!, dotRadius, linesConnectingDots);
    canvas.drawCircle(r!, dotRadius, linesConnectingDots);

    canvas.drawCircle(t!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(b!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(l!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(r!, dotRadius, linesConnectingDotsOutline);

    canvas.drawCircle(tl!, dotRadius, linesConnectingDots);
    canvas.drawCircle(tr!, dotRadius, linesConnectingDots);
    canvas.drawCircle(bl!, dotRadius, linesConnectingDots);
    canvas.drawCircle(br!, dotRadius, linesConnectingDots);

    canvas.drawCircle(tl!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(tr!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(bl!, dotRadius, linesConnectingDotsOutline);
    canvas.drawCircle(br!, dotRadius, linesConnectingDotsOutline);

    canvas.drawLine(tl!, tr!, dots);
    canvas.drawLine(tr!, br!, dots);
    canvas.drawLine(br!, bl!, dots);
    canvas.drawLine(bl!, tl!, dots);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
