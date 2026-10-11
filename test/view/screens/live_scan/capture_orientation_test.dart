import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/view/screens/live_scan/capture_orientation.dart';

const _g = 9.8;

/// Gravity as the accelerometer reads it with the phone upright and then
/// turned [degrees] clockwise, tilted [tiltFromFlat] degrees up off a flat
/// table (90 = held vertical).
(double, double) _reading(double degrees, {double tiltFromFlat = 90}) {
  final r = degrees * pi / 180;
  final across = _g * sin(tiltFromFlat * pi / 180);
  return (-across * sin(r), across * cos(r));
}

void main() {
  late CaptureOrientation orientation;

  setUp(() => orientation = CaptureOrientation());
  tearDown(() => orientation.dispose());

  void hold(double degrees, {double tiltFromFlat = 90}) {
    final (x, y) = _reading(degrees, tiltFromFlat: tiltFromFlat);
    orientation.onReading(x, y);
  }

  test('starts upright, with nothing to turn', () {
    expect(orientation.deviceTurns.value, 0);
    expect(orientation.uprightTurns, 0);
  });

  test('turned clockwise onto its right edge needs one clockwise turn', () {
    hold(90);
    expect(orientation.deviceTurns.value, 1);
    expect(orientation.uprightTurns, 1);
  });

  test('turned anticlockwise onto its left edge needs three', () {
    hold(270);
    expect(orientation.uprightTurns, 3);
  });

  test('upside down needs two', () {
    hold(180);
    expect(orientation.uprightTurns, 2);
  });

  test('a diagonal hold does not flip the reading', () {
    hold(55); // past 45°, but inside the hysteresis band
    expect(orientation.deviceTurns.value, 0);
    hold(70);
    expect(orientation.deviceTurns.value, 1);
    hold(35); // back past 45°, still inside the band around landscape
    expect(orientation.deviceTurns.value, 1);
  });

  test('lying flat over a page keeps the last confident reading', () {
    hold(90);
    // Nearly flat, and nominally pointing the other way: not enough
    // gravity across the screen to say which edge is up.
    hold(270, tiltFromFlat: 5);
    expect(orientation.deviceTurns.value, 1);
  });

  test('a clear tilt off the table is still read', () {
    hold(90, tiltFromFlat: 30);
    expect(orientation.deviceTurns.value, 1);
  });
}
