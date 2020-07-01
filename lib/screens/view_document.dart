import 'dart:io';
import 'package:flutter/material.dart';
import 'package:openscan/Utilities/Image_Card.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/screens/share_document.dart';

class ViewDocument extends StatefulWidget {
  static String route = "ViewDocument";

  ViewDocument({this.dirPath});
  final String dirPath;

  @override
  _ViewDocumentState createState() => _ViewDocumentState();
}

class _ViewDocumentState extends State<ViewDocument> {
  var imageFiles;

  void _deleteDocument() {
    Directory(widget.dirPath).deleteSync(recursive: true);
  }

  void imageEditCallback() {
    _getImages();
  }

  void _getImages() {
    setState(() {
      imageFiles = Directory(widget.dirPath)
          .listSync(recursive: false, followLinks: false);
    });
    print(imageFiles);
  }

  @override
  void initState() {
    super.initState();
    _getImages();
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
          title: RichText(
            text: TextSpan(
              text: 'View ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              children: [
                TextSpan(
                  text: 'Document',
                  style: TextStyle(color: secondaryColor),
                ),
              ],
            ),
          ),
        ),
        body: RefreshIndicator(
          backgroundColor: primaryColor,
          color: secondaryColor,
          onRefresh: () async {
            _getImages();
          },
          child: ListView.builder(
            itemCount: ((imageFiles.length) / 2).round(),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ImageCard(
                      imageFile: File(imageFiles[index * 2].path),
                      imageFileEditCallback: imageEditCallback,
                    ),
                    if (index * 2 + 1 < imageFiles.length)
                      ImageCard(
                        imageFile: File(imageFiles[index * 2 + 1].path),
                        imageFileEditCallback: imageEditCallback,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
              child: Text(
                "Share Document as PDF",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
