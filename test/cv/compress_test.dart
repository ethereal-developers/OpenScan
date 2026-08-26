import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/cv/compress.dart';

void main() {
  test('compresses a JPEG into a new file under dest', () async {
    final tempDir = Directory.systemTemp.createTempSync('compress_test');
    final srcPath = '${tempDir.path}/src.jpg';

    final image = img.Image(width: 200, height: 200);
    img.fill(image, color: img.ColorRgb8(200, 100, 50));
    File(srcPath).writeAsBytesSync(img.encodeJpg(image, quality: 100));

    final outPath = await compressImageIsolateEntry({
      'src': srcPath,
      'dest': tempDir.path,
      'quality': 40,
    });

    expect(File(outPath).existsSync(), isTrue);
    expect(outPath, startsWith(tempDir.path));
    expect(outPath, endsWith('.jpg'));

    final decoded = img.decodeImage(File(outPath).readAsBytesSync());
    expect(decoded, isNotNull);
    expect(decoded!.width, 200);
    expect(decoded.height, 200);

    // Lower quality should produce a smaller file than the quality-100 source.
    expect(File(outPath).lengthSync(), lessThan(File(srcPath).lengthSync()));

    tempDir.deleteSync(recursive: true);
  });

  test('throws for an undecodable source file', () async {
    final tempDir = Directory.systemTemp.createTempSync('compress_test_bad');
    final badPath = '${tempDir.path}/bad.jpg';
    File(badPath).writeAsBytesSync([1, 2, 3]);

    // decodeImage throws its own exception on unparseable bytes before
    // this function's own null check ever runs; either way it must not
    // silently succeed or hang.
    await expectLater(
      compressImageIsolateEntry({
        'src': badPath,
        'dest': tempDir.path,
        'quality': 90,
      }),
      throwsA(anything),
    );

    tempDir.deleteSync(recursive: true);
  });

  test('caps the long edge when a maxEdge is given, and never enlarges',
      () async {
    final tempDir = Directory.systemTemp.createTempSync('compress_maxedge');
    final srcPath = '${tempDir.path}/wide.jpg';

    // Landscape, so the cap has to land on the width.
    final image = img.Image(width: 2400, height: 1600);
    img.fill(image, color: img.ColorRgb8(200, 100, 50));
    File(srcPath).writeAsBytesSync(img.encodeJpg(image, quality: 90));

    final capped = await compressImageIsolateEntry({
      'src': srcPath,
      'dest': tempDir.path,
      'quality': 80,
      'maxEdge': 900,
    });
    final small = img.decodeImage(File(capped).readAsBytesSync())!;
    expect(small.width, 900);
    expect(small.height, 600);

    // A cap the image already fits inside leaves it alone rather than
    // scaling it up to meet the number.
    final untouched = await compressImageIsolateEntry({
      'src': srcPath,
      'dest': tempDir.path,
      'quality': 80,
      'maxEdge': 4000,
    });
    final same = img.decodeImage(File(untouched).readAsBytesSync())!;
    expect(same.width, 2400);
    expect(same.height, 1600);

    tempDir.deleteSync(recursive: true);
  });

  test('measures every preset, and smaller presets weigh less', () async {
    final tempDir = Directory.systemTemp.createTempSync('compress_measure');
    final srcPath = '${tempDir.path}/page.jpg';

    // Noise rather than a flat fill: a solid colour compresses to almost
    // nothing at any setting, which would hide the differences entirely.
    final image = img.Image(width: 2400, height: 1800);
    final random = Random(7);
    for (int y = 0; y < image.height; y += 1) {
      for (int x = 0; x < image.width; x += 1) {
        final v = random.nextInt(256);
        image.setPixelRgb(x, y, v, (v * 3) % 256, (v * 7) % 256);
      }
    }
    File(srcPath).writeAsBytesSync(img.encodeJpg(image, quality: 85));

    final presets = <Map<String, dynamic>>[
      {'quality': 30, 'maxEdge': 900},
      {'quality': 45, 'maxEdge': 1200},
      {'quality': 65, 'maxEdge': 1800},
      {'quality': 85, 'maxEdge': 2400},
    ];
    final sizes = await measureEncodedSizesIsolateEntry({
      'src': srcPath,
      'presets': presets,
      'includePng': true,
    });

    expect(sizes['source'], File(srcPath).lengthSync());
    for (final preset in presets) {
      expect(sizes[encodedSizeKey(preset['quality'] as int,
          preset['maxEdge'] as int?)], isNotNull);
      expect(sizes[pngSizeKey(preset['maxEdge'] as int?)], isNotNull);
    }

    // The whole point of the presets: each step down is actually smaller.
    final jpegs = [
      for (final preset in presets)
        sizes[encodedSizeKey(
            preset['quality'] as int, preset['maxEdge'] as int?)]!,
    ];
    for (int i = 1; i < jpegs.length; i++) {
      expect(jpegs[i], greaterThan(jpegs[i - 1]),
          reason: 'preset ${presets[i]} should weigh more than ${presets[i - 1]}');
    }

    // PNG ignores JPEG quality but not the pixel cap, so it still moves.
    expect(sizes[pngSizeKey(900)]!, lessThan(sizes[pngSizeKey(2400)]!));

    tempDir.deleteSync(recursive: true);
  });
}
