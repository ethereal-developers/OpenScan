import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/cv/compress.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/models.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Routes every path_provider call [FileOperations] makes — staging,
/// export, cache purge — into one temp directory tree, so
/// [FileOperations.saveToDevice] and [FileOperations.saveForSharing] run
/// end to end without touching the real device filesystem.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final Directory root;

  @override
  Future<String?> getTemporaryPath() async => '${root.path}/tmp';

  @override
  Future<String?> getApplicationDocumentsPath() async => '${root.path}/docs';
}

void main() {
  late Directory root;
  late FileOperations fileOps;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('file_operations_test');
    // path_provider only hands back a path; unlike the real platform
    // directories, nothing creates it on disk.
    Directory('${root.path}/docs').createSync(recursive: true);
    Directory('${root.path}/tmp').createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(root);
    fileOps = FileOperations();
  });

  tearDown(() => root.deleteSync(recursive: true));

  /// A page-sized JPEG, already matching what a stored page looks like.
  ImageOS writePage(String name, {int width = 300, int height = 400}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(80, 140, 200));
    final path = '${root.path}/$name.jpg';
    File(path).writeAsBytesSync(img.encodeJpg(image, quality: 90));
    return ImageOS(imgPath: path);
  }

  test(
      'default quality/maxEdge skip re-compression and use the pages as-is',
      () async {
    final page = writePage('page0');

    final pdfPath = await fileOps.saveToDevice(
      fileName: 'doc',
      images: [page],
      // Explicit, but these are the same as saveToDevice's own defaults —
      // the fast path in _compressedForPdf that avoids redundant work.
      quality: kStoredPageQuality,
      maxEdge: kStoredPageMaxEdge,
    );

    expect(pdfPath, isNotNull);
    expect(File(pdfPath!).existsSync(), isTrue);
    // No staging directory should have been created since nothing needed
    // to be re-encoded.
    expect(Directory('${root.path}/tmp/staging/pdf').existsSync(), isFalse);
  });

  test('a non-default quality/maxEdge re-encodes pages and cleans up staging',
      () async {
    final pages = [writePage('page0'), writePage('page1')];

    final pdfPath = await fileOps.saveToDevice(
      fileName: 'doc',
      images: pages,
      quality: 50,
      maxEdge: 150,
    );

    expect(pdfPath, isNotNull);
    expect(File(pdfPath!).existsSync(), isTrue);

    // The staged per-page copies are cleaned up once the PDF is written —
    // saveToDevice's `finally` block — leaving the source pages untouched.
    final stagingDir = Directory('${root.path}/tmp/staging/pdf');
    if (stagingDir.existsSync()) {
      expect(stagingDir.listSync(), isEmpty);
    }
    for (final page in pages) {
      expect(File(page.imgPath).existsSync(), isTrue);
    }
  });

  test('pages compressed for a PDF are actually re-encoded at the request',
      () async {
    // Deliberately oversized so the maxEdge cap in _compressOneForPdf is
    // the thing under test, not merely "some JPEG got written".
    final page = writePage('big', width: 1200, height: 1600);
    final originalSize = File(page.imgPath).lengthSync();

    // saveForSharing stages into its own directory but goes through the
    // same _compressedForPdf/_compressOneForPdf path as saveToDevice.
    final pdfPath = await fileOps.saveForSharing(
      fileName: 'shared',
      images: [page],
      quality: 30,
      maxEdge: 200,
      imagesSelected: false,
    );

    expect(pdfPath, isNotNull);
    expect(File(pdfPath!).existsSync(), isTrue);
    // A much lower quality and a hard cap on pixel count should produce a
    // meaningfully smaller PDF than the single oversized source page.
    expect(File(pdfPath).lengthSync(), lessThan(originalSize));
  });

  test('an unreadable page among several falls back to the originals',
      () async {
    final good = writePage('good');
    final brokenPath = '${root.path}/broken.jpg';
    File(brokenPath).writeAsBytesSync([1, 2, 3]);
    final broken = ImageOS(imgPath: brokenPath);

    final pdfPath = await fileOps.saveToDevice(
      fileName: 'doc',
      images: [good, broken],
      quality: 50,
      maxEdge: 150,
    );

    // _compressedForPdf falls back to the original images unmodified, and
    // createPdf then fails on the still-unreadable broken page — the
    // point under test is that this doesn't hang, throw uncaught, or leave
    // any staged files behind, not that the PDF gets produced.
    expect(pdfPath, isNull);
    final stagingDir = Directory('${root.path}/tmp/staging/pdf');
    if (stagingDir.existsSync()) {
      expect(stagingDir.listSync(), isEmpty);
    }
  });
}
