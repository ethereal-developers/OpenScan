import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/data/document_naming.dart';

void main() {
  group('defaultDocumentName', () {
    test('is the date followed by the epoch stamp', () {
      final at = DateTime.fromMillisecondsSinceEpoch(1756240151234);
      expect(defaultDocumentName(at),
          'OpenScan-${at.year}-${at.month.toString().padLeft(2, '0')}-'
          '${at.day.toString().padLeft(2, '0')}-1756240151234');
    });

    test('pads single-digit months and days', () {
      final name = defaultDocumentName(DateTime(2026, 1, 5, 9, 30));
      expect(name, startsWith('OpenScan-2026-01-05-'));
    });

    test('carries nothing a filesystem objects to', () {
      final name = defaultDocumentName(DateTime(2026, 8, 26, 22, 29, 11, 375));
      // Colons and spaces are what the old DateTime.toString() scheme
      // put in a folder name, and what FAT and exFAT reject.
      expect(name, matches(RegExp(r'^[A-Za-z0-9-]+$')));
    });

    test('two documents in the same millisecond apart is the only clash', () {
      final first = defaultDocumentName(DateTime(2026, 8, 26, 22, 29, 11, 1));
      final second = defaultDocumentName(DateTime(2026, 8, 26, 22, 29, 11, 2));
      expect(first, isNot(second));
    });
  });

  group('createdFromDocumentName', () {
    test('reads back the moment a generated name was made', () {
      final at = DateTime.fromMillisecondsSinceEpoch(1756240151234);
      expect(createdFromDocumentName(defaultDocumentName(at)), at);
    });

    test('still reads the old OpenScan <DateTime> scheme', () {
      // Exactly what DateTime.toString() produced, which is what folders
      // scanned before the rename are still called on disk.
      expect(createdFromDocumentName('OpenScan 2026-08-26 22:29:11.375905'),
          DateTime(2026, 8, 26, 22, 29, 11, 375, 905));
    });

    test('is null for a name the user chose', () {
      expect(createdFromDocumentName('Invoice'), isNull);
      expect(createdFromDocumentName('OpenScan notes'), isNull);
      expect(createdFromDocumentName('OpenScan-2026-08-26-notanumber'), isNull);
      // A name that merely starts the same way is not a generated one.
      expect(createdFromDocumentName('OpenScan-2026-08-26-123-extra'), isNull);
    });
  });

  group('exportFileName', () {
    final now = DateTime(2026, 8, 26, 22, 29, 11);

    test('files an unnamed document under a fresh generated name', () {
      final documentName = defaultDocumentName(DateTime(2026, 1, 1));
      expect(exportFileName(documentName, now: now), defaultDocumentName(now));
    });

    test('files a legacy-named document under a fresh generated name too', () {
      expect(exportFileName('OpenScan 2026-08-26 22:29:11.375905', now: now),
          defaultDocumentName(now));
    });

    test('keeps the name the user gave', () {
      expect(exportFileName('Invoice', now: now), 'Invoice');
    });

    test('strips what a filesystem would object to, and joins words', () {
      expect(exportFileName('Rent receipt: March/2026', now: now),
          'Rent_receipt_March2026');
    });

    test('falls back when a chosen name survives stripping as nothing', () {
      expect(exportFileName('///', now: now), defaultDocumentName(now));
    });
  });
}
