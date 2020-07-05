import 'package:flutter/material.dart';

import 'package:openscan/Utilities/slide.dart';

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
          height: size.height*0.8,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(slideList[index].imageUrl),
            ),
          ),
        ),
//        SizedBox(
//          height: 40,
//        ),
//        Text(
//          slideList[index].title,
//          style: TextStyle(
//            fontSize: 22,
//            color: Theme.of(context).primaryColor,
//          ),
//        ),
//        SizedBox(
//          height: 10,
//        ),
//        Text(
//          slideList[index].description,
//          textAlign: TextAlign.center,
//        ),
      ],
    );
  }
}
