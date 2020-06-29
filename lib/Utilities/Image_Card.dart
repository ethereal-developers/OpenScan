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
    return RaisedButton(
      color: Colors.black,
      child: FocusedMenuHolder(
        menuWidth: MediaQuery.of(context).size.width*0.44,
        onPressed: (){},
        menuItems: [
          FocusedMenuItem(
            title: Text('Crop', style: TextStyle(color: Colors.black),),
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
          child: Image.file(imageFile,scale: 1.7,),
          height: size.height*0.25,
          width: size.width*0.4,
        ),
      ),
    );
  }
}

