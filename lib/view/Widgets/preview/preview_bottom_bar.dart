import 'package:flutter/material.dart';

class PreviewScreenBottomBar extends StatelessWidget {
  const PreviewScreenBottomBar({
    Key? key,
    required this.cropOnPressed,
    required this.deleteOnPressed,
    required this.filterOnPressed,
    required this.isAppBarVisible,
  }) : super(key: key);

  final bool isAppBarVisible;
  final Function()? cropOnPressed;
  final Function()? deleteOnPressed;
  final Function()? filterOnPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      height: isAppBarVisible ? 60.0 : 0.0,
      child: Container(
        padding: EdgeInsets.all(8.0),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomButton(
              icon: Icon(Icons.crop_rounded),
              // TODO: i18n
              text: 'Crop',
              onPressed: cropOnPressed,
            ),
            BottomButton(
              icon: Icon(Icons.rotate_right_rounded),
              // TODO: i18n
              text: 'Rotate',
              onPressed: () {
                // TODO: handle rotate right
              },
            ),
            BottomButton(
              // Add gradient color
              icon: Icon(Icons.photo_filter_rounded),
              // TODO: i18n
              text: 'Filters',
              onPressed: filterOnPressed,
            ),
            BottomButton(
              icon: Icon(
                Icons.delete_rounded,
                color: Colors.redAccent,
              ),
              // TODO: i18n
              text: 'Delete',
              onPressed: deleteOnPressed,
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
    required this.text,
    required this.icon,
  }) : super(key: key);

  final Icon icon;
  final String text;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: 50,
      elevation: 0,
      highlightElevation: 0,
      color: Colors.transparent,
      splashColor: Colors.transparent,
      child: Column(
        children: [
          icon,
          Text(text),
        ],
      ),
      onPressed: onPressed,
    );
  }
}
