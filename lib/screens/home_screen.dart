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
  void getDirectoryNames() async {
    // TODO: Append values to the map
    Map<String, int> appDetails;
    Directory appDir = await getExternalStorageDirectory();
    Directory appDirPath = Directory("${appDir.path}");
    appDirPath
        .list(recursive: false, followLinks: false)
        .listen((FileSystemEntity entity) {
      String path = entity.path;
      int n;
      var some =
          Directory(entity.path).listSync(recursive: false, followLinks: false);
      n = some.length;
      // path is a string that contains the name of the folder
      // n is the number of files present inside the folder
      // This function is triggered when the user clicks on any of the ListTiles
      print("$path: $n");
    });
    print(appDetails);
  }

  List<ListTile> getDocuments({@required BuildContext context, int temp}) {
    List<ListTile> documentsList = [];
    for (int i = 0; i < temp; i++) {
      documentsList.add(
        ListTile(
          leading: Icon(Icons.landscape),
          title: Text("Name of the document"),
          subtitle: Text("Date and size of the file"),
          trailing: Icon(Icons.arrow_right),
          onTap: () async {
            getDirectoryNames();
            Navigator.pushNamed(context, ViewDocument.route);
          },
        ),
      );
    }
    return documentsList;
  }

  var image;
  Future _openCamera() async {
    final _picker = ImagePicker();
    var picture = await _picker.getImage(source: ImageSource.camera);
    setState(() {
      final requiredPicture = File(picture.path);
      print(picture.path);
      image = requiredPicture;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Home"),
        ),
        body: ListView(
          children: getDocuments(context: context, temp: 10),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
//            await _openCamera();
            if (image == null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScanDocument(
//                    image: image,
                      ),
                ),
              );
            }
          },
          child: Icon(Icons.camera),
        ),
      ),
    );
  }
}
