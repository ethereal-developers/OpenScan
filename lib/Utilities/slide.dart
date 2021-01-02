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
