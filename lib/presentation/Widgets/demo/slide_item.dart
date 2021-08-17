import 'package:flutter/material.dart';

class SlideItem extends StatelessWidget {
  final int index;

  SlideItem(this.index);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: size.width,
          height: size.height * 0.78,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(slideList[index].imageUrl),
            ),
          ),
        ),
      ],
    );
  }
}

class Slide {
  final String imageUrl;

  Slide({
    @required this.imageUrl,
  });
}

final slideList = [
  Slide(
    imageUrl: 'assets/home.jpg',
  ),
  Slide(
    imageUrl: 'assets/view_doc_01.jpg',
  ),
  Slide(
    imageUrl: 'assets/view_doc_02.jpg',
  ),
  Slide(
    imageUrl: 'assets/view_doc_03.jpg',
  ),
  Slide(
    imageUrl: 'assets/view_doc_05.jpg',
  ),
  Slide(
    imageUrl: 'assets/view_doc_04.jpg',
  ),
];
