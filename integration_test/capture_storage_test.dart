import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:openscan/core/cv/capture_pipeline.dart';
import 'package:openscan/core/cv/compress.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/core/data/document_naming.dart';
import 'package:path_provider/path_provider.dart';

import 'helpers.dart';

/// What storing a capture does with bytes that aren't an image.
///
/// A page nothing can decode used to be written anyway — the pipeline
/// copies a capture it can't decode through untouched, which is right for
/// a HEIC the platform decoder handles and wrong for a truncated gallery
/// pick. These run on a device because the check that separates the two is
/// the platform's own decoder.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(prepareApp);
  tearDown(clearLibrary);

  /// A document directory no test has written to yet.
  Future<String> emptyDocumentPath() async {
    final root = (await getExternalStorageDirectory())!;
    return '${root.path}/${defaultDocumentName(DateTime.now())}';
  }

  /// A file of [bytes] in the cache, named like a capture.
  Future<File> cacheFile(String name, List<int> bytes) async {
    final cache = await getTemporaryDirectory();
    return File('${cache.path}/$name')..writeAsBytesSync(bytes);
  }

  testWidgets('a capture that is not an image is stored as no page at all',
      (tester) async {
    final dirPath = await emptyDocumentPath();
    // A JPEG that starts like one and then isn't: exactly what a truncated
    // or partly-synced gallery pick looks like.
    final random = Random(7);
    final source = await cacheFile(
      'broken_${DateTime.now().microsecondsSinceEpoch}.jpg',
      [0xff, 0xd8, 0xff, 0xe0, ...List.generate(64 * 1024, (_) => random.nextInt(256))],
    );

    final saved = await fileOperations.saveCapture(
      source: source,
      dirPath: dirPath,
      index: 1,
    );

    expect(saved, isNull);
    // No half-written page, no orphaned original, no row pointing at either.
    final dir = Directory(dirPath);
    expect(dir.existsSync() ? dir.listSync() : const [], isEmpty);
    expect(await database.getImageData(dirPath.split('/').last),
        isEmpty);

    source.deleteSync();
  });

  testWidgets('a readable capture still becomes a page', (tester) async {
    final dirPath = await emptyDocumentPath();
    final source = await cacheFile(
      'good_${DateTime.now().microsecondsSinceEpoch}.jpg',
      img.encodeJpg(img.Image(width: 800, height: 1000), quality: 90),
    );

    final saved = await fileOperations.saveCapture(
      source: source,
      dirPath: dirPath,
      index: 1,
    );

    expect(saved, isNotNull);
    expect(File(saved!.imgPath).existsSync(), isTrue);
    expect(await database.getImageData(dirPath.split('/').last),
        hasLength(1));

    source.deleteSync();
  });

  testWidgets('the platform decoder stores the same page the Dart one would',
      (tester) async {
    // Storing a capture goes through the platform's image decoder, falling
    // back to the pure-Dart pipeline only when that cannot read the bytes.
    // The two have to agree about what a page is, so this stores the same
    // capture both ways and compares.
    final cache = await getTemporaryDirectory();
    final photo = img.Image(width: 1600, height: 1200);
    final random = Random(11);
    for (int y = 0; y < photo.height; y++) {
      for (int x = 0; x < photo.width; x++) {
        photo.setPixelRgb(x, y, x * 255 ~/ photo.width,
            y * 255 ~/ photo.height, random.nextInt(256));
      }
    }
    final source = await cacheFile(
        'parity_${DateTime.now().microsecondsSinceEpoch}.jpg',
        img.encodeJpg(photo, quality: 90));

    // A boundary that is not the whole frame, so the warp runs too.
    const quad = Quad(
      topLeft: Pt(0.08, 0.06),
      topRight: Pt(0.94, 0.05),
      bottomRight: Pt(0.96, 0.95),
      bottomLeft: Pt(0.05, 0.93),
    );

    for (final withQuad in [false, true]) {
      final reason = 'quad=$withQuad';

      final viaDart = '${cache.path}/dart_$withQuad.jpg';
      await compute(storeCaptureIsolateEntry, {
        'src': source.path,
        'pageDest': viaDart,
        'pageMaxEdge': kStoredPageMaxEdge,
        'pageQuality': kStoredPageQuality,
        'quad': withQuad ? quad : null,
        'originalDest': null,
        'originalMaxEdge': kStoredOriginalMaxEdge,
        'originalQuality': kStoredOriginalQuality,
      });

      final stored = await fileOperations.writeCapture(
        source: source,
        dir: cache.path,
        stamp: 'native_$withQuad',
        quad: withQuad ? quad : null,
        keepOriginal: true,
      );

      expect(stored, isNotNull, reason: reason);
      final native = img.decodeImage(File(stored!.pagePath).readAsBytesSync())!;
      final dart = img.decodeImage(File(viaDart).readAsBytesSync())!;
      // Rounding differs by at most a pixel between scaling the decode and
      // scaling the warp, but the page is the same page.
      expect((native.width - dart.width).abs(), lessThanOrEqualTo(2),
          reason: reason);
      expect((native.height - dart.height).abs(), lessThanOrEqualTo(2),
          reason: reason);

      // The kept original is the uncropped capture at its own larger cap.
      expect(stored.originalPath, isNotNull, reason: reason);
      final original =
          img.decodeImage(File(stored.originalPath!).readAsBytesSync())!;
      expect(original.width, photo.width, reason: reason);
      expect(original.height, photo.height, reason: reason);

      File(viaDart).deleteSync();
      File(stored.pagePath).deleteSync();
      File(stored.originalPath!).deleteSync();
    }

    source.deleteSync();
  });

  testWidgets('a transparent gallery pick is flattened onto white',
      (tester) async {
    // A page is an opaque JPEG, so transparency has to land on something.
    // White is the answer a scanner wants: a logo on paper, not a logo in a
    // black box, which is what dropping a premultiplied alpha channel gives.
    final cache = await getTemporaryDirectory();
    final png = img.Image(width: 64, height: 64, numChannels: 4);
    for (int y = 0; y < 64; y++) {
      for (int x = 0; x < 64; x++) {
        png.setPixelRgba(x, y, 255, 0, 0, x < 32 ? 0 : 128);
      }
    }
    final source = await cacheFile(
        'alpha_${DateTime.now().microsecondsSinceEpoch}.png',
        img.encodePng(png));

    final stored = await fileOperations.writeCapture(
        source: source, dir: cache.path, stamp: 'alpha_page');
    expect(stored, isNotNull);
    final page = img.decodeImage(File(stored!.pagePath).readAsBytesSync())!;

    final clear = page.getPixel(10, 32);
    expect(clear.r, greaterThan(240));
    expect(clear.g, greaterThan(240));
    expect(clear.b, greaterThan(240));

    // Half-transparent red over white: still red, lifted towards white.
    final half = page.getPixel(54, 32);
    expect(half.r, greaterThan(200));
    expect(half.g, greaterThan(100));
    expect(half.g, lessThan(200));

    File(stored.pagePath).deleteSync();
    source.deleteSync();
  });
}
