import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/cv/frame_adapter.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/view/screens/live_scan/live_scan_controller.dart';

/// Builds a landscape-shaped (width > height) synthetic grayscale frame
/// with a light quadrilateral on a dark background, mirroring the
/// sensor-native shape a live camera frame would have — same synthetic-
/// fixture approach as test/cv/document_detector_test.dart, but building
/// the grayscale buffer directly instead of going through a JPEG decode.
Uint8List _buildSyntheticGrayFrame(int width, int height) {
  final gray = Uint8List(width * height)..fillRange(0, width * height, 20);
  const inset = 10;
  for (int y = inset; y < height - inset; y++) {
    for (int x = inset; x < width - inset; x++) {
      gray[y * width + x] = 220;
    }
  }
  return gray;
}

void main() {
  group('rotateQuadForPortrait', () {
    test('rotates sensor-space corners 90 degrees into portrait space', () {
      // Sensor-native landscape frame, 100x60. A quad near the frame's
      // corners should map into a quad near the corners of the rotated
      // 60x100 portrait space, still in canonical TL/TR/BR/BL order.
      const quad = Quad(
        topLeft: Pt(10, 5),
        topRight: Pt(90, 10),
        bottomRight: Pt(85, 55),
        bottomLeft: Pt(5, 50),
      );

      final rotated = rotateQuadForPortrait(quad, 100, 60);

      // frameHeight=60, so rotate(x,y) = (60-y, x), then normalized to
      // [0,1] by dividing by (frameHeight, frameWidth) = (60, 100).
      for (final p in rotated.points) {
        expect(p.x, inInclusiveRange(0, 1));
        expect(p.y, inInclusiveRange(0, 1));
      }
      // Canonical order preserved: topLeft has the smallest x+y.
      final sums = rotated.points.map((p) => p.x + p.y).toList();
      expect(sums.indexOf(sums.reduce((a, b) => a < b ? a : b)), 0);
    });
  });

  group('LiveScanController', () {
    test('start -> submitFrame -> latestQuad round trip through the worker isolate',
        () async {
      final controller = LiveScanController();
      await controller.start();
      addTearDown(controller.dispose);

      const width = 160, height = 120;
      final gray = _buildSyntheticGrayFrame(width, height);

      final completer = Completer<Quad?>();
      void listener() {
        if (controller.latestQuad.value != null && !completer.isCompleted) {
          completer.complete(controller.latestQuad.value);
        }
      }

      controller.latestQuad.addListener(listener);
      controller.submitFrame(gray, width, height);

      final quad = await completer.future.timeout(const Duration(seconds: 5));
      controller.latestQuad.removeListener(listener);

      expect(quad, isNotNull);
    });

    test('submitFrame no-ops while a previous frame is still in flight', () async {
      final controller = LiveScanController();
      await controller.start();
      addTearDown(controller.dispose);

      const width = 160, height = 120;
      final gray = _buildSyntheticGrayFrame(width, height);

      controller.submitFrame(gray, width, height);
      expect(controller.isBusy, isTrue);
      // Second submit while busy should be a no-op, not throw or queue.
      controller.submitFrame(gray, width, height);

      // Let the in-flight detection complete so dispose() doesn't race it.
      await Future.delayed(const Duration(milliseconds: 500));
    });

    test('lastLatencyMs is populated after a completed round trip', () async {
      final controller = LiveScanController();
      await controller.start();
      addTearDown(controller.dispose);

      const width = 160, height = 120;
      final gray = _buildSyntheticGrayFrame(width, height);

      expect(controller.lastLatencyMs.value, isNull);

      final completer = Completer<Quad?>();
      void listener() {
        if (controller.latestQuad.value != null && !completer.isCompleted) {
          completer.complete(controller.latestQuad.value);
        }
      }

      controller.latestQuad.addListener(listener);
      controller.submitFrame(gray, width, height);
      await completer.future.timeout(const Duration(seconds: 5));
      controller.latestQuad.removeListener(listener);

      expect(controller.lastLatencyMs.value, isNotNull);
      expect(controller.lastLatencyMs.value, greaterThanOrEqualTo(0));
    });
  });

  group('detection latency profiling', () {
    test('per-frame round-trip latency at the live-scan working resolution',
        () async {
      final controller = LiveScanController();
      await controller.start();
      addTearDown(controller.dispose);

      // Same shape the live-scan screen actually submits: long edge at
      // kLiveDetectionMaxDimension, ~4:3 short edge (frame_adapter.dart's
      // downsampling preserves the sensor's aspect ratio; 4:3 is the
      // common case for back-camera preview streams).
      final width = kLiveDetectionMaxDimension;
      final height = (kLiveDetectionMaxDimension * 3 / 4).round();
      final gray = _buildSyntheticGrayFrame(width, height);

      const sampleCount = 20;
      final latencies = <int>[];

      for (int i = 0; i < sampleCount; i++) {
        // Measured by the test itself, not read from lastLatencyMs:
        // ValueNotifier only notifies on a value *change*, and two
        // consecutive round trips landing on the same millisecond
        // (plausible at this speed) would silently skip a notification
        // and hang this loop. Timing the latestQuad round trip directly
        // (a freshly-allocated Quad every time, so it's never `==` to
        // the previous value) sidesteps that.
        final stopwatch = Stopwatch()..start();
        final completer = Completer<void>();
        void listener() {
          if (!completer.isCompleted) completer.complete();
        }

        controller.latestQuad.addListener(listener);
        controller.submitFrame(gray, width, height);
        await completer.future.timeout(const Duration(seconds: 5));
        controller.latestQuad.removeListener(listener);
        stopwatch.stop();
        latencies.add(stopwatch.elapsedMilliseconds);
      }

      latencies.sort();
      final p50 = latencies[(sampleCount * 0.5).floor()];
      final p95 = latencies[(sampleCount * 0.95).floor().clamp(0, sampleCount - 1)];

      // ignore: avoid_print
      print(
          'LiveScanController per-frame detection latency at ${width}x$height '
          '(host machine, $sampleCount samples): p50=${p50}ms p95=${p95}ms '
          'min=${latencies.first}ms max=${latencies.last}ms');

      // This runs on the test host (not the target Android device), so
      // it's a regression guard against a gross slowdown (e.g. an
      // accidentally-quadratic change to the edge/contour pipeline), not
      // a substitute for the real on-device profiling check called for
      // in the project plan before deciding whether the pure-Dart
      // pipeline needs an FFI fallback.
      expect(p50, lessThan(2000));
    });
  });
}
