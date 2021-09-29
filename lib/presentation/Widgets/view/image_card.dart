import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/core/theme/appTheme.dart';

import '../../screens/view_screen.dart';

class ImageCard extends StatefulWidget {
  final ImageOS image;
  final Function onPressed;
  final Function onLongPressed;
  final Function onSelect;

  ImageCard({
    this.image,
    this.onPressed,
    this.onLongPressed,
    this.onSelect,
  });

  @override
  _ImageCardState createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  DatabaseHelper database = DatabaseHelper();

  // selectionOnPressed() {
  //   setState(() {
  //     ViewDocument.selectedImageIndex[widget.imageOS.idx - 1] = true;
  //   });
  //   widget.selectCallback();
  // }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      children: [
        MaterialButton(
          elevation: 0,
          onLongPress: widget.onLongPressed,
          color: Theme.of(context).primaryColor,
          onPressed: widget.onPressed,
          child: Container(
            child: Image.file(File(widget.image.imgPath)),
            height: size.height * 0.25,
            width: size.width * 0.387,
          ),
        ),
        (widget.image.selected)
            ? Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    // setState(() {
                    //   ViewDocument.selectedImageIndex[widget.imageOS.idx - 1] =
                    //       false;
                    // });
                    // widget.selectCallback();
                  },
                  child: Container(
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(
                        width: 3,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    color: AppTheme.accentColor.withOpacity(0.3),
                  ),
                ),
              )
            : Container(
                width: 0.001,
                height: 0.001,
              ),
        // (enableReorder)
        //     ? Positioned.fill(
        //         child: Container(
        //           color: Colors.transparent,
        //         ),
        //       )
        //     : Container(
        //         width: 0.001,
        //         height: 0.001,
        //       ),
      ],
    );
  }
}
