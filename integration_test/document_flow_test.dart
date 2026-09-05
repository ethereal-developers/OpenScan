import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openscan/core/settings/app_settings.dart';

import 'helpers.dart';

/// A document from the inside: its page grid, the page preview, deleting a
/// page, cropping one, and putting a filter on it. Every one of these ends
/// in a file on disk changing, so that is what they assert on rather than
/// on the screen alone.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(prepareApp);
  tearDown(clearLibrary);

  /// Opens the seeded document from the library.
  Future<void> openDocument(WidgetTester tester, String title) async {
    await pumpApp(tester);
    await tapAndSettle(tester, find.text(title));
  }

  testWidgets('every page is in the grid, numbered in order', (tester) async {
    await seedDocument(name: 'Notes', pages: 3);
    await openDocument(tester, 'Notes');

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('3 pages'), findsOneWidget);
  });

  testWidgets('tapping a page opens it in the preview', (tester) async {
    await seedDocument(name: 'Notes', pages: 2);
    await openDocument(tester, 'Notes');

    await tapAndSettle(tester, find.text('1'));

    // The preview's own actions, which the grid doesn't have.
    expect(find.text('Crop'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Re-scan'), findsOneWidget);
  });

  testWidgets('deleting a page removes it from the document and from disk',
      (tester) async {
    final doc = await seedDocument(name: 'Notes', pages: 3);
    await openDocument(tester, 'Notes');

    await tapAndSettle(tester, find.text('1'));
    await tapAndSettle(tester, find.text('Delete'));
    // The dialog's confirm, not the bar button behind it.
    await tapAndSettle(tester, find.text('Delete').last);

    await settleUntil(
      tester,
      () => !File(doc.pagePaths.first).existsSync(),
      reason: 'the deleted page to be removed from disk',
    );

    // The document itself is one page lighter — the preview stays open on
    // what is left, so this is checked on the way back out.
    final images = await database.getImageData(doc.dirName);
    expect(images.length, 2);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('2 pages'), findsOneWidget);
    expect(find.text('3'), findsNothing);
  });

  testWidgets('cropping a page from the preview rewrites that page',
      (tester) async {
    final doc = await seedDocument(name: 'Notes', pages: 1);
    await openDocument(tester, 'Notes');
    final before = File(doc.pagePaths.first).lengthSync();

    await tapAndSettle(tester, find.text('1'));
    await tapAndSettle(tester, find.text('Crop'));

    // The crop screen, once detection has finished and the page is
    // measured, cropped to the whole page and turned a quarter turn.
    await settleUntil(tester, () => _nextIsEnabled(tester),
        reason: 'the crop screen to finish detecting');
    await tapAndSettle(tester, find.text('No crop'));
    await tapAndSettle(tester, find.text('Rotate'));
    await tapAndSettle(tester, find.text('Next'));

    await settleUntil(
      tester,
      () => find.text('Crop').evaluate().isNotEmpty,
      reason: 'the crop to finish and the preview to come back',
      timeout: const Duration(seconds: 60),
    );

    // The page on record is a new file, and it is the turned one.
    final images = await database.getImageData(doc.dirName);
    final page = File(images.first['img_path'] as String);
    expect(page.existsSync(), isTrue);
    expect(page.path, isNot(doc.pagePaths.first));
    expect(page.lengthSync(), isNot(before));
  });

  testWidgets('a filter is applied to the page and kept', (tester) async {
    final doc = await seedDocument(name: 'Notes', pages: 1);
    await openDocument(tester, 'Notes');

    await tapAndSettle(tester, find.text('1'));
    await tapAndSettle(tester, find.text('Filter'));

    // Filter thumbnails are rendered off-isolate; the chips are there
    // either way.
    await tapAndSettle(tester, find.text('Grayscale').last);
    await tapAndSettle(tester, find.text('Done'));

    await settleUntil(
      tester,
      () => find.text('Crop').evaluate().isNotEmpty,
      reason: 'the filter to be applied and the preview to come back',
      timeout: const Duration(seconds: 60),
    );

    final images = await database.getImageData(doc.dirName);
    expect(images.first['filter_name'], 'Grayscale');
    // The unfiltered copy is kept alongside, so the choice can be undone.
    expect(images.first['unfiltered_img_path'], isNotNull);
  });

  testWidgets('an original is kept for a scanned page by default',
      (tester) async {
    // Not a UI flow as such, but the setting the crop flow above depends
    // on: a re-crop is only faithful if the uncropped capture survived.
    expect(AppSettings.instance.keepOriginal, isTrue);
  });
}

bool _nextIsEnabled(WidgetTester tester) =>
    tester.widgetList<TextButton>(find.byType(TextButton))
        .any((b) => b.onPressed != null);
