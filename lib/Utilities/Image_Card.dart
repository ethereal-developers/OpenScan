import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

import 'constants.dart';
import 'cropper.dart';

class ImageCard extends StatelessWidget {
  const ImageCard({this.imageFile, this.imageWidget});

  final File imageFile;
  final Widget imageWidget;

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
            onPressed: () {
              Cropper cropper = Cropper();
              cropper.cropImage(imageFile);
              //TODO: Save cropped image
              print('Cropped');
            },
          ),
          FocusedMenuItem(
              title: Text('Delete'),
              onPressed: () {
                //TODO: Delete image
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
