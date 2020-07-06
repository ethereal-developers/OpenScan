import 'package:flutter/material.dart';

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
    imageUrl: 'assets/scan1.jpg',
  ),
  Slide(
    imageUrl: 'assets/scan2.jpg',
  ),
  Slide(
    imageUrl: 'assets/view1.jpg',
  ),
  Slide(
    imageUrl: 'assets/view2.jpg',
  ),
];
