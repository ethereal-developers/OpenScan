import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/models.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Opening a database from the table-per-document era.
///
/// Anyone who used the released build has one, so the fold into
/// `documents` + `pages` has to carry their library across — including the
/// documents scanned before originals and filters were recorded, whose
/// tables are missing those columns entirely.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String path;

  setUp(() async {
    await DatabaseHelper.resetForTesting();
    final documents = await getApplicationDocumentsDirectory();
    path = join(documents.path, 'OpenScan.db');
    if (File(path).existsSync()) File(path).deleteSync();
  });

  tearDown(DatabaseHelper.resetForTesting);

  /// Builds a version 1 database: one master table, one table per
  /// document, named after the document with the punctuation stripped.
  Future<void> writeLegacyDatabase() async {
    final db = await openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE DirectoryDetails(
        dir_name TEXT,
        dir_path TEXT,
        created TEXT,
        image_count INTEGER,
        first_img_path TEXT,
        last_modified TEXT,
        new_name TEXT)
        ''');
    });

    // A recent document: every column the last version wrote.
    await db.insert('DirectoryDetails', {
      'dir_name': 'OpenScan 2024-01-02 03:04:05.000',
      'dir_path': '/documents/OpenScan 2024-01-02 03:04:05.000',
      'created': '2024-01-02 03:04:05.000',
      'image_count': 2,
      'first_img_path': '/documents/one/page1.jpg',
      'last_modified': '2024-01-02 03:04:05.000',
      'new_name': 'Lease',
    });
    await db.execute('''
      CREATE TABLE "OpenScan20240102030405000"(
      idx INTEGER,
      img_path TEXT,
      orig_img_path TEXT,
      unfiltered_img_path TEXT,
      filter_name TEXT)
      ''');
    await db.insert('"OpenScan20240102030405000"', {
      'idx': 1,
      'img_path': '/documents/one/page1.jpg',
      'orig_img_path': '/documents/one/orig1.jpg',
      'unfiltered_img_path': '/documents/one/unfilt1.jpg',
      'filter_name': 'Grayscale',
    });
    await db.insert('"OpenScan20240102030405000"', {
      'idx': 2,
      'img_path': '/documents/one/page2.jpg',
    });

    // An old document, from before originals or filters were recorded: its
    // table has neither column.
    await db.insert('DirectoryDetails', {
      'dir_name': 'OpenScan 2021-05-06 07:08:09.000',
      'dir_path': '/documents/OpenScan 2021-05-06 07:08:09.000',
      'created': '2021-05-06 07:08:09.000',
      'image_count': 1,
      'first_img_path': '/documents/two/page1.jpg',
      'last_modified': '2021-05-06 07:08:09.000',
      'new_name': null,
    });
    await db.execute('''
      CREATE TABLE "OpenScan20210506070809000"(
      idx INTEGER,
      img_path TEXT)
      ''');
    await db.insert('"OpenScan20210506070809000"', {
      'idx': 1,
      'img_path': '/documents/two/page1.jpg',
    });

    await db.close();
  }

  testWidgets('a table-per-document library survives the upgrade',
      (tester) async {
    await writeLegacyDatabase();

    final database = DatabaseHelper();
    final documents = await database.getMasterData();

    expect(documents.length, 2);

    final lease = documents.firstWhere((d) => d['new_name'] == 'Lease');
    // The count and the cover are derived now, and they agree with what
    // the old master table had stored by hand.
    expect(lease['image_count'], 2);
    expect(lease['first_img_path'], '/documents/one/page1.jpg');
    expect(lease['created'], '2024-01-02 03:04:05.000');

    final pages =
        await database.getImageData('OpenScan 2024-01-02 03:04:05.000');
    expect(pages.length, 2);
    expect(pages.first['img_path'], '/documents/one/page1.jpg');
    expect(pages.first['orig_img_path'], '/documents/one/orig1.jpg');
    expect(pages.first['filter_name'], 'Grayscale');
    expect(pages.last['idx'], 2);
    expect(pages.last['orig_img_path'], isNull);
  });

  testWidgets('a document from before originals and filters comes across too',
      (tester) async {
    await writeLegacyDatabase();

    final database = DatabaseHelper();
    final pages =
        await database.getImageData('OpenScan 2021-05-06 07:08:09.000');

    expect(pages.length, 1);
    expect(pages.first['img_path'], '/documents/two/page1.jpg');
    // The columns its table never had read as "nothing recorded".
    expect(pages.first['orig_img_path'], isNull);
    expect(pages.first['unfiltered_img_path'], isNull);
    expect(pages.first['filter_name'], isNull);
  });

  testWidgets('the old tables are gone once they have been folded in',
      (tester) async {
    await writeLegacyDatabase();

    final database = DatabaseHelper();
    await database.getMasterData(); // opens, and so migrates

    final db = await database.database;
    final tables = (await db.query('sqlite_master',
            columns: ['name'], where: 'type = ?', whereArgs: ['table']))
        .map((row) => row['name'] as String)
        .toList();

    expect(tables, contains('documents'));
    expect(tables, contains('pages'));
    expect(tables, isNot(contains('DirectoryDetails')));
    expect(tables, isNot(contains('OpenScan20240102030405000')));
    expect(tables, isNot(contains('OpenScan20210506070809000')));
  });

  testWidgets('deleting a document takes its pages with it', (tester) async {
    await writeLegacyDatabase();

    final database = DatabaseHelper();
    await database
        .deleteDirectory(dirPath: '/documents/OpenScan 2024-01-02 03:04:05.000');

    expect((await database.getMasterData()).length, 1);
    // Cascaded, rather than dropped by a second statement that could be
    // forgotten.
    final db = await database.database;
    final orphans = await db.query('pages',
        where: 'img_path = ?', whereArgs: ['/documents/one/page1.jpg']);
    expect(orphans, isEmpty);
  });

  testWidgets('the page count follows the pages, however they were added',
      (tester) async {
    await writeLegacyDatabase();

    final database = DatabaseHelper();
    const dirName = 'OpenScan 2024-01-02 03:04:05.000';

    // Delete the middle of three pages, then add one. The count used to be
    // written as the new row's id, which keeps climbing past deleted rows —
    // a three-page document listed as four.
    await database.deleteImage(
        imgPath: '/documents/one/page2.jpg', tableName: dirName);
    await database.createImage(
      image: ImageOS(idx: 2, imgPath: '/documents/one/page3.jpg'),
      tableName: dirName,
    );

    final documents = await database.getMasterData();
    final lease = documents.firstWhere((d) => d['new_name'] == 'Lease');
    expect(lease['image_count'], 2);
  });
}
