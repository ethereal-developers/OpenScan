import 'dart:io';
import 'package:flutter/material.dart';
import 'package:openscan/screens/view_document.dart';

class ImageCard extends StatelessWidget {
  const ImageCard({
    @required this.imageFile,
    @required this.size,});

  final File imageFile;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: () {
//        Navigator.pushNamed(context, ViewDocument.route);
      },
      child: Container(
        child: Image.file(imageFile,),
        height: size.height*0.3,
        width: size.width*0.4,
      ),
      color: Colors.transparent,
    );
  }
}

