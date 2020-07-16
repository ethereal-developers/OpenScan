import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:openscan/Utilities/Classes.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  DatabaseHelper();

  static final instance = DatabaseHelper._privateConstructor();
  String path;
  static final _dbName = "OpenScan.db";
  static final _dbVersion = 1;
  static final _masterTableName = 'DirectoryDetails';
  String _dirTableName;
  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await initDB();
    return _database;
  }

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
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
    // TODO: Create tables for existing directories (for old users)
  }

  Future createDirectory({DirectoryOS directory}) async {
    Database db = await instance.database;
    int index = await db.insert(_masterTableName, {
      'dir_name' : directory.dirName,
      'dir_path' : directory.dirPath,
      'created' : directory.created,
      'image_count' : directory.imageCount,
      'first_img_path' : directory.firstImagePath,
      'last_modified' : directory.lastModified,
      'new_name' : directory.newName
    });
    print('Directory Index: $index');
    _dirTableName = directory.dirName;
    db.execute('''
      CREATE TABLE $_dirTableName(
      index INT,
      img_name TEXT,
      img_path TEXT,
      created TEXT)
      ''');
  }

  Future createImage({ImageOS image, String tableName}) async {
    Database db = await instance.database;
    _dirTableName = tableName;
    int index = await db.insert(_dirTableName, {
      'index' : image.index,
      'img_name' : image.imgName,
      'img_path' : image.imgPath,
      'created' : image.created
    });
    print('Image Index: $index');
    var data = await db.query(_masterTableName,
        columns: ['no_of_images'],
        where: 'dir_name == ?',
        whereArgs: [tableName]);
    db.update(_masterTableName, {'no_of_images': data[0]['no_of_images'] + 1},
        where: 'dir_name == ?', whereArgs: [tableName]);
  }

  Future<int> updateDirectory({DirectoryOS directory}) async {
    Database db = await instance.database;
    return await db.update(_masterTableName, {
      'image_count' : directory.imageCount,
      'first_img_path' : directory.firstImagePath,
      'last_modified' : directory.lastModified,
      'new_name' : directory.newName
    });
  }

  Future<int> updateImage({ImageOS image, String tableName}) async {
    Database db = await instance.database;
    return await db.update(tableName, {
      'index' : image.index,
      'img_name' : image.imgName,
    },
        where: 'img_name == ?', whereArgs: [image.imgName]);
  }

  Future deleteDirectory({String dirName}) async {
    Database db = await instance.database;
    await db
        .delete(_masterTableName, where: 'dir_name == ?', whereArgs: [dirName]);
    await db.execute('DROP TABLE $dirName');
  }

  Future deleteImage({String imgName, String tableName}) async {
    Database db = await instance.database;
    await db.delete(tableName, where: 'img_name == ?', whereArgs: [imgName]);
    var data = await db.query(_masterTableName,
        columns: ['no_of_images'],
        where: 'dir_name == ?',
        whereArgs: [tableName]);
    db.update(_masterTableName, {'no_of_images': data[0]['no_of_images'] - 1},
        where: 'dir_name == ?', whereArgs: [tableName]);
  }

  Future queryAll() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> data = await db.query(_masterTableName);
    print(data);
  }

//  void deleteDB() async {
//    await deleteDatabase(path);
//  }
}





