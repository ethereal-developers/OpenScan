import 'package:flutter/material.dart';

class Slide {
  final String imageUrl;

  Slide({
    @required this.imageUrl,
  });
}
//TODO: Change assets
final slideList = [
  Slide(
    imageUrl: 'assets/home.jpg',
  ),
  Slide(
    imageUrl: 'assets/view1.jpg',
  ),
  Slide(
    imageUrl: 'assets/view2.jpg',
  ),
];
