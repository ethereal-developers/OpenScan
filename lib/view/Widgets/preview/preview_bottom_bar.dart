import 'package:flutter/material.dart';

class PreviewScreenBottomBar extends StatelessWidget {
  const PreviewScreenBottomBar({
    Key? key,
    required this.cropOnPressed,
    required this.moreOnPressed,
    required this.deleteOnPressed,
    required this.filterOnPressed,
    required this.isAppBarVisible,
  }) : super(key: key);

  final bool isAppBarVisible;
  final Function()? cropOnPressed;
  final Function()? moreOnPressed;
  final Function()? deleteOnPressed;
  final Function()? filterOnPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      height: isAppBarVisible ? 60.0 : 0.0,
      child: Container(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomButton(
              icon: Icon(Icons.crop_rounded),
              onPressed: cropOnPressed,
            ),
            BottomButton(
              icon: Icon(Icons.delete_rounded),
              onPressed: deleteOnPressed,
            ),
            BottomButton(
              icon: Icon(Icons.photo_filter_rounded),
              onPressed: filterOnPressed,
            ),
            BottomButton(
              icon: Icon(Icons.more_vert_rounded),
              onPressed: moreOnPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class BottomButton extends StatelessWidget {
  const BottomButton({
    Key? key,
    required this.onPressed,
    required this.icon,
  }) : super(key: key);

  final Icon icon;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: 50,
      elevation: 0,
      highlightElevation: 0,
      color: Colors.transparent,
      splashColor: Colors.transparent,
      child: icon,
      onPressed: onPressed,
    );
  }
}
