import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:openscan/Utilities/Classes.dart';
import 'package:openscan/Utilities/DatabaseHelper.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/screens/about_screen.dart';
import 'package:openscan/screens/getting_started_screen.dart';
import 'package:openscan/screens/view_document.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  static String route = "HomeScreen";

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DatabaseHelper database = DatabaseHelper();
  List<Map<String, dynamic>> masterData;
  List<DirectoryOS> masterDirectories = [];

  Future homeRefresh() async {
    await getMasterData();
    setState(() {});
  }

  void getData() {
    homeRefresh();
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

  Future<List<DirectoryOS>> getMasterData() async {
    masterDirectories = [];
    masterData = await database.getMasterData();
    print('Master Table => $masterData');
    for (var directory in masterData) {
      var flag = false;
      for (var dir in masterDirectories) {
        if (dir.dirPath == directory['dir_path']) {
          flag = true;
        }
      }
      if (!flag) {
        masterDirectories.add(
          DirectoryOS(
            dirName: directory['dir_name'],
            dirPath: directory['dir_path'],
            created: DateTime.parse(directory['created']),
            imageCount: directory['image_count'],
            firstImgPath: directory['first_img_path'],
            lastModified: DateTime.parse(directory['last_modified']),
            newName: directory['new_name'],
          ),
        );
      }
    }
    masterDirectories = masterDirectories.reversed.toList();
    return masterDirectories;
  }

  @override
  void initState() {
    super.initState();
    askPermission();
    getMasterData();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
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
          onRefresh: homeRefresh,
          child: Column(
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
                  future: getMasterData(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    return Theme(
                      data:
                          Theme.of(context).copyWith(accentColor: primaryColor),
                      child: ListView.builder(
                        itemCount: masterDirectories.length,
                        itemBuilder: (context, index) {
                          return FocusedMenuHolder(
                            onPressed: null,
                            menuWidth: size.width * 0.44,
                            child: ListTile(
                              leading: Image.file(
                                File(masterDirectories[index].firstImgPath),
                                width: 50,
                                height: 50,
                              ),
                              title: Text(
                                masterDirectories[index].newName ??
                                    masterDirectories[index].dirName,
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Last Modified: ${masterDirectories[index].lastModified.day}-${masterDirectories[index].lastModified.month}-${masterDirectories[index].lastModified.year}',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    '${masterDirectories[index].imageCount} ${(masterDirectories[index].imageCount == 1) ? 'image' : 'images'}',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_right,
                                size: 30,
                                color: secondaryColor,
                              ),
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewDocument(
                                      directoryOS: masterDirectories[index],
                                    ),
                                  ),
                                ).whenComplete(() {
                                  homeRefresh();
                                });
                              },
                            ),
                            menuItems: [
                              FocusedMenuItem(
                                title: Text(
                                  'Rename',
                                  style: TextStyle(color: Colors.black),
                                ),
                                trailingIcon: Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      String fileName = '';
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                        ),
                                        title: Text('Rename File'),
                                        content: TextField(
                                          onChanged: (value) {
                                            fileName = value;
                                          },
                                          controller: TextEditingController(
                                            text: fileName,
                                          ),
                                          cursorColor: secondaryColor,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          decoration: InputDecoration(
                                            prefixStyle:
                                                TextStyle(color: Colors.white),
                                            focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: secondaryColor)),
                                          ),
                                        ),
                                        actions: <Widget>[
                                          FlatButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Cancel'),
                                          ),
                                          FlatButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              print(fileName);
                                              masterDirectories[index].newName =
                                                  fileName;
                                              database.renameDirectory(
                                                  directory:
                                                      masterDirectories[index]);
                                              homeRefresh();
                                            },
                                            child: Text(
                                              'Save',
                                              style: TextStyle(
                                                  color: secondaryColor),
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
                                              Directory(masterDirectories[index]
                                                      .dirPath)
                                                  .deleteSync(recursive: true);
                                              database.deleteDirectory(
                                                  dirPath:
                                                      masterDirectories[index]
                                                          .dirPath);
                                              Navigator.pop(context);
                                              homeRefresh();
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
        ),
        floatingActionButton: SpeedDial(
          marginRight: 18,
          marginBottom: 20,
          animatedIcon: AnimatedIcons.menu_close,
          animatedIconTheme: IconThemeData(size: 22.0),
          visible: true,
          closeManually: false,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          tooltip: 'Scan Options',
          heroTag: 'speed-dial-hero-tag',
          backgroundColor: secondaryColor,
          foregroundColor: Colors.black,
          elevation: 8.0,
          shape: CircleBorder(),
          children: [
            SpeedDialChild(
              child: Icon(Icons.camera_alt),
              backgroundColor: Colors.white,
              label: 'Normal Scan',
              labelStyle: TextStyle(fontSize: 18.0, color: Colors.black),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewDocument(
                      quickScan: false,
                      directoryOS: DirectoryOS(),
                    ),
                  ),
                ).whenComplete(() {
                  homeRefresh();
                });
              },
            ),
            SpeedDialChild(
              child: Icon(Icons.add_a_photo),
              backgroundColor: Colors.white,
              label: 'Quick Scan',
              labelStyle: TextStyle(fontSize: 18.0, color: Colors.black),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewDocument(
                      quickScan: true,
                      directoryOS: DirectoryOS(),
                    ),
                  ),
                ).whenComplete(() {
                  homeRefresh();
                });
              },
            ),
            SpeedDialChild(
              child: Icon(Icons.image),
              backgroundColor: Colors.white,
              label: 'Import from Gallery',
              labelStyle: TextStyle(fontSize: 18.0, color: Colors.black),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewDocument(
                      quickScan: false,
                      directoryOS: DirectoryOS(),
                      fromGallery: true,
                    ),
                  ),
                ).whenComplete(() {
                  homeRefresh();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
