import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/cv/capture_pipeline.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('capture_pipeline'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// A portrait "photo" with a white page on a black background, the page
  /// occupying the middle half of the frame.
  File writePhoto({int width = 1200, int height = 1600}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(0, 0, 0));
    img.fillRect(image,
        x1: width ~/ 4,
        y1: height ~/ 4,
        x2: width * 3 ~/ 4,
        y2: height * 3 ~/ 4,
        color: img.ColorRgb8(255, 255, 255));
    final file = File('${dir.path}/photo.jpg')
      ..writeAsBytesSync(img.encodeJpg(image, quality: 92));
    return file;
  }

  Map<String, dynamic> params(File src, {Quad? quad, String? originalDest}) => {
        'src': src.path,
        'pageDest': '${dir.path}/page.jpg',
        'pageMaxEdge': 800,
        'pageQuality': 85,
        'quad': quad,
        'originalDest': originalDest,
        'originalMaxEdge': 1000,
        'originalQuality': 80,
      };

  test('stores an uncropped page, capped at the page size', () async {
    final result = await storeCaptureIsolateEntry(params(writePhoto()));

    expect(result['page'], isTrue);
    expect(result['cropped'], isFalse);
    expect(result['original'], isFalse);

    final page = img.decodeImage(File('${dir.path}/page.jpg').readAsBytesSync())!;
    expect(page.height, 800);
    expect(page.width, 600);
  });

  test('crops to the quad it is given, and caps that too', () async {
    // The page rectangle, in fractional coordinates of the same portrait
    // frame the live overlay works in.
    const quad = Quad(
      topLeft: Pt(0.25, 0.25),
      topRight: Pt(0.75, 0.25),
      bottomRight: Pt(0.75, 0.75),
      bottomLeft: Pt(0.25, 0.75),
    );

    final result =
        await storeCaptureIsolateEntry(params(writePhoto(), quad: quad));

    expect(result['cropped'], isTrue);

    final page = img.decodeImage(File('${dir.path}/page.jpg').readAsBytesSync())!;
    // Half the frame each way: 600x800, already under the 800 cap.
    expect(page.width, closeTo(600, 2));
    expect(page.height, closeTo(800, 2));

    // What survived is the white page, not the black surround.
    final middle = page.getPixel(page.width ~/ 2, page.height ~/ 2);
    expect(middle.r, greaterThan(200));
    final corner = page.getPixel(2, 2);
    expect(corner.r, greaterThan(200));
  });

  test('writes the uncropped original alongside the cropped page', () async {
    const quad = Quad(
      topLeft: Pt(0.25, 0.25),
      topRight: Pt(0.75, 0.25),
      bottomRight: Pt(0.75, 0.75),
      bottomLeft: Pt(0.25, 0.75),
    );

    final result = await storeCaptureIsolateEntry(params(
      writePhoto(),
      quad: quad,
      originalDest: '${dir.path}/orig.jpg',
    ));

    expect(result['original'], isTrue);

    final original =
        img.decodeImage(File('${dir.path}/orig.jpg').readAsBytesSync())!;
    // Uncropped, so still the whole frame's aspect, capped at 1000.
    expect(original.height, 1000);
    // And it really is the uncropped one: its corners are the background.
    expect(original.getPixel(2, 2).r, lessThan(60));
  });

  test('copies the capture through when it cannot be decoded', () async {
    final broken = File('${dir.path}/broken.jpg')
      ..writeAsStringSync('not an image');

    final result = await storeCaptureIsolateEntry(params(broken));

    expect(result['page'], isTrue);
    expect(result['cropped'], isFalse);
    expect(File('${dir.path}/page.jpg').readAsStringSync(), 'not an image');
  });

  test('caps a large crop at the page size', () async {
    const quad = Quad(
      topLeft: Pt(0.0, 0.0),
      topRight: Pt(1.0, 0.0),
      bottomRight: Pt(1.0, 1.0),
      bottomLeft: Pt(0.0, 1.0),
    );

    await storeCaptureIsolateEntry(
        params(writePhoto(width: 3000, height: 4000), quad: quad));

    final page = img.decodeImage(File('${dir.path}/page.jpg').readAsBytesSync())!;
    expect(page.height, 800);
    expect(page.width, 600);
  });
}
