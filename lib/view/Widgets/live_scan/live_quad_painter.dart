import 'package:flutter/material.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';

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

/// The capture acknowledgement: the detected document fills with light
/// from its bottom edge upward, instead of the whole screen blinking
/// white. The fill is clipped to the quad itself, so what flashes is
/// exactly the area that was just photographed.
///
/// [progress] runs 0 → 1 over the whole animation: the fill rises over the
/// first [_riseFraction] of it and the whole thing fades out over the
/// rest, so the page is never hidden for longer than the shot takes.
class CaptureFillPainter extends CustomPainter {
  final List<Offset>? points; // [topLeft, topRight, bottomRight, bottomLeft]
  final double progress;
  final Color color;

  static const double _riseFraction = 0.62;

  CaptureFillPainter({
    required this.points,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pts = points;
    if (pts == null || pts.length != 4 || progress <= 0) return;

    final rise = (progress / _riseFraction).clamp(0.0, 1.0);
    final fade = progress <= _riseFraction
        ? 1.0
        : 1.0 - ((progress - _riseFraction) / (1 - _riseFraction));
    final opacity = Curves.easeOut.transform(fade.clamp(0.0, 1.0));
    // Ease the rise so it leaves the bottom edge quickly and settles into
    // the top one, rather than sweeping at a constant machine-like speed.
    final level = Curves.easeOutCubic.transform(rise);

    final path = Path()..addPolygon(pts, true);
    final bounds = path.getBounds();
    if (bounds.isEmpty) return;

    final top = bounds.bottom - bounds.height * level;

    canvas.save();
    canvas.clipPath(path);

    // The body of the fill: brightest at the leading edge, thinning out
    // toward the bottom it rose from.
    final filled = Rect.fromLTRB(bounds.left, top, bounds.right, bounds.bottom);
    canvas.drawRect(
      filled,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.92 * opacity),
            color.withValues(alpha: 0.45 * opacity),
          ],
        ).createShader(filled),
    );

    // The leading edge itself, a bright line riding the top of the fill —
    // the part that reads as movement.
    if (level < 1) {
      canvas.drawRect(
        Rect.fromLTRB(bounds.left, top - 2, bounds.right, top + 2),
        Paint()..color = Colors.white.withValues(alpha: 0.95 * opacity),
      );
    }
    canvas.restore();

    // The outline stays lit for the whole animation, so the shape being
    // captured is legible even at the very start of the rise.
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * opacity)
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CaptureFillPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.points != points;
}


/// Corner-wise interpolation between two quads, so the overlay can be
/// animated from wherever it is drawn to wherever detection just put it.
class QuadTween extends Tween<Quad?> {
  QuadTween({super.begin, super.end});

  @override
  Quad? lerp(double t) {
    final from = begin, to = end;
    if (from == null || to == null) return to ?? from;
    Pt at(Pt a, Pt b) => Pt(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
    return Quad(
      topLeft: at(from.topLeft, to.topLeft),
      topRight: at(from.topRight, to.topRight),
      bottomRight: at(from.bottomRight, to.bottomRight),
      bottomLeft: at(from.bottomLeft, to.bottomLeft),
    );
  }
}

/// The detection overlay, drawn continuously rather than in steps.
///
/// Detection produces a result perhaps ten times a second; a display
/// updated only when a result arrives moves in visible increments no
/// matter how well filtered those results are. Each new [quad] instead
/// becomes the target of a short corner-wise tween from wherever the
/// overlay currently sits, so the corners slide at screen refresh rate
/// and land right about when the next detection replaces them.
///
/// The tween is linear on purpose: detection results are already smoothed
/// (`QuadSmoother`) and arrive at irregular intervals, and easing each
/// short hop on top of that reads as the overlay hesitating.
class LiveQuadOverlay extends StatelessWidget {
  const LiveQuadOverlay({
    super.key,
    required this.quad,
    required this.size,
    required this.accent,
    this.isImminent = false,
    this.duration = const Duration(milliseconds: 120),
  });

  /// The latest detection, in fractional [0,1] overlay coordinates.
  final Quad quad;

  /// Rendered size of the preview the overlay is painted over.
  final Size size;

  final Color accent;
  final bool isImminent;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Quad?>(
      tween: QuadTween(end: quad),
      duration: duration,
      curve: Curves.linear,
      builder: (context, value, _) => CustomPaint(
        size: size,
        painter: LiveQuadPainter(
          accent: accent,
          isImminent: isImminent,
          points: (value ?? quad)
              .points
              .map((p) => Offset(p.x * size.width, p.y * size.height))
              .toList(),
        ),
      ),
    );
  }
}
