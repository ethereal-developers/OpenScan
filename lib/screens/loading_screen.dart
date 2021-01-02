import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openscan/Utilities/Classes.dart';
import 'package:openscan/Utilities/DatabaseHelper.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/Utilities/file_operations.dart';
import 'package:openscan/screens/home_screen.dart';
import 'package:path_provider/path_provider.dart';

class LoadingScreen extends StatefulWidget {
  static String route = 'loading';

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  List<Map<String, dynamic>> imageDirectories = [];
  List<FileSystemEntity> directoryImages = [];
  var imageDirPaths = [];
  var imageCount = 0;
  DatabaseHelper database = DatabaseHelper();
  FileOperations fileOperations;

  getDirectoryNames() async {
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

  Future getDirectoryImages(String dirPath) async {
    directoryImages = await Directory(dirPath)
        .list(recursive: false, followLinks: false)
        .toList();
    var index = 1;
    for (var image in directoryImages) {
      database.createImage(
        image: ImageOS(
          imgPath: image.path,
          idx: index,
        ),
        tableName:
            dirPath.substring(dirPath.lastIndexOf('/') + 1, dirPath.length),
      );
      if (index == 1) {
        database.updateFirstImagePath(imagePath: image.path, dirPath: dirPath);
      }

      index += 1;
    }
  }

  @override
  void initState() {
    super.initState();
    fileOperations = FileOperations();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: primaryColor,
        body: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(secondaryColor),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 50,
              ),
              FutureBuilder(
                future: getDirectoryNames(),
                builder:
                    (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.hasData) {
                    for (var directory in imageDirectories) {
                      database.createDirectory(
                        directory: DirectoryOS(
                          dirPath: directory['path'],
                          dirName: directory['path'].substring(
                              directory['path'].lastIndexOf('/') + 1,
                              directory['path'].length),
                          created: directory['modified'],
                          imageCount: 0,
                          firstImgPath: null,
                          lastModified: directory['modified'],
                          newName: null,
                        ),
                      );

                      Timer(Duration(milliseconds: 300), () {
                        getDirectoryImages(directory['path']);
                      });
                    }
                    Timer(Duration(milliseconds: 500), () {
                      Navigator.of(context)
                          .pushReplacementNamed(HomeScreen.route);
                    });
                    return RichText(
                      text: TextSpan(
                        text: 'Embrace for a new version of ',
                        style: TextStyle(fontSize: 18, color: secondaryColor),
                        children: [
                          TextSpan(
                            text: 'Open',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: 'Scan',
                            style: TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Text(
                    'Retrieving Data',
                    style: TextStyle(fontSize: 18, color: secondaryColor),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
