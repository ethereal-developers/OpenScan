import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openscan/screens/scan_document.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openscan/screens/view_document.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  static String route = "HomeScreen";

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
//  var imageFiles;
  var imageDirPaths = [];
  Future getDirectoryNames() async {
//    imageFiles = [];
    Map<String, int> appDetails;
    Directory appDir = await getExternalStorageDirectory();
    Directory appDirPath = Directory("${appDir.path}");
    appDirPath
        .list(recursive: false, followLinks: false)
        .listen((FileSystemEntity entity) {
      String path = entity.path;
      if (!imageDirPaths.contains(path)) imageDirPaths.add(path);
//      print(path);
//      int n;
//      imageFiles = Directory(imageDirPaths[2]).listSync(recursive: false, followLinks: false);
//      n = imageFiles.length;
//      print("$path: $n");
    });
//    print(imageDirPaths);
    return imageDirPaths;
  }

  @override
  Widget build(BuildContext context) {
    String folderName;
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Home"),
        ),
        // TODO: Move to view doc
        body: FutureBuilder(
          future: getDirectoryNames(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return ListView.builder(
              itemCount: imageDirPaths.length,
              itemBuilder: (context, index) {
                folderName = imageDirPaths[index].substring(
                    imageDirPaths[index].lastIndexOf('/') + 1,
                    imageDirPaths[index].length - 1);
                return ListTile(
                  leading: Icon(Icons.landscape, size: 30),
                  title: Text(folderName),
                  subtitle: Text(folderName),
                  trailing: Icon(
                    Icons.arrow_right,
                    size: 30,
                  ),
                  onTap: () async {
                    getDirectoryNames();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ViewDocument(
                                  dirPath: imageDirPaths[index],
                                )));
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.popAndPushNamed(context, ScanDocument.route),
          child: Icon(Icons.camera),
        ),
      ),
    );
  }
}
