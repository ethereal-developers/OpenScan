import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openscan/screens/scan_document.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openscan/screens/view_document.dart';

class HomeScreen extends StatefulWidget {
  static String route = "HomeScreen";

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ListTile> getDocuments({@required BuildContext context, int temp}) {
    List<ListTile> documentsList = [];
    for (int i = 0; i < temp; i++) {
      documentsList.add(
        ListTile(
          leading: Icon(Icons.landscape),
          title: Text("Name of the document"),
          subtitle: Text("Date and size of the file"),
          trailing: Icon(Icons.arrow_right),
          onTap: () {
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
