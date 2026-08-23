import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/view/screens/live_scan/auto_capture_detector.dart';

/// A quad near the center of the normalized [0,1] space, optionally offset
/// by [dx]/[dy] to simulate hand-shake or deliberate movement between
/// frames.
Quad _quad({double dx = 0, double dy = 0}) => Quad(
      topLeft: Pt(0.1 + dx, 0.1 + dy),
      topRight: Pt(0.9 + dx, 0.1 + dy),
      bottomRight: Pt(0.9 + dx, 0.9 + dy),
      bottomLeft: Pt(0.1 + dx, 0.9 + dy),
    );

/// Mutable fake clock so tests can simulate elapsed time without real
/// delays, driven through the detector's injectable `now` parameter.
class _FakeClock {
  DateTime _time = DateTime(2026);
  DateTime now() => _time;
  void advance(Duration d) => _time = _time.add(d);
}

void main() {
  group('AutoCaptureDetector', () {
    late _FakeClock clock;
    late List<bool> stableCalls;
    late List<bool> imminentCalls;
    late AutoCaptureDetector detector;

    setUp(() {
      clock = _FakeClock();
      stableCalls = [];
      imminentCalls = [];
      detector = AutoCaptureDetector(
        onStable: () => stableCalls.add(true),
        onImminentChanged: (v) => imminentCalls.add(v),
        now: clock.now,
      );
    });

    // Chosen so that kStableFrameCount frames spent at this cadence lands
    // exactly at kMinStableDuration on the final frame (mirrors how the
    // constants themselves are tuned) — keeps these tests correct
    // automatically if either constant is retuned again later.
    final defaultStep = Duration(
      milliseconds: AutoCaptureDetector.kMinStableDuration.inMilliseconds ~/
          (AutoCaptureDetector.kStableFrameCount - 1),
    );

    void feedStableFrames(int count, {Duration? step}) {
      step ??= defaultStep;
      for (int i = 0; i < count; i++) {
        detector.onQuadUpdate(_quad());
        clock.advance(step);
      }
    }

    test('fires once after kStableFrameCount stable frames spanning kMinStableDuration', () {
      feedStableFrames(AutoCaptureDetector.kStableFrameCount);
      expect(stableCalls, hasLength(1));
    });

    test('does not fire with fewer than kStableFrameCount frames', () {
      feedStableFrames(AutoCaptureDetector.kStableFrameCount - 1);
      expect(stableCalls, isEmpty);
    });

    test('does not fire if the frames arrive faster than kMinStableDuration', () {
      // Enough frames, but with no simulated time passing between them.
      for (int i = 0; i < AutoCaptureDetector.kStableFrameCount; i++) {
        detector.onQuadUpdate(_quad());
      }
      expect(stableCalls, isEmpty);
    });

    test('movement beyond tolerance resets the window', () {
      feedStableFrames(AutoCaptureDetector.kStableFrameCount - 1);
      // A big jump breaks stability; only this one frame is in the new
      // window, nowhere near enough to fire.
      detector.onQuadUpdate(_quad(dx: 0.5));
      expect(stableCalls, isEmpty);
    });

    test('a null quad mid-run resets the window', () {
      feedStableFrames(AutoCaptureDetector.kStableFrameCount - 1);
      detector.onQuadUpdate(null);
      clock.advance(const Duration(milliseconds: 500));
      detector.onQuadUpdate(_quad());
      expect(stableCalls, isEmpty);
    });

    test('does not fire while disabled', () {
      detector.enabled = false;
      feedStableFrames(AutoCaptureDetector.kStableFrameCount);
      expect(stableCalls, isEmpty);
    });

    test('does not fire during cooldown after a capture', () {
      feedStableFrames(AutoCaptureDetector.kStableFrameCount);
      expect(stableCalls, hasLength(1));

      detector.notifyCaptured();
      expect(detector.isInCooldown, isTrue);

      feedStableFrames(AutoCaptureDetector.kStableFrameCount);
      expect(stableCalls, hasLength(1)); // still just the first firing

      clock.advance(AutoCaptureDetector.kCooldownDuration);
      feedStableFrames(AutoCaptureDetector.kStableFrameCount);
      expect(stableCalls, hasLength(2));
    });

    test('onImminentChanged transitions true then false on reset', () {
      feedStableFrames(AutoCaptureDetector.kStableFrameCount - 2);
      expect(imminentCalls, [true]);

      detector.onQuadUpdate(null);
      expect(imminentCalls, [true, false]);
    });

    test('onImminentChanged resets after notifyCaptured', () {
      feedStableFrames(AutoCaptureDetector.kStableFrameCount);
      expect(imminentCalls.last, isTrue);

      detector.notifyCaptured();
      expect(imminentCalls.last, isFalse);
    });
  });
}
