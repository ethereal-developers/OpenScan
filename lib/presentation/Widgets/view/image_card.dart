import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/core/theme/appTheme.dart';

class ImageCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      children: [
        MaterialButton(
          elevation: 0,
          onLongPress: onLongPressed,
          color: Theme.of(context).primaryColor,
          onPressed: onPressed,
          child: Container(
            child: Image.file(File(image.imgPath)),
            height: size.height * 0.25,
            width: size.width * 0.38,
          ),
        ),
        (image.selected)
            ? Positioned.fill(
                child: GestureDetector(
                  onTap: onPressed,
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
              width: 0.0001,
              height: 0.0001,
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
