import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scanner_cropper/flutter_scanner_cropper.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:openscan/Utilities/Classes.dart';
import 'package:openscan/Utilities/DatabaseHelper.dart';
import 'package:path_provider/path_provider.dart';

import '../Utilities/constants.dart';
import '../screens/view_document.dart';

class ImageCard extends StatefulWidget {
  final Function fileEditCallback;
  final DirectoryOS directoryOS;
  final ImageOS imageOS;
  final Function selectCallback;
  final Function imageViewerCallback;

  const ImageCard({
    this.fileEditCallback,
    this.directoryOS,
    this.imageOS,
    this.selectCallback,
    this.imageViewerCallback,
  });

  @override
  _ImageCardState createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  DatabaseHelper database = DatabaseHelper();

  selectionOnPressed() {
    setState(() {
      selectedImageIndex[widget.imageOS.idx - 1] = true;
    });
    widget.selectCallback();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      children: [
        RaisedButton(
          elevation: 20,
          color: primaryColor,
          onPressed: () {
            (enableSelect)
                ? selectionOnPressed()
                : widget.imageViewerCallback();
          },
          child: FocusedMenuHolder(
            menuWidth: size.width * 0.45,
            onPressed: () {
              (enableSelect)
                  ? selectionOnPressed()
                  : widget.imageViewerCallback();
            },
            menuItems: [
              FocusedMenuItem(
                title: Text(
                  'Crop',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () async {
                  Directory cacheDir = await getTemporaryDirectory();
                  String imageFilePath = await FlutterScannerCropper.openCrop(
                    src: widget.imageOS.imgPath,
                    dest: cacheDir.path,
                    shouldCompress:
                        widget.imageOS.shouldCompress == 1 ? true : false,
                  );
                  File image = File(imageFilePath);
                  File temp = File(widget.imageOS.imgPath.substring(
                          0, widget.imageOS.imgPath.lastIndexOf(".")) +
                      "c.jpg");
                  File(widget.imageOS.imgPath).deleteSync();
                  if (image != null) {
                    image.copySync(temp.path);
                  }
                  widget.imageOS.imgPath = temp.path;
                  print(temp.path);
                  database.updateImagePath(
                    tableName: widget.directoryOS.dirName,
                    image: widget.imageOS,
                  );
                  if (widget.imageOS.idx == 1) {
                    database.updateFirstImagePath(
                      imagePath: widget.imageOS.imgPath,
                      dirPath: widget.directoryOS.dirPath,
                    );
                  }
                  if (widget.imageOS.shouldCompress == 1) {
                    database.updateShouldCompress(
                      image: widget.imageOS,
                      tableName: widget.directoryOS.dirName,
                    );
                  }
                  widget.fileEditCallback();
                },
                trailingIcon: Icon(
                  Icons.crop,
                  color: Colors.black,
                ),
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
                        content: Text('Do you really want to delete image?'),
                        actions: <Widget>[
                          FlatButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          FlatButton(
                            onPressed: () {
                              File(widget.imageOS.imgPath).deleteSync();
                              database.deleteImage(
                                imgPath: widget.imageOS.imgPath,
                                tableName: widget.directoryOS.dirName,
                              );
                              database.updateImageCount(
                                tableName: widget.directoryOS.dirName,
                              );
                              try {
                                Directory(widget.directoryOS.dirPath)
                                    .deleteSync(recursive: false);
                                database.deleteDirectory(
                                    dirPath: widget.directoryOS.dirPath);
                                Navigator.pop(context);
                              } catch (e) {
                                widget.fileEditCallback();
                              }
                              widget.selectCallback();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.redAccent),
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
              child: Image.file(File(widget.imageOS.imgPath)),
              height: size.height * 0.25,
              width: size.width * 0.395,
            ),
          ),
        ),
        (selectedImageIndex[widget.imageOS.idx - 1] && enableSelect)
            ? Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedImageIndex[widget.imageOS.idx - 1] = false;
                    });
                    widget.selectCallback();
                  },
                  child: Container(
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(
                        width: 3,
                        color: secondaryColor,
                      ),
                    ),
                    color: secondaryColor.withOpacity(0.3),
                  ),
                ),
              )
            : Container(
                width: 0.001,
                height: 0.001,
              ),
        (enableReorder)
            ? Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              )
            : Container(
                width: 0.001,
                height: 0.001,
              ),
      ],
    );
  }
}
