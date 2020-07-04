import 'dart:core';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/Utilities/cropper.dart';
import 'package:openscan/Utilities/file_operations.dart';
import 'package:openscan/screens/home_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'view_document.dart';

class ScanDocument extends StatefulWidget {
  static String route = "ScanDocument";

  @override
  _ScanDocumentState createState() => _ScanDocumentState();
}

class _ScanDocumentState extends State<ScanDocument> {
  FileOperations fileOperations = FileOperations();
  File imageFile;
  List<File> imageFiles = [];
  String appPath;
  String docPath;

  @override
  void initState() {
    super.initState();
    createDirectoryName();
    createImage();
  }

  Future createImage() async {
    File image = await fileOperations.openCamera();
    if (image != null) {
      Cropper cropper = Cropper();
      var imageFile = await cropper.cropImage(image);
      if (imageFile != null) imageFiles.add(imageFile);
    }
    setState(() {});
  }

  void _reCropImage(index) async {
    Cropper cropper = Cropper();
    var image = await cropper.cropImage(imageFiles[index]);
    if (image != null) {
      imageFiles.removeAt(index);
      setState(() {
        imageFiles.insert(index, image);
      });
    }
  }

  Future<void> createDirectoryName() async {
    Directory appDir = await getExternalStorageDirectory();
    docPath = "${appDir.path}/OpenScan ${DateTime.now()}";
  }

  Future<bool> _onBackPressed() async {
    return (await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              title: Text('Discard'),
              titlePadding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              contentPadding: EdgeInsets.fromLTRB(20, 20, 20, 30),
              content: Text(
                'Do you want to discard the documents?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              backgroundColor: primaryColor,
              actions: <Widget>[
                FlatButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                  ),
                ),
                FlatButton(
                  onPressed: () => Navigator.popUntil(
                      context, ModalRoute.withName(HomeScreen.route)),
                  child: Text(
                    'Discard',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        ) ??
        false);
  }

  void _removeImage(int index) {
    setState(() {
      imageFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
          backgroundColor: primaryColor,
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: primaryColor,
            leading: IconButton(
              onPressed: _onBackPressed,
              icon: Icon(
                Icons.arrow_back_ios,
                color: secondaryColor,
              ),
            ),
            title: RichText(
              text: TextSpan(
                text: 'Scan ',
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
          body: ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: ((imageFiles.length) / 2).round(),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    RaisedButton(
                      elevation: 20,
                      color: primaryColor,
                      onPressed: () {},
                      child: FocusedMenuHolder(
                        menuWidth: size.width * 0.44,
                        onPressed: () {
                          showCupertinoDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  elevation: 20,
                                  backgroundColor: primaryColor,
                                  child: Container(
                                    width: size.width * 0.95,
                                    child: Image.file(imageFiles[index * 2]),
                                  ),
                                );
                              });
                        },
                        menuItems: [
                          FocusedMenuItem(
                            title: Text(
                              'Crop',
                              style: TextStyle(color: Colors.black),
                            ),
                            trailingIcon: Icon(Icons.crop, color: Colors.black,),
                            onPressed: () async {
                              int tempIndex = index * 2;
                              _reCropImage(tempIndex);
                            },
                          ),
                          FocusedMenuItem(
                            title: Text('Delete'),
                            trailingIcon: Icon(Icons.delete),
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
                                        'Do you really want to delete image?'),
                                    actions: <Widget>[
                                      FlatButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancel'),
                                      ),
                                      FlatButton(
                                        onPressed: () {
                                          _removeImage(index * 2);
                                          Navigator.pop(context);
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
                              );
                            },
                            backgroundColor: Colors.redAccent,
                          ),
                        ],
                        child: Container(
                          child: Image.file(imageFiles[index * 2]),
                          height: size.height * 0.25,
                          width: size.width * 0.4,
                        ),
                      ),
                    ),
                    if (index * 2 + 1 < imageFiles.length)
                      RaisedButton(
                        elevation: 20,
                        color: primaryColor,
                        onPressed: () {},
                        child: FocusedMenuHolder(
                          menuWidth: size.width * 0.44,
                          onPressed: () {
                            showCupertinoDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  elevation: 20,
                                  backgroundColor: primaryColor,
                                  child: Container(
                                    width: size.width * 0.95,
                                    child:
                                        Image.file(imageFiles[index * 2 + 1]),
                                  ),
                                );
                              },
                            );
                          },
                          menuItems: [
                            FocusedMenuItem(
                              title: Text(
                                'Crop',
                                style: TextStyle(color: Colors.black),
                              ),
                              trailingIcon: Icon(Icons.crop),
                              onPressed: () async {
                                int tempIndex = index * 2 + 1;
                                _reCropImage(tempIndex);
                              },
                            ),
                            FocusedMenuItem(
                              title: Text('Remove'),
                              trailingIcon: Icon(Icons.delete),
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
                                          'Do you really want to delete image?'),
                                      actions: <Widget>[
                                        FlatButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Cancel'),
                                        ),
                                        FlatButton(
                                          onPressed: () {
                                            _removeImage(index * 2 + 1);
                                            Navigator.pop(context);
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
                                );
                              },
                              backgroundColor: Colors.redAccent,
                            ),
                          ],
                          child: Container(
                            child: Image.file(imageFiles[index * 2 + 1]),
                            height: size.height * 0.25,
                            width: size.width * 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: RaisedButton(
              onPressed: () async {
                if (imageFiles.length != 0) {
                  for (int i = 0; i < imageFiles.length; i++) {
                    await fileOperations.saveImage(
                        image: imageFiles[i], i: i + 1, dirName: docPath);
                  }
                }
                await fileOperations.deleteTemporaryFiles();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewDocument(
                      dirPath: docPath,
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
                  "Done",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: secondaryColor,
            onPressed: () async {
              await createImage();
            },
            child: Icon(Icons.camera_alt),
          ),
        ),
      ),
    );
  }
}
