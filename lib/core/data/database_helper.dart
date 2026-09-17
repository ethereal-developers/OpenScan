import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:openscan/core/models.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Two tables: one row per document, one row per page, joined by a foreign
/// key.
///
/// Earlier versions gave every document a table of its own, created on
/// scan and dropped on delete. That made every schema change a per-table
/// migration run lazily on each read, forced table names to be built by
/// string surgery (identifiers can't be bound as parameters), left the
/// "which table am I working on" answer in a mutable field on this object,
/// and kept the page count in a column that had to be written by hand.
/// [_migrateFromTablePerDocument] folds those tables into `pages` the
/// first time a database from that era is opened.
class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  DatabaseHelper();

  static final instance = DatabaseHelper._privateConstructor();
  static const _dbName = "OpenScan.db";
  static const _dbVersion = 3;

  static const _documentsTable = 'documents';
  static const _pagesTable = 'pages';
  static const _pageTextTable = 'page_text';

  /// The table-per-document era's master table, read once by the migration
  /// and dropped after.
  static const _legacyMasterTable = 'DirectoryDetails';

  /// Opened once and shared. Every call used to run `openDatabase` again,
  /// which hands back a fresh handle to the same file on every query.
  static Future<Database>? _opening;
  static String? _path;

  /// Path of the database file, once it has been opened.
  String? get path => _path;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    _path = join(documentsDirectory.path, _dbName);
    return openDatabase(
      _path!,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) => _createSchema(db);

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $_documentsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dir_name TEXT NOT NULL UNIQUE,
        dir_path TEXT NOT NULL UNIQUE,
        created TEXT,
        last_modified TEXT,
        new_name TEXT)
      ''');
    await db.execute('''
      CREATE TABLE $_pagesTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL
          REFERENCES $_documentsTable(id) ON DELETE CASCADE,
        idx INTEGER NOT NULL,
        img_path TEXT NOT NULL,
        orig_img_path TEXT,
        unfiltered_img_path TEXT,
        filter_name TEXT)
      ''');
    // Every page read is "this document's pages, in order".
    await db.execute(
        'CREATE INDEX pages_by_document ON $_pagesTable(document_id, idx)');
    await _createPageTextTable(db);
  }

  /// Recognized text, one row per page that has been through OCR.
  ///
  /// A table of its own rather than columns on `pages`: most pages never
  /// get recognized, the text and its word boxes are far larger than the
  /// rest of a page row put together, and every existing page read would
  /// otherwise start dragging them along. The cascade means deleting a
  /// page or a document takes its text with it.
  ///
  /// `source_img_path` is what the text was actually read from. A page is
  /// re-cropped and re-filtered in place, so the image behind it changes;
  /// comparing that column against the page's current image is how a read
  /// tells live text from text describing a picture that is gone.
  ///
  /// `IF NOT EXISTS` because two upgrade steps can reach it on the same
  /// open: a database still on version 1 runs the table-per-document
  /// migration, which rebuilds the whole schema including this table, and
  /// then falls through to the version 3 step below.
  Future<void> _createPageTextTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_pageTextTable(
        page_id INTEGER PRIMARY KEY
          REFERENCES $_pagesTable(id) ON DELETE CASCADE,
        source_img_path TEXT NOT NULL,
        text TEXT NOT NULL,
        words TEXT,
        language TEXT,
        updated_at TEXT)
      ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _migrateFromTablePerDocument(db);
    // Nothing to backfill: no page has been recognized yet, and OCR runs
    // on demand, so an empty table is the correct starting state.
    if (oldVersion < 3) await _createPageTextTable(db);
  }

  // <========================= Migration =========================>

  /// Folds a table-per-document database into `documents` + `pages`.
  ///
  /// Runs once, inside sqflite's upgrade transaction. Each document is
  /// migrated independently and a failure on one is logged rather than
  /// thrown: a table that can't be read costs that document's page
  /// records, where letting the exception out would cost the whole
  /// library.
  Future<void> _migrateFromTablePerDocument(Database db) async {
    await _createSchema(db);

    final legacy = await db.query(_legacyMasterTable);
    for (final row in legacy) {
      final dirName = row['dir_name'] as String?;
      final dirPath = row['dir_path'] as String?;
      if (dirName == null || dirPath == null) continue;

      try {
        final documentId = await db.insert(_documentsTable, {
          'dir_name': dirName,
          'dir_path': dirPath,
          'created': row['created'],
          'last_modified': row['last_modified'],
          'new_name': row['new_name'],
        });
        await _migrateLegacyPages(db, dirName, documentId);
      } catch (e) {
        debugPrint('Could not migrate document $dirName: $e');
      }
    }

    await db.execute('DROP TABLE IF EXISTS $_legacyMasterTable');
  }

  Future<void> _migrateLegacyPages(
      Database db, String dirName, int documentId) async {
    final table = _legacyTableName(dirName);
    final exists = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', _unquoted(table)],
    );
    if (exists.isEmpty) return;

    // Those tables were grown column by column across releases, so which
    // ones a given document has depends on when it was scanned.
    final columns = <String>{
      for (final column in await db.rawQuery('PRAGMA table_info($table)'))
        column['name'] as String,
    };

    final rows = await db.query(table, orderBy: 'idx');
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final imgPath = row['img_path'] as String?;
      if (imgPath == null) continue;
      await db.insert(_pagesTable, {
        'document_id': documentId,
        'idx': row['idx'] ?? i + 1,
        'img_path': imgPath,
        'orig_img_path':
            columns.contains('orig_img_path') ? row['orig_img_path'] : null,
        'unfiltered_img_path': columns.contains('unfiltered_img_path')
            ? row['unfiltered_img_path']
            : null,
        'filter_name':
            columns.contains('filter_name') ? row['filter_name'] : null,
      });
    }

    await db.execute('DROP TABLE $table');
  }

  /// The table name a document's pages lived in before this schema: its
  /// directory name with the characters SQLite would choke on removed,
  /// quoted because it still starts with a digit-heavy timestamp.
  static String _legacyTableName(String dirName) {
    final stripped = dirName
        .replaceAll('-', '')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .replaceAll(':', '');
    return '"$stripped"';
  }

  static String _unquoted(String table) => table.replaceAll('"', '');

  // <===================== Document operations =====================>

  /// Every document, with its page count and cover derived from the pages
  /// themselves rather than stored alongside them — a count in a column is
  /// a count that can be wrong.
  Future<List<Map<String, dynamic>>> getMasterData() async {
    Database db = await database;
    return db.rawQuery('''
      SELECT d.dir_name, d.dir_path, d.created, d.last_modified, d.new_name,
        (SELECT COUNT(*) FROM $_pagesTable p WHERE p.document_id = d.id)
          AS image_count,
        (SELECT p.img_path FROM $_pagesTable p WHERE p.document_id = d.id
           ORDER BY p.idx LIMIT 1) AS first_img_path
      FROM $_documentsTable d
      ''');
  }

  /// Creates the document's row. Its pages are rows in [_pagesTable], so
  /// there is nothing else to create.
  Future<int> createDirectory({required DirectoryOS directory}) async {
    Database db = await database;
    return db.insert(
      _documentsTable,
      {
        'dir_name': directory.dirName,
        'dir_path': directory.dirPath,
        'created': directory.created.toString(),
        'last_modified': directory.lastModified.toString(),
        'new_name': directory.newName,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Renames a document. The name shown is [DirectoryOS.newName]; the
  /// directory on disk, and the row's identity, are untouched.
  Future<int> renameDirectory({
    required String tableName,
    required String newName,
  }) async {
    Database db = await database;
    return db.update(_documentsTable, {'new_name': newName},
        where: 'dir_name = ?', whereArgs: [tableName]);
  }

  /// Deletes a document and, by the foreign key's cascade, its pages.
  Future<int> deleteDirectory({required String dirPath}) async {
    Database db = await database;
    return db
        .delete(_documentsTable, where: 'dir_path = ?', whereArgs: [dirPath]);
  }

  // <======================= Page operations =======================>

  /// A document's pages, in order.
  Future<List<Map<String, dynamic>>> getImageData(String tableName) async {
    Database db = await database;
    return db.rawQuery('''
      SELECT p.idx, p.img_path, p.orig_img_path, p.unfiltered_img_path,
             p.filter_name
      FROM $_pagesTable p
      JOIN $_documentsTable d ON d.id = p.document_id
      WHERE d.dir_name = ?
      ORDER BY p.idx
      ''', [tableName]);
  }

  /// Adds a page to a document, and marks the document as touched.
  Future<int> createImage({
    required ImageOS image,
    required String tableName,
  }) async {
    Database db = await database;
    final documentId = await _documentId(db, tableName);
    if (documentId == null) return 0;

    final id = await db.insert(_pagesTable, {
      'document_id': documentId,
      'idx': image.idx,
      'img_path': image.imgPath,
      'orig_img_path': image.origPath,
      'unfiltered_img_path': image.unfilteredPath,
      'filter_name': image.filterName,
    });

    await db.update(
      _documentsTable,
      {'last_modified': DateTime.now().toString()},
      where: 'id = ?',
      whereArgs: [documentId],
    );
    return id;
  }

  /// Updates the files a page is made of.
  ///
  /// Pass [origPath] to also record the uncropped original the image was
  /// derived from; omitting it leaves whatever original is already stored
  /// untouched, so a re-crop can keep pointing at the same original.
  ///
  /// Returns: Records updated [int]
  Future<int> updateImagePath({
    required String tableName,
    String? imgPath,
    String? origPath,
    String? unfilteredPath,
    String? filterName,
    bool clearFilter = false,
    bool clearOriginal = false,
    int? idx,
  }) async {
    Database db = await database;
    final documentId = await _documentId(db, tableName);
    if (documentId == null) return 0;

    return db.update(
      _pagesTable,
      {
        if (imgPath != null) 'img_path': imgPath,
        // clearOriginal distinguishes "no original for this page" from
        // "leave whatever original is on record alone" — without it a
        // page whose original is gone keeps pointing at a deleted file.
        if (origPath != null || clearOriginal) 'orig_img_path': origPath,
        if (clearFilter || unfilteredPath != null)
          'unfiltered_img_path': unfilteredPath,
        if (clearFilter || filterName != null) 'filter_name': filterName,
      },
      where: 'document_id = ? AND idx = ?',
      whereArgs: [documentId, idx],
    );
  }

  /// Moves a page to a new position in its document.
  ///
  /// Returns: Records updated [int]
  Future<int> updateImageIndex({
    String? imgPath,
    int? newIndex,
    required String tableName,
  }) async {
    Database db = await database;
    final documentId = await _documentId(db, tableName);
    if (documentId == null) return 0;

    return db.update(
      _pagesTable,
      {'idx': newIndex},
      where: 'document_id = ? AND img_path = ?',
      whereArgs: [documentId, imgPath],
    );
  }

  /// Removes a page from its document.
  Future<int> deleteImage({
    String? imgPath,
    required String tableName,
  }) async {
    Database db = await database;
    final documentId = await _documentId(db, tableName);
    if (documentId == null) return 0;

    return db.delete(
      _pagesTable,
      where: 'document_id = ? AND img_path = ?',
      whereArgs: [documentId, imgPath],
    );
  }

  // <===================== Recognized text =====================>

  /// Stores (or replaces) the text recognized for one page.
  ///
  /// Keyed off the page's current image path, so a page that has since been
  /// re-cropped is simply not found and nothing is written — the alternative
  /// would be filing text under a page whose picture has moved on.
  Future<int> savePageText({
    required String tableName,
    required String imgPath,
    required String text,
    required String words,
    required String language,
  }) async {
    Database db = await database;
    final pageId = await _pageId(db, tableName, imgPath);
    if (pageId == null) return 0;

    await db.insert(
      _pageTextTable,
      {
        'page_id': pageId,
        'source_img_path': imgPath,
        'text': text,
        'words': words,
        'language': language,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return pageId;
  }

  /// The stored text for one page, or null if it has never been recognized.
  ///
  /// `source_img_path` comes back with it rather than being filtered on
  /// here: the caller decides what to do about text that describes an older
  /// version of the page, and "stale" is a different answer from "none".
  Future<Map<String, dynamic>?> getPageText({
    required String tableName,
    required String imgPath,
  }) async {
    Database db = await database;
    final rows = await db.rawQuery('''
      SELECT t.source_img_path, t.text, t.words, t.language, t.updated_at
      FROM $_pageTextTable t
      JOIN $_pagesTable p ON p.id = t.page_id
      JOIN $_documentsTable d ON d.id = p.document_id
      WHERE d.dir_name = ? AND p.img_path = ?
      LIMIT 1
      ''', [tableName, imgPath]);
    return rows.isEmpty ? null : rows.first;
  }

  /// Every stored page text for a document, keyed by the image path it was
  /// read from, in page order.
  ///
  /// One query rather than one per page: the export path needs the whole
  /// document's text at once to build a searchable PDF, and a forty-page
  /// document should not cost forty round trips.
  Future<Map<String, Map<String, dynamic>>> getDocumentText(
      String tableName) async {
    Database db = await database;
    final rows = await db.rawQuery('''
      SELECT t.source_img_path, t.text, t.words, t.language
      FROM $_pageTextTable t
      JOIN $_pagesTable p ON p.id = t.page_id
      JOIN $_documentsTable d ON d.id = p.document_id
      WHERE d.dir_name = ?
      ORDER BY p.idx
      ''', [tableName]);
    return {
      for (final row in rows) row['source_img_path'] as String: row,
    };
  }

  /// How many of a document's pages have text on record that still matches
  /// the image the page currently points at.
  ///
  /// The join on `img_path = source_img_path` is what makes it "still
  /// matches": a re-cropped page keeps its stale row but stops counting,
  /// which is exactly what a "12 of 20 pages recognized" line should say.
  Future<int> recognizedPageCount(String tableName) async {
    Database db = await database;
    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS n
      FROM $_pageTextTable t
      JOIN $_pagesTable p
        ON p.id = t.page_id AND p.img_path = t.source_img_path
      JOIN $_documentsTable d ON d.id = p.document_id
      WHERE d.dir_name = ?
      ''', [tableName]);
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Directory names of documents whose recognized text contains [query].
  ///
  /// Matching is left to SQLite's LIKE, which is ASCII-case-insensitive
  /// only. Good enough for the English model shipped today, and the
  /// alternative — pulling every page's text into Dart to lowercase it —
  /// scales with the whole library on every keystroke.
  Future<Set<String>> searchDocumentText(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const {};
    Database db = await database;
    // LIKE's own wildcards have to survive being typed as literal text.
    final escaped = trimmed
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final rows = await db.rawQuery('''
      SELECT DISTINCT d.dir_name
      FROM $_pageTextTable t
      JOIN $_pagesTable p ON p.id = t.page_id
      JOIN $_documentsTable d ON d.id = p.document_id
      WHERE t.text LIKE ? ESCAPE ?
      ''', ['%$escaped%', r'\']);
    return {for (final row in rows) row['dir_name'] as String};
  }

  Future<int?> _pageId(Database db, String dirName, String imgPath) async {
    final rows = await db.rawQuery('''
      SELECT p.id FROM $_pagesTable p
      JOIN $_documentsTable d ON d.id = p.document_id
      WHERE d.dir_name = ? AND p.img_path = ?
      LIMIT 1
      ''', [dirName, imgPath]);
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  Future<int?> _documentId(Database db, String dirName) async {
    final rows = await db.query(
      _documentsTable,
      columns: ['id'],
      where: 'dir_name = ?',
      whereArgs: [dirName],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  /// Deletes the database file itself. Only for tests that need to start
  /// from a database in a known state.
  @visibleForTesting
  static Future<void> resetForTesting() async {
    final opening = _opening;
    _opening = null;
    if (opening != null) {
      try {
        await (await opening).close();
      } catch (_) {}
    }
    final path = _path;
    if (path != null && File(path).existsSync()) File(path).deleteSync();
  }
}
