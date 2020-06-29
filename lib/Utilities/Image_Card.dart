import 'dart:io';
import 'package:flutter/material.dart';
import 'package:focused_menu/modals.dart';
import 'package:openscan/screens/view_document.dart';
import 'package:focused_menu/focused_menu.dart';

class ImageCard extends StatelessWidget {
  const ImageCard({
    @required this.imageFile,
    @required this.size,});

  final File imageFile;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return FocusedMenuHolder(
      onPressed: (){},
      menuItems: [
        FocusedMenuItem(
          title: Text('Crop'),
          onPressed: (){
            print('Cropped');
          },
        ),
        FocusedMenuItem(
          title: Text('Delete'),
          onPressed: (){},
          backgroundColor: Colors.redAccent
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Image.file(imageFile,),
        height: size.height*0.25,
        width: size.width*0.4,
      ),
    );
  }
}

