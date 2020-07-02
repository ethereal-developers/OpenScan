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

  void imageEditCallback() {
    _getImages();
  }

  void _getImages() {
    setState(() {
      imageFiles = Directory(widget.dirPath)
          .listSync(recursive: false, followLinks: false);
    });
  }

  @override
  void initState() {
    super.initState();
    _getImages();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: primaryColor,
          // TODO: add bottom sheet...
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
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.picture_as_pdf),
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
            ),
            Builder(builder: (context) {
              return IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {
                  showModalBottomSheet(
                      context: context, builder: _buildBottomSheet);
                },
              );
            }),
          ],
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
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    String folderName = widget.dirPath.substring(
        widget.dirPath.lastIndexOf('/') + 1, widget.dirPath.length - 1);
    return Container(
      height: size.height * 0.45,
      color: primaryColor,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  folderName,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                GestureDetector(
                  child: Icon(Icons.edit),
                  onTap: (){
                    // TODO: Rename folder
                  },
                ),
              ],
            ),
          ),
          Divider(
            thickness: 0.2,
            indent: 8,
            endIndent: 8,
            color: Colors.white,
          ),
          ListTile(
            leading: Icon(Icons.add_a_photo),
            title: Text('Add Image'),
            onTap: (){
              //TODO: Call Cropper
            },
          ),
          ListTile(
            leading: Icon(Icons.phone_android),
            title: Text('Save to device'),
            onTap: (){
              // TODO: Save PDF to downloads
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Share as PDF'),
            onTap: (){
              // TODO: Share
            },
          ),
          ListTile(
            leading: Icon(Icons.image),
            title: Text('Share as image'),
            onTap: (){
              //TODO: Share
            },
          ),
        ],
      ),
    );
  }
}
