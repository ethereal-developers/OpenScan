import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

import 'constants.dart';
import 'cropper.dart';

class ImageCard extends StatelessWidget {
  const ImageCard(
      {this.imageFile, this.imageWidget, this.imageFileEditCallback});

  final File imageFile;
  final Widget imageWidget;
  final Function imageFileEditCallback;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return RaisedButton(
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
                    child: (imageFile != null)
                        ? Image.file(
                            imageFile,
                            scale: 1.7,
                          )
                        : imageWidget,
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
            onPressed: () async {
              Cropper cropper = Cropper();
              var image = await cropper.cropImage(imageFile);
              // TODO: make the renaming switch between adding a "c" if it isn't present and removing a "c" if it is present in the name of the image
              // eg: if the name of the file is ../OpenScan Datetime/2.jpg, it has to become ../OpenScan Datetime/2c.jpg
              // eg: if the name of the file is ../OpenScan Datetime/2c.jpg, it has to become ../OpenScan Datetime/2.jpg
              File temp = File(
                  imageFile.path.substring(0, imageFile.path.lastIndexOf(".")) +
                      "c.jpg");
              imageFile.deleteSync();
              if (image != null) {
                image.copy(temp.path);
              }
              await imageFileEditCallback();
            },
          ),
          FocusedMenuItem(
              title: Text('Delete'),
              onPressed: () async {
                imageFile.deleteSync();
                await imageFileEditCallback();
              },
              backgroundColor: Colors.redAccent),
        ],
        child: Container(
          child: (imageFile != null)
              ? Image.file(
                  imageFile,
                  scale: 1.7,
                )
              : imageWidget,
          height: size.height * 0.25,
          width: size.width * 0.4,
        ),
      ),
    );
  }
}
