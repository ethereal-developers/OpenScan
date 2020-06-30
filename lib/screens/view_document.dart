import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openscan/screens/scan_document.dart';
import 'package:openscan/screens/share_document.dart';
import 'package:openscan/Utilities/Image_Card.dart';

class ViewDocument extends StatefulWidget {
  static String route = "ViewDocument";
  final String dirPath;
  ViewDocument({this.dirPath});

  @override
  _ViewDocumentState createState() => _ViewDocumentState();
}

class _ViewDocumentState extends State<ViewDocument> {
  var imageFiles;

  Future getImages() async {
    imageFiles = Directory(widget.dirPath)
        .listSync(recursive: false, followLinks: false);
    return imageFiles;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("View Document"),
        ),
        body: FutureBuilder(
          future: getImages(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return ListView.builder(
              itemCount: ((imageFiles.length) / 2).round(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      ImageCard(
                          imageFile: File(imageFiles[index * 2].path),
                          size: size),
                      if (index * 2 + 1 < imageFiles.length)
                        ImageCard(
                            imageFile: File(imageFiles[index * 2 + 1].path),
                            size: size),
                    ],
                  ),
                );
              },
            );
          },
        ),
//        body: ListView(
//          children: <Widget>[
//            Padding(
//              padding: const EdgeInsets.all(8.0),
//              child: Text(
//                "Name of the document",
//                textAlign: TextAlign.center,
//                style: TextStyle(fontSize: 17.0),
//              ),
//            ),
//            FlatButton(
//              // TODO: Implement how to change the name of the document
//              onPressed: () {},
//              child: Text("Change the name of the document"),
//            ),
//          ],
//        ),
        bottomNavigationBar: FlatButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShareDocument(
                  dirName: widget.dirPath,
                ),
              ),
            );
          },
          child: Text("Share Document as PDF"),
          color: Colors.green,
        ),
      ),
    );
  }
}
