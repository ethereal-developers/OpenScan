import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/cv/compress.dart';

img.Image _noise(int width, int height) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(x, y, x % 255, y % 255, (x + y) % 255);
    }
  }
  return image;
}

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('normalize_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('normalizeImageIsolateEntry', () {
    test('caps the long edge, keeping the aspect ratio', () async {
      final src = '${dir.path}/src.jpg';
      final dest = '${dir.path}/dest.jpg';
      File(src).writeAsBytesSync(img.encodeJpg(_noise(1600, 1200)));

      await normalizeImageIsolateEntry(
          {'src': src, 'dest': dest, 'maxEdge': 800, 'quality': 85});

      final out = img.decodeImage(File(dest).readAsBytesSync())!;
      expect(out.width, 800);
      expect(out.height, 600);
    });

    test('caps the long edge of a portrait image on its height', () async {
      final src = '${dir.path}/portrait.jpg';
      final dest = '${dir.path}/portrait_out.jpg';
      File(src).writeAsBytesSync(img.encodeJpg(_noise(600, 900)));

      await normalizeImageIsolateEntry(
          {'src': src, 'dest': dest, 'maxEdge': 300, 'quality': 85});

      final out = img.decodeImage(File(dest).readAsBytesSync())!;
      expect(out.height, 300);
      expect(out.width, 200);
    });

    test('leaves an already-small image at its own size, and shrinks the '
        'file rather than growing it', () async {
      final src = '${dir.path}/small.jpg';
      final dest = '${dir.path}/small_out.jpg';
      // Quality 100 in, the stored quality out: the point of normalizing.
      File(src).writeAsBytesSync(img.encodeJpg(_noise(400, 300), quality: 100));

      await normalizeImageIsolateEntry({
        'src': src,
        'dest': dest,
        'maxEdge': kStoredPageMaxEdge,
        'quality': kStoredPageQuality,
      });

      final out = img.decodeImage(File(dest).readAsBytesSync())!;
      expect(out.width, 400);
      expect(out.height, 300);
      expect(File(dest).lengthSync(), lessThan(File(src).lengthSync()));
    });

    // FileOperations._copyNormalized falls back to a plain copy on any
    // failure here, so what matters is that undecodable input fails loudly
    // rather than writing an empty file over a page.
    test('fails on a file that is not an image', () async {
      final src = '${dir.path}/notanimage.jpg';
      File(src).writeAsStringSync('nope');
      await expectLater(
        normalizeImageIsolateEntry({
          'src': src,
          'dest': '${dir.path}/out.jpg',
          'maxEdge': 800,
          'quality': 85,
        }),
        throwsA(anything),
      );
      expect(File('${dir.path}/out.jpg').existsSync(), isFalse);
    });
  });

}
