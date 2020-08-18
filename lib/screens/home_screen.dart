import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/Widgets/custom_FAB.dart';
import 'package:openscan/screens/about_screen.dart';
import 'package:openscan/screens/getting_started_screen.dart';
import 'package:openscan/screens/view_document.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  static String route = "HomeScreen";

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> imageDirectories = [];
  var imageDirPaths = [];
  var imageCount = 0;

  Future getDirectoryNames() async {
    //TODO: Get all details from Tables
    imageDirectories = [];
    imageDirPaths = [];
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
          'count': imageCount
        });
      }
      imageDirectories.sort((a, b) => a['modified'].compareTo(b['modified']));
      imageDirectories = imageDirectories.reversed.toList();
    });
    return imageDirectories;
  }

  Future _onRefresh() async {
    imageDirectories = await getDirectoryNames();
    setState(() {});
  }

  void getData() {
    _onRefresh();
  }

  Future<bool> _requestPermission() async {
    final PermissionHandler _permissionHandler = PermissionHandler();
    var result = await _permissionHandler.requestPermissions(
        <PermissionGroup>[PermissionGroup.storage, PermissionGroup.camera]);
    if (result[PermissionGroup.storage] == PermissionStatus.granted &&
        result[PermissionGroup.camera] == PermissionStatus.granted) {
      return true;
    }
    return false;
  }

  void askPermission() async {
    await _requestPermission();
  }

  @override
  void initState() {
    super.initState();
    getData();
    askPermission();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
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
        drawer: Container(
          width: size.width * 0.55,
          color: primaryColor,
          child: Column(
            children: <Widget>[
              Spacer(),
              Image.asset(
                'assets/scan_g.jpeg',
                scale: 6,
              ),
              Spacer(),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white24,
              ),
              ListTile(
                title: Center(
                  child: Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white24,
              ),
              ListTile(
                title: Center(
                  child: Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AboutScreen.route);
                },
              ),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white24,
              ),
              ListTile(
                title: Center(
                  child: Text(
                    'Demo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GettingStartedScreen(
                        showSkip: false,
                      ),
                    ),
                  );
                },
              ),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white24,
              ),
              Spacer(
                flex: 9,
              ),
              IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
                color: secondaryColor,
              ),
              Spacer(),
            ],
          ),
        ),
        body: RefreshIndicator(
          backgroundColor: primaryColor,
          color: secondaryColor,
          onRefresh: _onRefresh,
          child: Stack(
            children: [
              Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Text(
                      'Drag down to refresh',
                      style: TextStyle(color: Colors.grey[700], fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder(
                      future: getDirectoryNames(),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        return Theme(
                          data: Theme.of(context)
                              .copyWith(accentColor: primaryColor),
                          child: ListView.builder(
                            itemCount: imageDirectories.length,
                            itemBuilder: (context, index) {
                              folderName = imageDirectories[index]['path']
                                  .substring(
                                      imageDirectories[index]['path']
                                              .lastIndexOf('/') +
                                          1,
                                      imageDirectories[index]['path'].length -
                                          1);
                              return FocusedMenuHolder(
                                onPressed: null,
                                menuWidth: size.width * 0.44,
                                child: ListTile(
                                  // TODO : Add sample image
                                  leading: Icon(
                                    Icons.landscape,
                                    size: 30,
                                  ),
                                  title: Text(
                                    folderName,
                                    style: TextStyle(fontSize: 14),
                                    overflow: TextOverflow.visible,
                                  ),
                                  subtitle: Text(
                                    'Last Modified: ${imageDirectories[index]['modified'].day}-${imageDirectories[index]['modified'].month}-${imageDirectories[index]['modified'].year}',
                                    style: TextStyle(fontSize: 11),
                                  ),
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
                                          dirPath: imageDirectories[index]
                                              ['path'],
                                          quickScan: false,
                                        ),
                                      ),
                                    ).whenComplete(() => () {
                                          print('Completed');
                                        });
                                  },
                                ),
                                menuItems: [
                                  FocusedMenuItem(
                                    title: Text('Delete'),
                                    trailingIcon: Icon(Icons.delete),
                                    backgroundColor: Colors.redAccent,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(10),
                                              ),
                                            ),
                                            title: Text('Delete'),
                                            content: Text(
                                                'Do you really want to delete file?'),
                                            actions: <Widget>[
                                              FlatButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('Cancel'),
                                              ),
                                              FlatButton(
                                                onPressed: () {
                                                  print(imageDirectories[index]
                                                      ['path']);
                                                  Directory(imageDirectories[
                                                          index]['path'])
                                                      .deleteSync(
                                                          recursive: true);
//                                              DatabaseHelper()
//                                                ..deleteDirectory(
//                                                    dirPath:
//                                                        imageDirectories[index]
//                                                            ['path']);
                                                  Navigator.pop(context);
                                                  getData();
                                                },
                                                child: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                      color: Colors.redAccent),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ).whenComplete(() {
                                        setState(() {});
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 30,
                bottom: 20,
                child: CustomFAB(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewDocument(
                          quickScan: false,
                        ),
                      ),
                    ).whenComplete(() {
                      setState(() {});
                    });
                  },
                  onPressedQuick: () {
                    //TODO: Work on QuickScan
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewDocument(
                          quickScan: true,
                        ),
                      ),
                    ).whenComplete(() {
                      setState(() {});
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
