import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/data/document_naming.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/settings/app_settings.dart';
import 'package:openscan/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared scaffolding for the on-device flow tests: putting the app into a
/// known state, seeding documents through the app's own data layer (so
/// what the tests read is what the app would have written), and waiting
/// for work that finishes off-frame.

final DatabaseHelper database = DatabaseHelper();
final FileOperations fileOperations = FileOperations();

/// Everything the app needs before its first frame, plus the two bits of
/// stored state that would otherwise derail a test run: the tutorial, which
/// takes over the screen on first launch, and any documents left behind by
/// an earlier test.
Future<void> prepareApp() async {
  await AppSettings.instance.load();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('alreadyVisited', true);
  await clearLibrary();
}

/// Removes every document the app knows about, from disk and from the
/// database. Tests share one installed app, so each starts from empty
/// rather than from whatever the last one left.
Future<void> clearLibrary() async {
  final rows = await database.getMasterData();
  for (final row in rows) {
    final path = row['dir_path'] as String;
    final dir = Directory(path);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    await database.deleteDirectory(dirPath: path);
  }
}

/// A document with [pages] pages, written the way a scan writes one, so
/// its files, database rows and page indices are the real thing.
///
/// Each page carries a band of its own colour across the top, so a test
/// can tell them apart after a reorder or a delete.
Future<SeededDocument> seedDocument({
  String? name,
  int pages = 3,
  DateTime? created,
}) async {
  final root = (await getExternalStorageDirectory())!;
  final when = created ?? DateTime.now();
  final dirName = defaultDocumentName(when);
  final dirPath = '${root.path}/$dirName';

  final cache = await getTemporaryDirectory();
  final paths = <String>[];
  for (int i = 0; i < pages; i++) {
    final source = File('${cache.path}/seed_${when.microsecondsSinceEpoch}_$i.jpg')
      ..writeAsBytesSync(img.encodeJpg(pageImage(i), quality: 90));
    final saved = await fileOperations.saveCapture(
      source: source,
      dirPath: dirPath,
      index: i + 1,
    );
    // The seed images are freshly encoded JPEGs, so a null here means the
    // storage path itself broke — fail the test loudly rather than seeding
    // a document with holes in it.
    if (saved == null) {
      throw StateError('Could not store seed page ${i + 1} in $dirPath');
    }
    paths.add(saved.imgPath);
    if (source.existsSync()) source.deleteSync();
  }

  if (name != null) {
    await database.renameDirectory(tableName: dirName, newName: name);
  }

  return SeededDocument(
    dirName: dirName,
    dirPath: dirPath,
    title: name ?? dirName,
    pagePaths: paths,
  );
}

/// A page image with a colour band across the top identifying it.
img.Image pageImage(int index) {
  final image = img.Image(width: 600, height: 800);
  img.fill(image, color: img.ColorRgb8(245, 245, 240));
  img.fillRect(image,
      x1: 0,
      y1: 0,
      x2: 599,
      y2: 99,
      color: pageBands[index % pageBands.length]);
  return image;
}

/// Distinct, far-apart colours so a band can be identified from one pixel.
final List<img.ColorRgb8> pageBands = [
  img.ColorRgb8(220, 30, 30),
  img.ColorRgb8(30, 130, 220),
  img.ColorRgb8(40, 170, 60),
  img.ColorRgb8(230, 190, 30),
];

/// Which seeded page [file] is, by the colour of its top band, or -1 if it
/// matches none of them.
int pageIndexOf(File file) {
  final image = img.decodeImage(file.readAsBytesSync());
  if (image == null) return -1;
  final pixel = image.getPixel(image.width ~/ 2, image.height ~/ 20);
  for (int i = 0; i < pageBands.length; i++) {
    final band = pageBands[i];
    if ((pixel.r - band.r).abs() < 60 &&
        (pixel.g - band.g).abs() < 60 &&
        (pixel.b - band.b).abs() < 60) {
      return i;
    }
  }
  return -1;
}

class SeededDocument {
  final String dirName;
  final String dirPath;
  final String title;
  final List<String> pagePaths;

  const SeededDocument({
    required this.dirName,
    required this.dirPath,
    required this.title,
    required this.pagePaths,
  });
}

/// Starts the real app — the same widget `main()` runs — and waits for the
/// library to load.
Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const OpenScan());
  await tester.pumpAndSettle();
}

/// Pumps frames until [done] or the deadline passes.
///
/// `pumpAndSettle` can't do this on its own: what these tests wait for is
/// an isolate or a database call finishing, and the screen sits idle in
/// between, so settling returns immediately and the test races ahead.
Future<void> settleUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 30),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out after $timeout waiting for ${reason ?? 'the app'}');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

/// Taps whatever is found, then settles — the shape almost every step in
/// these tests takes.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
