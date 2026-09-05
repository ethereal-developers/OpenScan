import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/cv/models/detection_result.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/core/cv/perspective_crop.dart';

/// Writes a [width]x[height] black JPEG with a solid red rectangle filling
/// the region between the given fractional bounds.
String _writeImageWithRedRegion(
  Directory dir,
  String name, {
  required int width,
  required int height,
  required double left,
  required double top,
  required double right,
  required double bottom,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(0, 0, 0));
  img.fillRect(
    image,
    x1: (left * width).round(),
    y1: (top * height).round(),
    x2: (right * width).round() - 1,
    y2: (bottom * height).round() - 1,
    color: img.ColorRgb8(255, 0, 0),
  );
  final path = '${dir.path}/$name';
  File(path).writeAsBytesSync(img.encodeJpg(image, quality: 100));
  return path;
}

/// Fraction of pixels in [image] that are predominantly red.
double _redFraction(img.Image image) {
  int red = 0;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      if (p.r > 150 && p.g < 100 && p.b < 100) red++;
    }
  }
  return red / (image.width * image.height);
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('perspective_crop_test');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('normalized crop maps overlay coordinates onto a portrait photo',
      () async {
    // The live overlay's quad is fractional and portrait-oriented, exactly
    // like the region drawn here.
    final path = _writeImageWithRedRegion(
      tempDir,
      'portrait.jpg',
      width: 400,
      height: 800,
      left: 0.25,
      top: 0.25,
      right: 0.75,
      bottom: 0.75,
    );

    final result = await cropImageNormalizedIsolateEntry({
      'path': path,
      'quad': const Quad(
        topLeft: Pt(0.25, 0.25),
        topRight: Pt(0.75, 0.25),
        bottomRight: Pt(0.75, 0.75),
        bottomLeft: Pt(0.25, 0.75),
      ),
    });

    expect(result, isA<CropSuccess>());

    final cropped = img.decodeImage(File(path).readAsBytesSync())!;
    // Half the width and half the height of the 400x800 source.
    expect(cropped.width, closeTo(200, 2));
    expect(cropped.height, closeTo(400, 2));
    // The crop landed on the red region, not somewhere in the black.
    expect(_redFraction(cropped), greaterThan(0.95));
  });

  test('normalized crop rotates the overlay quad for a landscape photo',
      () async {
    // A photo that decoded landscape while the overlay quad is portrait:
    // portrait (x, y) corresponds to sensor (y, 1 - x), so a quad sitting
    // in the overlay's top-left maps to the photo's bottom-left.
    final path = _writeImageWithRedRegion(
      tempDir,
      'landscape.jpg',
      width: 800,
      height: 400,
      left: 0.1,
      top: 0.5,
      right: 0.5,
      bottom: 0.9,
    );

    final result = await cropImageNormalizedIsolateEntry({
      'path': path,
      'quad': const Quad(
        topLeft: Pt(0.1, 0.1),
        topRight: Pt(0.5, 0.1),
        bottomRight: Pt(0.5, 0.5),
        bottomLeft: Pt(0.1, 0.5),
      ),
    });

    expect(result, isA<CropSuccess>());

    final cropped = img.decodeImage(File(path).readAsBytesSync())!;
    expect(_redFraction(cropped), greaterThan(0.95));
  });

  test('reports failure for an undecodable file', () async {
    final path = '${tempDir.path}/bad.jpg';
    File(path).writeAsBytesSync([1, 2, 3]);

    final result = await cropImageNormalizedIsolateEntry({
      'path': path,
      'quad': const Quad(
        topLeft: Pt(0, 0),
        topRight: Pt(1, 0),
        bottomRight: Pt(1, 1),
        bottomLeft: Pt(0, 1),
      ),
    });

    expect(result, isA<CropFailure>());
  });
}
