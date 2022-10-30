import 'dart:async';
import 'dart:io';
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
    print('Directory Index: $index');
    db.execute('''
      CREATE TABLE $_dirTableName(
      idx INTEGER,
      img_path TEXT,
      filtered_image_path TEXT)
      ''');
  }

  /// Reads image records from Directory table
  ///
  /// Returns: Image records [List]
  Future getImageData(String tableName) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    List<Map<String, dynamic>> data =
        await db.query(_dirTableName, orderBy: 'idx');

    addFilteredImageColumn(tableName);

    return data;
  }

  /// Updates image path in Directory table
  ///
  /// Returns: Records updated [int]
  Future<int> updateImagePath(
      {required String tableName, String? imgPath, int? idx}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    return await db.update(
        _dirTableName,
        {
          'img_path': imgPath,
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

  /// Add filtered image path column to old directory
  Future addFilteredImageColumn(String tableName) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);

    List tableData = await db.rawQuery('PRAGMA table_info($_dirTableName);');
    bool filterColumnAvailable = false;
    for (Map<String, dynamic> column in tableData.reversed) {
      if (column['name'] == 'filtered_image_path') filterColumnAvailable = true;
      break;
    }
    if (!filterColumnAvailable) {
      await db.rawQuery(
          'ALTER TABLE $_dirTableName ADD COLUMN filtered_image_path TEXT;');
    }
  }

  // <=========================== Cache Operations ============================>

  // <=========================== CRUD Operations =============================>

  /// Adds image to database.
  /// Inserts Directory table and updates Master Table
  ///
  /// Returns: Records updated [int]
  Future createImage(
      {required ImageOS image, required String tableName}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    int index = await db.insert(_dirTableName, {
      'idx': image.idx,
      'img_path': image.imgPath,
      // 'shouldCompress': image.shouldCompress,
    });
    print('Image Index: $index');

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
