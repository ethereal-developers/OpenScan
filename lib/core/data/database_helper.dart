import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:openscan/core/models.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  DatabaseHelper();

  static final instance = DatabaseHelper._privateConstructor();
  static final _dbName = "OpenScan.db";
  static final _dbVersion = 1;
  static final _masterTableName = 'DirectoryDetails';
  static late Database _database;
  late String path;
  late String _dirTableName;

  Future<Database> get database async {
    _database = await initDB();
    return _database;
  }

  /// Initializing database
  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  /// Remove spl characters from Directory Name
  getDirectoryTableName(String dirName) {
    dirName = dirName.replaceAll('-', '');
    dirName = dirName.replaceAll('.', '');
    dirName = dirName.replaceAll(' ', '');
    dirName = dirName.replaceAll(':', '');
    _dirTableName = '"' + dirName + '"';
  }

  // <======================= Master Table Operations =========================>

  /// Create Master Table
  FutureOr<void> _onCreate(Database db, int version) {
    db.execute('''
      CREATE TABLE $_masterTableName(
      dir_name TEXT,
      dir_path TEXT,
      created TEXT,
      image_count INTEGER,
      first_img_path TEXT,
      last_modified TEXT,
      new_name TEXT)
      ''');
  }

  /// Read master table data
  Future getMasterData() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> data = await db.query(_masterTableName);
    return data;
  }

  /// Updates first image path in Master table
  Future<int> updateFirstImagePath({String? imagePath, String? dirPath}) async {
    Database db = await instance.database;
    return await db.update(_masterTableName, {'first_img_path': imagePath},
        where: 'dir_path == ?', whereArgs: [dirPath]);
  }

  /// Renames Directory in Master table
  Future<int> renameDirectory({
    required String tableName,
    required String newName,
  }) async {
    Database db = await instance.database;
    return await db.update(_masterTableName, {'new_name': newName},
        where: 'dir_name == ?', whereArgs: [tableName]);
  }

  /// Updates image count in Master table
  void updateImageCount({required String tableName}) async {
    Database db = await instance.database;
    var data = await getImageData(tableName);
    db.update(
      _masterTableName,
      {'image_count': data.length},
      where: 'dir_name == ?',
      whereArgs: [tableName],
    );
  }

  // <===================== Directory Table Operations ========================>

  /// Creates Directory table
  Future createDirectory({required DirectoryOS directory}) async {
    Database db = await instance.database;
    int index = await db.insert(_masterTableName, {
      'dir_name': directory.dirName,
      'dir_path': directory.dirPath,
      'created': directory.created.toString(),
      'image_count': directory.imageCount,
      'first_img_path': directory.firstImgPath,
      'last_modified': directory.lastModified.toString(),
      'new_name': directory.newName
    });

    getDirectoryTableName(directory.dirName);
    debugPrint('Directory Index: $index');
    db.execute('''
      CREATE TABLE $_dirTableName(
      idx INTEGER,
      img_path TEXT,
      orig_img_path TEXT,
      unfiltered_img_path TEXT,
      filter_name TEXT)
      ''');
  }

  /// Reads image records from Directory table
  ///
  /// Returns: Image records [List]
  Future getImageData(String tableName) async {
    Database db = await instance.database;
    await addOrigImageColumn(tableName);
    await addFilterColumns(tableName);
    getDirectoryTableName(tableName);
    List<Map<String, dynamic>> data =
        await db.query(_dirTableName, orderBy: 'idx');

    return data;
  }

  /// Updates image path in Directory table
  ///
  /// Pass [origPath] to also record the uncropped original the image was
  /// derived from; omitting it leaves whatever original is already stored
  /// untouched, so a re-crop can keep pointing at the same original.
  ///
  /// Returns: Records updated [int]
  Future<int> updateImagePath(
      {required String tableName,
      String? imgPath,
      String? origPath,
      String? unfilteredPath,
      String? filterName,
      bool clearFilter = false,
      bool clearOriginal = false,
      int? idx}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    return await db.update(
        _dirTableName,
        {
          'img_path': imgPath,
          // clearOriginal distinguishes "no original for this page" from
          // "leave whatever original is on record alone" — without it a
          // page whose original is gone keeps pointing at a deleted file.
          if (origPath != null || clearOriginal) 'orig_img_path': origPath,
          if (clearFilter || unfilteredPath != null)
            'unfiltered_img_path': unfilteredPath,
          if (clearFilter || filterName != null) 'filter_name': filterName,
        },
        where: 'idx == ?',
        whereArgs: [idx]);
  }

  /// Updates image index in Directory table
  ///
  /// Returns: Records updated [int]
  Future<int> updateImageIndex(
      {String? imgPath, int? newIndex, required String tableName}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    return await db.update(
        _dirTableName,
        {
          'idx': newIndex,
        },
        where: 'img_path == ?',
        whereArgs: [imgPath]);
  }

  /// Adds the uncropped-original column to directory tables created before
  /// originals were retained. Rows in those tables keep a null
  /// `orig_img_path`, which callers read as "no original kept — crop from
  /// the stored image itself".
  Future addOrigImageColumn(String tableName) async {
    getDirectoryTableName(tableName);
    await _addColumnIfMissing(_dirTableName, 'orig_img_path', 'TEXT');
  }

  /// Adds the filter columns to directory tables created before filters
  /// were persisted. Rows in those tables keep a null `unfiltered_img_path`
  /// and `filter_name`, which callers read as "no filter applied — the
  /// stored image is the unfiltered one".
  ///
  /// Tables from those builds also carry a `filtered_image_path` column
  /// that was never written to; it is left in place (SQLite makes dropping
  /// a column costly) and simply ignored.
  Future addFilterColumns(String tableName) async {
    getDirectoryTableName(tableName);
    await _addColumnIfMissing(_dirTableName, 'unfiltered_img_path', 'TEXT');
    await _addColumnIfMissing(_dirTableName, 'filter_name', 'TEXT');
  }

  /// Adds [column] to [table] unless it is already there, so the migration
  /// is safe to run on every read.
  Future _addColumnIfMissing(String table, String column, String type) async {
    Database db = await instance.database;
    List tableData = await db.rawQuery('PRAGMA table_info($table);');
    bool columnAvailable =
        tableData.any((tableColumn) => tableColumn['name'] == column);
    if (!columnAvailable) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type;');
    }
  }

  // <=========================== CRUD Operations =============================>

  /// Adds image to database.
  /// Inserts Directory table and updates Master Table
  ///
  /// Returns: Records updated [int]
  Future createImage(
      {required ImageOS image, required String tableName}) async {
    Database db = await instance.database;
    // Directory tables created by older versions have no orig_img_path or
    // filter columns; writing to them would throw.
    await addOrigImageColumn(tableName);
    await addFilterColumns(tableName);
    getDirectoryTableName(tableName);
    int index = await db.insert(_dirTableName, {
      'idx': image.idx,
      'img_path': image.imgPath,
      'orig_img_path': image.origPath,
      // 'shouldCompress': image.shouldCompress,
    });
    debugPrint('Image Index: $index');

    return await db.update(
        _masterTableName,
        {
          'image_count': index,
          'last_modified': DateTime.now().toString(),
        },
        where: 'dir_name == ?',
        whereArgs: [tableName]);
  }

  /// Deletes Image Directory from database
  Future deleteDirectory({required String dirPath}) async {
    Database db = await instance.database;
    await db
        .delete(_masterTableName, where: 'dir_path == ?', whereArgs: [dirPath]);
    String dirName = basename(dirPath);
    getDirectoryTableName(dirName);
    await db.execute('DROP TABLE $_dirTableName');
  }

  /// Deletes image from database
  Future deleteImage({String? imgPath, required String tableName}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    await db
        .delete(_dirTableName, where: 'img_path == ?', whereArgs: [imgPath]);

    updateImageCount(tableName: tableName);
  }
}
