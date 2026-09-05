import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/view/screens/live_scan/quad_smoother.dart';

/// A quad near the center of the normalized [0,1] space, optionally offset
/// by [dx]/[dy] — mirrors the helper in auto_capture_detector_test.dart.
Quad _quad({double dx = 0, double dy = 0}) => Quad(
      topLeft: Pt(0.1 + dx, 0.1 + dy),
      topRight: Pt(0.9 + dx, 0.1 + dy),
      bottomRight: Pt(0.9 + dx, 0.9 + dy),
      bottomLeft: Pt(0.1 + dx, 0.9 + dy),
    );

double _maxCornerDelta(Quad a, Quad b) {
  final pa = a.points, pb = b.points;
  double maxDelta = 0;
  for (int i = 0; i < 4; i++) {
    final dx = (pa[i].x - pb[i].x).abs();
    final dy = (pa[i].y - pb[i].y).abs();
    maxDelta = [maxDelta, dx, dy].reduce((a, b) => a > b ? a : b);
  }
  return maxDelta;
}

/// Mutable fake clock so tests can simulate elapsed time without real
/// delays — same pattern as auto_capture_detector_test.dart.
class _FakeClock {
  DateTime _time = DateTime(2026);
  DateTime now() => _time;
  void advance(Duration d) => _time = _time.add(d);
}

