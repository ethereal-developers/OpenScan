import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/cv/document_detector.dart';
import 'package:openscan/core/cv/models/detection_result.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/core/cv/perspective_crop.dart';

void main() {
  test('detectDocumentIsolateEntry works through compute()', () async {
    final tempDir = Directory.systemTemp.createTempSync('cv_isolate_test');
    final photoPath = '${tempDir.path}/document.jpg';

    final image = img.Image(width: 300, height: 400);
    img.fill(image, color: img.ColorRgb8(15, 15, 15));
    img.fillPolygon(
      image,
      vertices: [
        img.Point(30, 40),
        img.Point(270, 30),
        img.Point(280, 370),
        img.Point(20, 360),
      ],
      color: img.ColorRgb8(220, 220, 220),
    );
    File(photoPath).writeAsBytesSync(img.encodeJpg(image, quality: 95));

    final result = await compute(detectDocumentIsolateEntry, photoPath);
    expect(result, isA<DetectionSuccess>());

    final quad = (result as DetectionSuccess).quad;
    final cropResult = await compute(cropImageIsolateEntry, {
      'path': photoPath,
      'quad': quad,
    });
    expect(cropResult, isA<CropSuccess>());

    tempDir.deleteSync(recursive: true);
  });

  test('Quad/Pt survive a raw isolate round trip', () async {
    const quad = Quad(
      topLeft: Pt(1, 2),
      topRight: Pt(3, 4),
      bottomRight: Pt(5, 6),
      bottomLeft: Pt(7, 8),
    );
    final scaled = await compute<Quad, Quad>(_scaleQuad, quad);
    expect(scaled.topLeft.x, 2);
    expect(scaled.bottomLeft.y, 16);
  });
}

Quad _scaleQuad(Quad q) => q.scaled(2, 2);
