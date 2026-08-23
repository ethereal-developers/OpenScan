import 'dart:io';

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
}
