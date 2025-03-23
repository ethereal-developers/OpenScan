import 'package:flutter/material.dart';
import 'package:openscan/core/theme/appTheme.dart';

class PolygonPainter extends CustomPainter {
  final Offset? tl, tr, bl, br, t, l, r, b;
  final double cornerDotRadius = 10.0;
  final double centerDotRadius = 8.0;

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
    ..color = AppTheme.secondaryColor.withOpacity(0.2)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill;

  Paint dotOutline = Paint()
    ..color = AppTheme.secondaryColor.withOpacity(0.9)
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  Paint linesConnectingDots = Paint()
    ..color = AppTheme.secondaryColor.withOpacity(0.8)
    ..strokeWidth = 1.7
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw center dots if they exist
    if (t != null) {
      canvas.drawCircle(t!, centerDotRadius, dotInnerShade);
      canvas.drawCircle(t!, centerDotRadius, dotOutline);
    }
    if (b != null) {
      canvas.drawCircle(b!, centerDotRadius, dotInnerShade);
      canvas.drawCircle(b!, centerDotRadius, dotOutline);
    }
    if (l != null) {
      canvas.drawCircle(l!, centerDotRadius, dotInnerShade);
      canvas.drawCircle(l!, centerDotRadius, dotOutline);
    }
    if (r != null) {
      canvas.drawCircle(r!, centerDotRadius, dotInnerShade);
      canvas.drawCircle(r!, centerDotRadius, dotOutline);
    }

    // Draw corner dots if they exist
    if (tl != null) {
      canvas.drawCircle(tl!, cornerDotRadius, dotInnerShade);
      canvas.drawCircle(tl!, cornerDotRadius, dotOutline);
    }
    if (tr != null) {
      canvas.drawCircle(tr!, cornerDotRadius, dotInnerShade);
      canvas.drawCircle(tr!, cornerDotRadius, dotOutline);
    }
    if (bl != null) {
      canvas.drawCircle(bl!, cornerDotRadius, dotInnerShade);
      canvas.drawCircle(bl!, cornerDotRadius, dotOutline);
    }
    if (br != null) {
      canvas.drawCircle(br!, cornerDotRadius, dotInnerShade);
      canvas.drawCircle(br!, cornerDotRadius, dotOutline);
    }

    // Draw connecting lines if both endpoints exist
    if (tl != null && tr != null) {
      canvas.drawLine(tl!, tr!, linesConnectingDots);
    }
    if (tr != null && br != null) {
      canvas.drawLine(tr!, br!, linesConnectingDots);
    }
    if (br != null && bl != null) {
      canvas.drawLine(br!, bl!, linesConnectingDots);
    }
    if (bl != null && tl != null) {
      canvas.drawLine(bl!, tl!, linesConnectingDots);
    }
  }

  @override
  bool shouldRepaint(PolygonPainter oldDelegate) {
    return tl != oldDelegate.tl ||
        tr != oldDelegate.tr ||
        bl != oldDelegate.bl ||
        br != oldDelegate.br ||
        t != oldDelegate.t ||
        l != oldDelegate.l ||
        r != oldDelegate.r ||
        b != oldDelegate.b;
  }
}
