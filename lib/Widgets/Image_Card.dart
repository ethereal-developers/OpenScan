import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scanner_cropper/flutter_scanner_cropper.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:openscan/Utilities/Classes.dart';
import 'package:openscan/Utilities/DatabaseHelper.dart';

import '../Utilities/constants.dart';

class ImageCard extends StatelessWidget {
  final Function imageFileEditCallback;
  final String dirPath;
  final ImageOS imageOS;

  const ImageCard({
    this.imageFileEditCallback,
    this.dirPath,
    this.imageOS,
  });

  @override
  Widget build(BuildContext context) {
    TransformationController _controller = TransformationController();
    print(dirPath);
    DatabaseHelper database = DatabaseHelper();
    Size size = MediaQuery.of(context).size;
    return RaisedButton(
      elevation: 20,
      color: primaryColor,
      onPressed: () {},
      child: FocusedMenuHolder(
        menuWidth: size.width * 0.45,
        onPressed: () {
          //TODO: Change it to stack
          showCupertinoDialog(
            context: context,
            builder: (context) {
              return Dialog(
                elevation: 20,
                backgroundColor: primaryColor,
                child: InteractiveViewer(
                  transformationController: _controller,
                  maxScale: 10,
                  child: GestureDetector(
                    onDoubleTap: () {
                      _controller.value = Matrix4.identity();
                    },
                    child: Container(
                      width: size.width * 0.95,
                      child: Image.file(
                        File(imageOS.imgPath),
                        scale: 1.7,
                      ),
                    ),
                  ),
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
            onPressed: () async {
              String imageFilePath = await FlutterScannerCropper.openCrop({
                'src': imageOS.imgPath,
                'dest': '/data/user/0/com.ethereal.openscan/cache/'
              });
              File image = File(imageFilePath);
              File temp = File(imageOS.imgPath
                      .substring(0, imageOS.imgPath.lastIndexOf(".")) +
                  "c.jpg");
              File(imageOS.imgPath).deleteSync();
              if (image != null) {
                image.copy(temp.path);
              }
              imageFileEditCallback();
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
                            File(imageOS.imgPath).deleteSync();
                            database.deleteImage(
                              imgPath: imageOS.imgPath,
                              tableName: dirPath.substring(dirPath.lastIndexOf("/") + 1),
                            );
                            try {
                              Directory(dirPath).deleteSync(recursive: false);
                              database.deleteDirectory(dirPath: dirPath);
                              Navigator.pop(context);
                            } catch (e) {
                              imageFileEditCallback();
                            }
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
              backgroundColor: Colors.redAccent),
        ],
        child: Container(
          child: Image.file(File(imageOS.imgPath)),
          height: size.height * 0.25,
          width: size.width * 0.4,
        ),
      ),
    );
  }
}
