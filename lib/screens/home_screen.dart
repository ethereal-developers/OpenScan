import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/screens/view_document.dart';
import 'package:path_provider/path_provider.dart';

import 'scan_document.dart';

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
          width: size.width * 0.6,
          color: primaryColor,
          child: Column(
//            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Spacer(),
              Image.asset('assets/scan_g.jpeg', scale: 6,),
              Spacer(),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white,
              ),
              MenuButton(text: 'Menu', size: size),
              MenuButton(text: 'Settings', size: size),
              MenuButton(text: 'About', size: size),
              Spacer(
                flex: 10,
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
                  // TODO: Add FocusedMenu
                  return ListTile(
                    // TODO : Add sample image
                    leading: Icon(
                      Icons.landscape,
                      size: 30,
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
        floatingActionButton: Builder(builder: (context) {
          return FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, ScanDocument.route)
                  .then((value) => Scaffold.of(context).showSnackBar(SnackBar(
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        backgroundColor: primaryColor,
                        duration: Duration(seconds: 1),
                        content: Container(
                          decoration: BoxDecoration(),
                          alignment: Alignment.center,
                          height: 15,
                          width: size.width * 0.3,
                          child: Text(
                            (value) ? 'Saved' : 'Discarded',
                            style: TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )));
            },
            backgroundColor: secondaryColor,
            child: Icon(
              Icons.camera,
              color: primaryColor,
            ),
          );
        }),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  const MenuButton({this.size, this.text});

  final String text;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              color: primaryColor,
              height: size.height * 0.06,
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
        Divider(
          thickness: 0.2,
          indent: 6,
          endIndent: 6,
          color: Colors.white,
        ),
      ],
    );
  }
}
