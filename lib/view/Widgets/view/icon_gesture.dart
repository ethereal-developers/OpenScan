import 'package:flutter/material.dart';

class IconGestureDetector extends StatelessWidget {
  final Icon? icon;
  final void Function()? onTap;

  const IconGestureDetector({this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: icon,
      ),
      onTap: onTap,
    );
  }
}