import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openscan/core/data/database_helper.dart';

import 'helpers.dart';

/// The storage side of OCR: where recognized text lives, how it is found
/// again, and — the part that matters most — how it stops being trusted
/// once the page it describes has changed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final DatabaseHelper db = DatabaseHelper();

  setUp(clearLibrary);
  tearDown(clearLibrary);

  Future<int> store(
    String dirName,
    String imgPath, {
    required String text,
    String words = '[]',
  }) =>
      db.savePageText(
        tableName: dirName,
        imgPath: imgPath,
        text: text,
        words: words,
        language: 'eng',
      );

  group('storing and reading back', () {
    testWidgets('a page keeps its text, words and language', (_) async {
      final doc = await seedDocument(pages: 2);
      await store(doc.dirName, doc.pagePaths.first,
          text: 'Invoice 42', words: '[{"t":"Invoice"}]');

      final row = await db.getPageText(
          tableName: doc.dirName, imgPath: doc.pagePaths.first);

      expect(row, isNotNull);
      expect(row!['text'], 'Invoice 42');
      expect(row['words'], '[{"t":"Invoice"}]');
      expect(row['language'], 'eng');
      expect(row['source_img_path'], doc.pagePaths.first);
    });

    testWidgets('a page nobody has read has no row', (_) async {
      final doc = await seedDocument(pages: 2);
      expect(
        await db.getPageText(
            tableName: doc.dirName, imgPath: doc.pagePaths.last),
        isNull,
      );
    });

    testWidgets('reading the same page again replaces the text rather than '
        'adding a second row', (_) async {
      final doc = await seedDocument(pages: 1);
      await store(doc.dirName, doc.pagePaths.first, text: 'first pass');
      await store(doc.dirName, doc.pagePaths.first, text: 'second pass');

      final row = await db.getPageText(
          tableName: doc.dirName, imgPath: doc.pagePaths.first);
      expect(row!['text'], 'second pass');
      expect(await db.recognizedPageCount(doc.dirName), 1);
    });

    testWidgets('text for a path that is not a page of this document is '
        'not written', (_) async {
      final doc = await seedDocument(pages: 1);
      final written = await store(doc.dirName, '/nowhere/ghost.jpg',
          text: 'text about nothing');
      expect(written, 0);
      expect(await db.recognizedPageCount(doc.dirName), 0);
    });
  });

  group('a whole document at once', () {
    testWidgets('comes back keyed by the image each row was read from',
        (_) async {
      final doc = await seedDocument(pages: 3);
      await store(doc.dirName, doc.pagePaths[0], text: 'page one');
      await store(doc.dirName, doc.pagePaths[2], text: 'page three');

      final rows = await db.getDocumentText(doc.dirName);

      expect(rows.keys, hasLength(2));
      expect(rows[doc.pagePaths[0]]!['text'], 'page one');
      expect(rows[doc.pagePaths[2]]!['text'], 'page three');
      expect(rows.containsKey(doc.pagePaths[1]), isFalse);
    });
  });

  group('text stops counting once the page changes under it', () {
    testWidgets('a re-cropped page no longer counts as recognized', (_) async {
      final doc = await seedDocument(pages: 2);
      await store(doc.dirName, doc.pagePaths.first, text: 'read before crop');
      expect(await db.recognizedPageCount(doc.dirName), 1);

      // What a re-crop does: the page row is pointed at a new file, while
      // the text row still describes the old one.
      await db.updateImagePath(
        tableName: doc.dirName,
        imgPath: '${doc.pagePaths.first}.recropped.jpg',
        idx: 1,
      );

      expect(await db.recognizedPageCount(doc.dirName), 0);
    });

    testWidgets('the stale row is not served for the page\'s new image',
        (_) async {
      final doc = await seedDocument(pages: 1);
      await store(doc.dirName, doc.pagePaths.first, text: 'read before crop');
      final newPath = '${doc.pagePaths.first}.recropped.jpg';
      await db.updateImagePath(
          tableName: doc.dirName, imgPath: newPath, idx: 1);

      expect(
        await db.getPageText(tableName: doc.dirName, imgPath: newPath),
        isNull,
      );
    });
  });

  group('searching recognized text', () {
    testWidgets('finds the document a phrase was read from', (_) async {
      final wanted = await seedDocument(pages: 1);
      final other = await seedDocument(pages: 1);
      await store(wanted.dirName, wanted.pagePaths.first,
          text: 'Quarterly tax return 2026');
      await store(other.dirName, other.pagePaths.first,
          text: 'Grocery receipt');

      expect(await db.searchDocumentText('tax'), {wanted.dirName});
      expect(await db.searchDocumentText('receipt'), {other.dirName});
    });

    testWidgets('ignores case', (_) async {
      final doc = await seedDocument(pages: 1);
      await store(doc.dirName, doc.pagePaths.first, text: 'Quarterly TAX');
      expect(await db.searchDocumentText('tax'), contains(doc.dirName));
      expect(await db.searchDocumentText('QUARTERLY'), contains(doc.dirName));
    });

    testWidgets('names a document once however many of its pages match',
        (_) async {
      final doc = await seedDocument(pages: 3);
      for (final path in doc.pagePaths) {
        await store(doc.dirName, path, text: 'invoice');
      }
      expect(await db.searchDocumentText('invoice'), {doc.dirName});
    });

    testWidgets('treats LIKE wildcards as characters the user typed',
        (_) async {
      // Without escaping, "%" matches every document that has any text at
      // all -- a search for a literal percent sign would return the whole
      // library.
      final doc = await seedDocument(pages: 1);
      final other = await seedDocument(pages: 1);
      await store(doc.dirName, doc.pagePaths.first, text: 'VAT 20% applied');
      await store(other.dirName, other.pagePaths.first, text: 'no rate here');

      expect(await db.searchDocumentText('20%'), {doc.dirName});
      expect(await db.searchDocumentText('%'), {doc.dirName});
      expect(await db.searchDocumentText('_'), isEmpty);
    });

    testWidgets('an empty query matches nothing rather than everything',
        (_) async {
      final doc = await seedDocument(pages: 1);
      await store(doc.dirName, doc.pagePaths.first, text: 'anything');
      expect(await db.searchDocumentText(''), isEmpty);
      expect(await db.searchDocumentText('   '), isEmpty);
    });
  });

  group('deleting', () {
    testWidgets('a deleted document takes its recognized text with it',
        (_) async {
      final doc = await seedDocument(pages: 2);
      for (final path in doc.pagePaths) {
        await store(doc.dirName, path, text: 'confidential');
      }

      await db.deleteDirectory(dirPath: doc.dirPath);

      // The cascade is the only thing standing between "deleted document"
      // and text from it still turning up in a search.
      expect(await db.searchDocumentText('confidential'), isEmpty);
    });

    testWidgets('a deleted page takes its text with it', (_) async {
      final doc = await seedDocument(pages: 2);
      await store(doc.dirName, doc.pagePaths.first, text: 'first page text');
      await store(doc.dirName, doc.pagePaths.last, text: 'second page text');

      await db.deleteImage(
          tableName: doc.dirName, imgPath: doc.pagePaths.first);

      expect(await db.recognizedPageCount(doc.dirName), 1);
      expect(await db.searchDocumentText('first page text'), isEmpty);
      expect(await db.searchDocumentText('second page text'),
          contains(doc.dirName));
    });
  });
}
