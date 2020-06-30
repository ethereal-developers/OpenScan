import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openscan/screens/scan_document.dart';
import 'package:openscan/screens/share_document.dart';
import 'package:openscan/Utilities/Image_Card.dart';
import 'package:openscan/Utilities/constants.dart';

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
          elevation: 0,
          centerTitle: true,
          backgroundColor: primaryColor,
          title:RichText(
            text: TextSpan(
              text: 'View ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              children: [TextSpan(
                  text: 'Document',
                  style: TextStyle(color: secondaryColor)
              )],
            ),
          ),
        ),
        body: FutureBuilder(
          future: getImages(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: ((imageFiles.length) / 2).round(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      ImageCard(
                          imageFile: File(imageFiles[index * 2].path),
                          ),
                      if (index * 2 + 1 < imageFiles.length)
                        ImageCard(
                            imageFile: File(imageFiles[index * 2 + 1].path),
                            ),
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
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal:15, vertical: 10),
          child: RaisedButton(
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
            color: secondaryColor,
            textColor: primaryColor,
            child: Container(
              alignment: Alignment.center,
              height: 55,
              child: Text("Share Document as PDF", style: TextStyle(fontSize: 18),),
            ),
          ),
        ),
      ),
    );
  }
}


