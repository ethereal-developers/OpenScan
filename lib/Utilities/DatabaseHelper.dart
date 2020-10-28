import 'dart:async';
import 'dart:io';

import 'package:openscan/Utilities/Classes.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  DatabaseHelper();

  static final instance = DatabaseHelper._privateConstructor();
  static final _dbName = "OpenScan.db";
  static final _dbVersion = 1;
  static final _masterTableName = 'DirectoryDetails';
  static Database _database;
  String path;
  String _dirTableName;

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

      // TODO: Create tables for existing directories (for old users)
      // for (var directory in getDirectoryNames()) {
        // createDirectory(
        //   directory: DirectoryOS(
        //     dirName: directory['path'].substring(directory['path'].lastIndexOf('/') + 1, directory['path'].length - 1),
        //     dirPath: directory['path'],
        //     created: directory['modified'],
        //     imageCount: 0,
        //     firstImgPath: null,
        //     lastModified: directory['modified'],
        //     newName: null,
        //   ),
        // );

        // getDirectoryImages(directory['path']);
      // }
  }

  temp() async {
    var data = await getDirectoryNames();
    print(data);
    for (var directory in data) {
      // createDirectory(
      //   directory: DirectoryOS(
      //     dirName: directory['path'].substring(directory['path'].lastIndexOf('/') + 1, directory['path'].length - 1),
      //     dirPath: directory['path'],
      //     created: directory['modified'],
      //     imageCount: 0,
      //     firstImgPath: null,
      //     lastModified: directory['modified'],
      //     newName: null,
      //   ),
      // );
      print(directory);
      getDirectoryImages(directory['path']);
    }
  }

  getDirectoryNames() async {
    List<Map<String, dynamic>> imageDirectories = [];
    var imageDirPaths = [];
    var imageCount = 0;
    Directory appDir = await getExternalStorageDirectory();
    Directory appDirPath = Directory("${appDir.path}");
    appDirPath
        .list(recursive: false, followLinks: false)
        .listen((FileSystemEntity entity) {
      String path = entity.path;
      if (!imageDirPaths.contains(path) && !path.contains('/files/Pictures')) {
        imageDirPaths.add(path);
        Directory(path)
            .list(recursive: false, followLinks: false)
            .listen((FileSystemEntity entity) {
          imageCount++;
        });
        FileStat fileStat = FileStat.statSync(path);
        imageDirectories.add({
          'path': path,
          'modified': fileStat.modified,
          'size': fileStat.size,
          'count': imageCount,
        });
      }
      imageDirectories.sort((a, b) => a['modified'].compareTo(b['modified']));
      imageDirectories = imageDirectories.reversed.toList();
    });
    return imageDirectories;
  }

  void getDirectoryImages(String dirPath) {
    List<String> imageFilesPath = [];
    List<Map<String, dynamic>> imageFilesWithDate = [];
    imageFilesPath = [];
    imageFilesWithDate = [];

    var data = Directory(dirPath).list(recursive: false, followLinks: false).toList();
    // print(data);
    //     .listen((FileSystemEntity entity) {
    //   List<String> temp = entity.path.split(" ");
    //   // var imageFileWithDate = {
    //   //   "file": entity,
    //   //   "creationDate": DateTime.parse(
    //   //       "${temp[3]} ${temp[4].split('.')[0]}.${temp[4].split('.')[1]}")
    //   // };
    //   //TODO: Fix delete bug
    //   if (!imageFilesWithDate.contains(imageFileWithDate)) {
    //     // print(imageFilesWithDate.contains(imageFileWithDate));
    //     imageFilesWithDate.add(imageFileWithDate);
    //     // print(imageFileWithDate);
    //   }
    //
    //   imageFilesWithDate
    //       .sort((a, b) => a["creationDate"].compareTo(b["creationDate"]));
    //   for (var image in imageFilesWithDate) {
    //     if (!imageFilesPath.contains(image['file'].path))
    //       imageFilesPath.add(image["file"].path);
    //   }
    // });
  }

  Future createDirectory({DirectoryOS directory}) async {
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

  Future createImage({ImageOS image, String tableName, String dirPath}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    int index = await db.insert(_dirTableName, {
      'idx': image.idx,
      'img_path': image.imgPath,
    });
    print('Image Index: $index');

    var data = await db.query(_masterTableName,
        columns: ['image_count'],
        where: 'dir_name == ?',
        whereArgs: [tableName]);
    // TODO: Not working when multiple images are saved !Check!
    db.update(
        _masterTableName,
        {
          'image_count': data[0]['image_count'] + 1,
          'last_modified': DateTime.now().toString()
        },
        where: 'dir_name == ?',
        whereArgs: [tableName]);
  }

  Future<int> updateFirstImagePath({String imagePath, String dirPath}) async {
    Database db = await instance.database;
    return await db.update(_masterTableName, {'first_img_path': imagePath},
        where: 'dir_path == ?', whereArgs: [dirPath]);
  }

  // For Renaming Directory
  Future<int> updateDirectory({DirectoryOS directory}) async {
    Database db = await instance.database;
    return await db.update(
        _masterTableName,
        {
          // 'first_img_path': directory.firstImgPath,
          // 'last_modified': directory.lastModified,
          'new_name': directory.newName
        },
        where: 'dir_name == ?',
        whereArgs: [directory.dirName]);
  }

  // For Reordering Images
  Future<int> updateImageIndex({ImageOS image, String tableName}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    return await db.update(
        _dirTableName,
        {
          'idx': image.idx,
        },
        where: 'img_path == ?',
        whereArgs: [image.imgPath]);
  }

  Future deleteDirectory({String dirPath}) async {
    Database db = await instance.database;
    await db
        .delete(_masterTableName, where: 'dir_path == ?', whereArgs: [dirPath]);
    String dirName = dirPath.substring(dirPath.lastIndexOf("/") + 1);
    getDirectoryTableName(dirName);
    await db.execute('DROP TABLE $_dirTableName');
  }

  Future deleteImage({String imgPath, String tableName}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    //TODO: Check if image index is 1, then change first_img_path in master
    await db
        .delete(_dirTableName, where: 'img_path == ?', whereArgs: [imgPath]);
    var data = await db.query(_masterTableName,
        columns: ['image_count'],
        where: 'dir_name == ?',
        whereArgs: [tableName]);
    db.update(_masterTableName, {'image_count': data[0]['image_count'] - 1},
        where: 'dir_name == ?', whereArgs: [tableName]);
  }

  Future getMasterData() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> data = await db.query(_masterTableName);
    return data;
  }

  Future getDirectoryData(String tableName) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    List<Map<String, dynamic>> data = await db.query(_dirTableName);
    return data;
  }

// Future queryAll() async {
//   Database db = await instance.database;
//   List<Map<String, dynamic>> data = await db.query(_masterTableName);
//
//   for (var record in data){
//     getDirectoryTableName(record['dir_name']);
//     data = await db.query(_dirTableName);
//   }
// }

//  void deleteDB() async {
//    await deleteDatabase(path);
//  }
}
