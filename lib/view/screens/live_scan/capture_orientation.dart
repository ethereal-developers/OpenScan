import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Which way up the phone is being held, tracked from the accelerometer.
///
/// The app is locked to portrait, and the camera writes every still as if
/// the phone were held that way — so a page shot with the phone on its
/// side came out on its side, and had to be turned by hand afterwards.
/// The accelerometer still knows how the phone is held while the UI
/// stays put; this turns that into the number of clockwise quarter turns
/// that stand a capture back up.
///
/// Gravity only says which way is down when the phone is tilted: lying
/// flat over a page on a table — the most common way to scan — it pulls
/// straight through the screen and says nothing about which edge is "up".
/// So the reading only moves on a clear tilt ([_kMinTilt]) and only once
/// the phone is well past the halfway point between two orientations
/// ([_kHysteresisDegrees]); otherwise the last confident answer stands,
/// which for a phone that never left the table is portrait.
class CaptureOrientation {
  /// Below this much gravity across the screen (m/s², ~12° of tilt from
  /// flat) the phone is treated as flat and the reading is left alone.
  static const double _kMinTilt = 2.0;

  /// How far past 45° from the current orientation the phone has to be
  /// turned before the reading changes, so it doesn't flicker when held
  /// at a diagonal.
  static const double _kHysteresisDegrees = 15;

  StreamSubscription<AccelerometerEvent>? _subscription;

  /// How far the phone is turned clockwise from upright portrait, in
  /// quarter turns (0–3).
  final ValueNotifier<int> deviceTurns = ValueNotifier(0);

  /// Clockwise quarter turns that bring a capture taken right now upright.
  /// The still's top edge is the phone's top edge, so with the phone
  /// turned clockwise onto its right edge, the page's real top is along
  /// the still's left edge — and a clockwise turn is what brings it up.
  /// The same number of turns as the phone, in the same direction.
  int get uprightTurns => deviceTurns.value;

  void start() {
    _subscription ??= accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
      (e) => onReading(e.x, e.y),
      // A phone without an accelerometer just keeps portrait.
      onError: (Object e) => debugPrint('No accelerometer: $e'),
      cancelOnError: true,
    );
  }

  /// Feeds one accelerometer reading. Android's axes: +x towards the right
  /// edge of the screen, +y towards the top, so an upright phone reads
  /// y ≈ +9.8 and one turned clockwise onto its right edge reads x ≈ -9.8.
  @visibleForTesting
  void onReading(double x, double y) {
    if (sqrt(x * x + y * y) < _kMinTilt) return;
    // 0° upright, increasing as the phone turns clockwise.
    final angle = (atan2(-x, y) * 180 / pi + 360) % 360;
    final current = deviceTurns.value * 90.0;
    var offset = (angle - current).abs() % 360;
    if (offset > 180) offset = 360 - offset;
    if (offset < 45 + _kHysteresisDegrees) return;
    deviceTurns.value = ((angle + 45) ~/ 90) % 4;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    deviceTurns.dispose();
  }
}
