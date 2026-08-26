import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

/// The library screen: finding a document, opening one, renaming it, and
/// deleting it. Documents are seeded through the app's own data layer, so
/// what the screen reads is what a scan would have written.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(prepareApp);
  tearDown(clearLibrary);

  testWidgets('an empty library says so, and offers a way out', (tester) async {
    await pumpApp(tester);

    expect(find.text('No documents yet'), findsOneWidget);
    expect(find.text('Start scanning'), findsOneWidget);
  });

  testWidgets('seeded documents are listed with their page counts',
      (tester) async {
    await seedDocument(name: 'Invoice', pages: 3);
    await seedDocument(name: 'Receipt', pages: 1);

    await pumpApp(tester);

    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('Receipt'), findsOneWidget);
    expect(find.textContaining('3 pages'), findsOneWidget);
    expect(find.textContaining('1 page'), findsOneWidget);
  });

  testWidgets('search narrows the grid to what was typed', (tester) async {
    await seedDocument(name: 'Invoice', pages: 1);
    await seedDocument(name: 'Receipt', pages: 1);

    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'invo');
    await tester.pumpAndSettle();

    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('Receipt'), findsNothing);

    // A search that matches nothing says which search it was.
    await tester.enterText(find.byType(TextField), 'nothing here');
    await tester.pumpAndSettle();
    expect(find.textContaining('No results for'), findsOneWidget);
  });

  testWidgets('tapping a document opens it, and back returns to the library',
      (tester) async {
    await seedDocument(name: 'Invoice', pages: 2);

    await pumpApp(tester);
    await tapAndSettle(tester, find.text('Invoice'));

    // The document view, showing its pages.
    expect(find.text('Add pages'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);

    await tapAndSettle(tester, find.byIcon(Icons.arrow_back_rounded));
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('a document can be renamed from its long-press menu',
      (tester) async {
    await seedDocument(name: 'Invoice', pages: 1);

    await pumpApp(tester);
    await tester.longPress(find.text('Invoice'));
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.text('Rename'));
    await tester.enterText(find.byType(TextField).last, 'Tax return');
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Save'));

    await settleUntil(tester, () => find.text('Tax return').evaluate().isNotEmpty,
        reason: 'the renamed document to appear');
    expect(find.text('Invoice'), findsNothing);
  });

  testWidgets('a document can be selected and deleted', (tester) async {
    await seedDocument(name: 'Invoice', pages: 1);
    await seedDocument(name: 'Receipt', pages: 1);

    await pumpApp(tester);
    await tester.longPress(find.text('Invoice'));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Select'));

    expect(find.text('1 selected'), findsOneWidget);

    await tapAndSettle(tester, find.text('Delete'));
    // The confirmation dialog, not the bar button behind it.
    await tapAndSettle(tester, find.text('Delete').last);

    await settleUntil(tester, () => find.text('Invoice').evaluate().isEmpty,
        reason: 'the deleted document to disappear');
    expect(find.text('Receipt'), findsOneWidget);
  });

  testWidgets('the overflow sheet reaches Settings and About', (tester) async {
    await pumpApp(tester);

    await tapAndSettle(tester, find.byIcon(Icons.more_vert_rounded));
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    // The scan types that were removed from this sheet stay removed.
    expect(find.textContaining('Quick scan'), findsNothing);
    expect(find.textContaining('Normal scan'), findsNothing);

    await tapAndSettle(tester, find.text('Settings'));
    expect(find.text('Keep original image'), findsOneWidget);
  });
}
