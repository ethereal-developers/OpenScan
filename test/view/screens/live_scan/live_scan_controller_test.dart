import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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
  });
}
