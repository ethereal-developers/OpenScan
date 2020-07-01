import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

import 'constants.dart';
import 'cropper.dart';

class ImageCard extends StatefulWidget {
  const ImageCard(
      {this.imageFile,
      this.imageWidget,
      this.imageFileEditCallback,
      this.imageFileDeleteCallback});

  final File imageFile;
  final Widget imageWidget;
  final Function imageFileEditCallback;
  final Function imageFileDeleteCallback;

  @override
  _ImageCardState createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  File imageFile;
  Widget imageWidget;
  Function imageFileEditCallback;
  Function imageFileDeleteCallback;

  Image picDispHolder;

  @override
  void initState() {
    super.initState();
    imageFile = widget.imageFile;
    imageWidget = widget.imageWidget;
    imageFileEditCallback = widget.imageFileEditCallback;
    imageFileDeleteCallback = widget.imageFileDeleteCallback;

    picDispHolder = Image.file(
      imageFile,
      scale: 1.7,
    );
  }

  @override
  void dispose() {
    imageFile = null;
  }

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
                    child: picDispHolder,
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
              if (image != null) {
                image.copy(imageFile.path);
                setState(() {
                  picDispHolder = Image.file(
                    imageFile,
                    scale: 1.7,
                  );
                });
                print(picDispHolder);
                print('Cropped');
              }
            },
          ),
          FocusedMenuItem(
            title: Text('Delete'),
            onPressed: () {
              var temp = imageFile;
              imageFile.deleteSync();
              imageFileDeleteCallback(temp);
            },
            backgroundColor: Colors.redAccent,
          ),
        ],
        child: Container(
          child: picDispHolder,
          height: size.height * 0.25,
          width: size.width * 0.4,
        ),
      ),
    );
  }
}
