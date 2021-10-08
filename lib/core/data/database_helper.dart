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

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  getDirectoryTableName(String dirName) {
    dirName = dirName.replaceAll('-', '');
    dirName = dirName.replaceAll('.', '');
    dirName = dirName.replaceAll(' ', '');
    dirName = dirName.replaceAll(':', '');
    _dirTableName = '"' + dirName + '"';
  }

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
      img_path TEXT)
      ''');
  }

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

    await db.update(
        _masterTableName,
        {
          'image_count': index,
          'last_modified': DateTime.now().toString(),
        },
        where: 'dir_name == ?',
        whereArgs: [tableName]);
  }

  Future deleteDirectory({required String dirPath}) async {
    Database db = await instance.database;
    await db
        .delete(_masterTableName, where: 'dir_path == ?', whereArgs: [dirPath]);
    String dirName = dirPath.substring(dirPath.lastIndexOf("/") + 1);
    getDirectoryTableName(dirName);
    await db.execute('DROP TABLE $_dirTableName');
  }

  Future deleteImage({String? imgPath, required String tableName}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    await db
        .delete(_dirTableName, where: 'img_path == ?', whereArgs: [imgPath]);

    updateImageCount(tableName: tableName);
  }

  /// <---- Master Table Operations ---->

  Future getMasterData() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> data = await db.query(_masterTableName);
    return data;
  }

  Future<int> updateFirstImagePath({String? imagePath, String? dirPath}) async {
    Database db = await instance.database;
    return await db.update(_masterTableName, {'first_img_path': imagePath},
        where: 'dir_path == ?', whereArgs: [dirPath]);
  }

  Future<int> renameDirectory({
    required String tableName,
    required String newName,
  }) async {
    Database db = await instance.database;
    return await db.update(_masterTableName, {'new_name': newName},
        where: 'dir_name == ?', whereArgs: [tableName]);
  }

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

  /// <---- Directory Table Operations ---->

  Future getImageData(String tableName) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    List<Map<String, dynamic>> data =
        await db.query(_dirTableName, orderBy: 'idx');
    return data;
  }

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

  // Future<int> updateShouldCompress({ImageOS image, String tableName}) async {
  //   Database db = await instance.database;
  //   getDirectoryData(tableName);
  //   return await db.update(
  //       _dirTableName,
  //       {
  //         'shouldCompress': false,
  //       },
  //       where: 'img_path == ?',
  //       whereArgs: [image.imgPath]);
  // }
}
