import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
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
}