void main() {
  group('QuadSmoother', () {
    late _FakeClock clock;
    late QuadSmoother smoother;

    setUp(() {
      clock = _FakeClock();
      smoother = QuadSmoother(now: clock.now);
    });

    const step = Duration(milliseconds: 100);

    test('first sample is published as-is (no easing on seed)', () {
      final quad = _quad();
      smoother.onRawQuad(quad);
      expect(smoother.smoothedQuad.value, quad);
    });

    test('steady-state: repeatedly feeding the same quad converges to it', () {
      final quad = _quad();
      for (int i = 0; i < 20; i++) {
        smoother.onRawQuad(quad);
        clock.advance(step);
      }
      final smoothed = smoother.smoothedQuad.value!;
      expect(_maxCornerDelta(smoothed, quad), lessThan(0.001));
    });

    test(
        'noisy oscillation around a fixed point produces smaller frame-to-frame '
        'deltas than the raw input', () {
      final rawSequence = <Quad>[];
      for (int i = 0; i < 30; i++) {
        // Alternate a small +/- jitter around the same nominal position —
        // simulates the per-frame detection noise this class exists to
        // remove, with no real underlying movement.
        rawSequence.add(_quad(dx: i.isEven ? 0.015 : -0.015));
      }

      double maxRawDelta = 0;
      double maxSmoothedDelta = 0;
      Quad? prevRaw;
      Quad? prevSmoothed;

      for (final raw in rawSequence) {
        smoother.onRawQuad(raw);
        clock.advance(step);
        final smoothed = smoother.smoothedQuad.value!;

        if (prevRaw != null) {
          maxRawDelta =
              [maxRawDelta, _maxCornerDelta(prevRaw, raw)].reduce((a, b) => a > b ? a : b);
          maxSmoothedDelta = [maxSmoothedDelta, _maxCornerDelta(prevSmoothed!, smoothed)]
              .reduce((a, b) => a > b ? a : b);
        }
        prevRaw = raw;
        prevSmoothed = smoothed;
      }

      expect(maxSmoothedDelta, lessThan(maxRawDelta));
    });

    test('a fast sustained move is tracked within bounded lag, not permanently trailing',
        () {
      // Linearly interpolate a corner across 0.5 units over 5 samples —
      // a deliberate reposition, not noise.
      const steps = 5;
      for (int i = 1; i <= steps; i++) {
        smoother.onRawQuad(_quad(dx: 0.5 * i / steps));
        clock.advance(step);
      }
      // Let it settle at the final position for a few more samples.
      for (int i = 0; i < 30; i++) {
        smoother.onRawQuad(_quad(dx: 0.5));
        clock.advance(step);
      }

      final smoothed = smoother.smoothedQuad.value!;
      expect(_maxCornerDelta(smoothed, _quad(dx: 0.5)), lessThan(0.01));
    });

    test('a null sample within the grace period leaves smoothedQuad unchanged',
        () {
      final quad = _quad();
      smoother.onRawQuad(quad);
      clock.advance(step);
      final beforeNull = smoother.smoothedQuad.value;

      clock.advance(const Duration(milliseconds: 200));
      smoother.onRawQuad(null);

      expect(identical(smoother.smoothedQuad.value, beforeNull), isTrue);
    });

    test('resuming after a within-grace-period null does not re-settle (no state perturbation)',
        () {
      final quad = _quad();
      for (int i = 0; i < 10; i++) {
        smoother.onRawQuad(quad);
        clock.advance(step);
      }
      final steadyState = smoother.smoothedQuad.value!;

      clock.advance(const Duration(milliseconds: 200));
      smoother.onRawQuad(null); // within grace period, no-op
      clock.advance(const Duration(milliseconds: 50));

      smoother.onRawQuad(quad);
      final resumed = smoother.smoothedQuad.value!;

      expect(_maxCornerDelta(resumed, steadyState), lessThan(0.001));
    });

    test('a null gap past the grace period resets to null and the next sample '
        'reseeds without inherited lag', () {
      final quad = _quad();
      smoother.onRawQuad(quad);
      clock.advance(step);

      clock.advance(QuadSmoother.kNullGracePeriod + const Duration(milliseconds: 50));
      smoother.onRawQuad(null);
      expect(smoother.smoothedQuad.value, isNull);

      final farAwayQuad = _quad(dx: 0.5, dy: 0.5);
      smoother.onRawQuad(farAwayQuad);
      // Reseeded fresh: snaps directly to the new raw sample instead of
      // easing toward it from the old position.
      expect(smoother.smoothedQuad.value, farAwayQuad);
    });

    test('reset() clears state so the next sample is published as-is', () {
      final quad = _quad();
      for (int i = 0; i < 10; i++) {
        smoother.onRawQuad(quad);
        clock.advance(step);
      }

      smoother.reset();
      expect(smoother.smoothedQuad.value, isNull);

      final newQuad = _quad(dx: 0.3);
      smoother.onRawQuad(newQuad);
      expect(smoother.smoothedQuad.value, newQuad);
    });

    test('a corner-label swap between consecutive raw samples still produces a '
        'smooth trajectory (correspondence step)', () {
      final quad = _quad();
      for (int i = 0; i < 10; i++) {
        smoother.onRawQuad(quad);
        clock.advance(step);
      }
      final beforeSwap = smoother.smoothedQuad.value!;

      // Same 4 physical points, but relabeled as if sortCorners flipped
      // near a ~45-degree rotation: swap topLeft<->topRight and
      // bottomRight<->bottomLeft labels while keeping the actual
      // positions the same as `quad` (i.e. feed a "wrongly labeled" but
      // geometrically identical quad).
      final relabeled = Quad(
        topLeft: quad.topRight,
        topRight: quad.topLeft,
        bottomRight: quad.bottomLeft,
        bottomLeft: quad.bottomRight,
      );
      smoother.onRawQuad(relabeled);
      final afterSwap = smoother.smoothedQuad.value!;

      // Since the physical geometry didn't actually move, the smoothed
      // output shouldn't have jumped either, despite the raw input's
      // labels flipping.
      expect(_maxCornerDelta(beforeSwap, afterSwap), lessThan(0.01));
    });

    test('a single conflicting detection does not change the displayed output',
        () {
      final quad = _quad();
      for (int i = 0; i < 10; i++) {
        smoother.onRawQuad(quad);
        clock.advance(step);
      }
      final steadyState = smoother.smoothedQuad.value!;

      // A wildly different one-off detection — background clutter, a
      // shadow, a texture momentarily scoring well — should never reach
      // the displayed output.
      smoother.onRawQuad(_quad(dx: 0.6, dy: 0.6));
      expect(smoother.smoothedQuad.value, steadyState);

      // And tracking the original document resumes normally afterward.
      clock.advance(step);
      smoother.onRawQuad(quad);
      expect(_maxCornerDelta(smoother.smoothedQuad.value!, steadyState),
          lessThan(0.01));
    });

    test(
        'a conflicting detection that recurs kJumpConfirmFrameCount times in a '
        'row replaces the displayed output', () {
      final quad = _quad();
      smoother.onRawQuad(quad);
      clock.advance(step);

      final newDocument = _quad(dx: 0.6, dy: 0.6);
      for (int i = 0; i < QuadSmoother.kJumpConfirmFrameCount - 1; i++) {
        smoother.onRawQuad(newDocument);
        clock.advance(step);
        // Still unconfirmed — output hasn't moved yet.
        expect(smoother.smoothedQuad.value, quad);
      }

      // The confirming sample: streak reaches kJumpConfirmFrameCount. The
      // output now heads for the new document, but eases there through the
      // position filters rather than teleporting in one frame.
      smoother.onRawQuad(newDocument);
      final afterConfirm = smoother.smoothedQuad.value!;
      expect(_maxCornerDelta(afterConfirm, quad), greaterThan(0.0),
          reason: 'the track started moving');
      expect(_maxCornerDelta(afterConfirm, newDocument), greaterThan(0.001),
          reason: 'but did not jump straight onto the new shape');

      // Held there, it converges on the new document within a few frames.
      for (int i = 0; i < 12; i++) {
        clock.advance(step);
        smoother.onRawQuad(newDocument);
      }
      expect(_maxCornerDelta(smoother.smoothedQuad.value!, newDocument),
          lessThan(0.01));
    });

    test('an unrelated stray candidate does not build toward confirming a '
        'different jump', () {
      final quad = _quad();
      smoother.onRawQuad(quad);
      clock.advance(step);

      // Two different, mutually-far-apart stray candidates in a row never
      // accumulate a shared streak against each other.
      smoother.onRawQuad(_quad(dx: 0.6, dy: 0.6));
      clock.advance(step);
      smoother.onRawQuad(_quad(dx: -0.6, dy: -0.6));
      clock.advance(step);
      smoother.onRawQuad(_quad(dx: 0.6, dy: -0.6));
      clock.advance(step);

      // None of that should have displaced the original track.
      expect(smoother.smoothedQuad.value, quad);
    });
  });
}
