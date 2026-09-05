import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/cv/document_detector.dart';
import 'package:openscan/core/cv/models/detection_result.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/core/cv/perspective_crop.dart';

/// Builds a synthetic "document photo": a light quadrilateral (mildly
/// skewed, to exercise the perspective path) on a dark background, so the
/// pure-Dart edge/contour pipeline has a known target to find.
File _buildSyntheticDocumentPhoto(String path) {
  const width = 480;
  const height = 640;
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(20, 20, 20));

  img.fillPolygon(
    image,
    vertices: [
      img.Point(60, 90),
      img.Point(420, 60),
      img.Point(440, 580),
      img.Point(40, 560),
    ],
    color: img.ColorRgb8(230, 230, 230),
  );

  final bytes = img.encodeJpg(image, quality: 95);
  final file = File(path);
  file.writeAsBytesSync(bytes);
  return file;
}

void main() {
  final tempDir = Directory.systemTemp.createTempSync('cv_test');
  final photoPath = '${tempDir.path}/document.jpg';

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  test('detects a synthetic document quad', () async {
    final file = _buildSyntheticDocumentPhoto(photoPath);

    final result = await detectDocumentIsolateEntry(file.path);

    expect(result, isA<DetectionSuccess>());
    final success = result as DetectionSuccess;
    expect(success.imageWidth, 480);
    expect(success.imageHeight, 640);

    // Corners should roughly land near the drawn quad (allow slack for the
    // downscale/upscale round trip and simplification epsilon search).
    expect(success.quad.topLeft.x, closeTo(60, 40));
    expect(success.quad.topLeft.y, closeTo(90, 40));
    expect(success.quad.bottomRight.x, closeTo(440, 40));
    expect(success.quad.bottomRight.y, closeTo(580, 40));
  });

  test('crops the image to the detected quad', () async {
    final quad = const Quad(
      topLeft: Pt(60, 90),
      topRight: Pt(420, 60),
      bottomRight: Pt(440, 580),
      bottomLeft: Pt(40, 560),
    );

    final result = await cropImageIsolateEntry({
      'path': photoPath,
      'quad': quad,
    });

    expect(result, isA<CropSuccess>());
    final decoded = img.decodeImage(File(photoPath).readAsBytesSync());
    expect(decoded, isNotNull);
    // Cropped output should be close to the quad's own width/height, not
    // the original 480x640 frame.
    expect(decoded!.width, lessThan(420));
    expect(decoded.height, lessThan(560));
  });

  test('reports failure instead of hanging on a corrupt file', () async {
    final badFile = File('${tempDir.path}/not_an_image.jpg');
    badFile.writeAsBytesSync([1, 2, 3, 4]);

    final result = await detectDocumentIsolateEntry(badFile.path);
    expect(result, isA<DetectionFailure>());
  });
}
