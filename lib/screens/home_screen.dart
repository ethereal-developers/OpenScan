import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/screens/scan_document.dart';
import 'package:openscan/screens/view_document.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  static String route = "HomeScreen";

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var imageDirPaths = [];

  Future getDirectoryNames() async {
    Directory appDir = await getExternalStorageDirectory();
    Directory appDirPath = Directory("${appDir.path}");
    appDirPath
        .list(recursive: false, followLinks: false)
        .listen((FileSystemEntity entity) {
      String path = entity.path;
      if (!imageDirPaths.contains(path) &&
          path !=
              '/storage/emulated/0/Android/data/com.example.openscan/files/Pictures')
        imageDirPaths.add(path);
    });
    return imageDirPaths;
  }

  @override
  Widget build(BuildContext context) {
    String folderName;
    return SafeArea(
      child: Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: primaryColor,
          title: RichText(
            text: TextSpan(
              text: 'Open',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
              children: [
                TextSpan(text: 'Scan', style: TextStyle(color: secondaryColor))
              ],
            ),
          ),
        ),
        body: RefreshIndicator(
          backgroundColor: primaryColor,
          color: secondaryColor,
          onRefresh: () async {
            imageDirPaths = [];
            imageDirPaths = await getDirectoryNames();
            setState(() {});
          },
          child: FutureBuilder(
            future: getDirectoryNames(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              return ListView.builder(
                itemCount: imageDirPaths.length,
                itemBuilder: (context, index) {
                  folderName = imageDirPaths[index].substring(
                      imageDirPaths[index].lastIndexOf('/') + 1,
                      imageDirPaths[index].length - 1);
                  return ListTile(
                    // TODO : Add sample image
                    leading: Icon(
                      Icons.landscape,
                      size: 30,
                      color: secondaryColor,
                    ),
                    title: Text(folderName),
                    subtitle: Text(folderName),
                    trailing: Icon(
                      Icons.arrow_right,
                      size: 30,
                      color: secondaryColor,
                    ),
                    onTap: () async {
                      getDirectoryNames();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewDocument(
                            dirPath: imageDirPaths[index],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, ScanDocument.route);
          },
          backgroundColor: secondaryColor,
          child: Icon(
            Icons.camera,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}
