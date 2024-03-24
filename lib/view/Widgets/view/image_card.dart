import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openscan/core/models.dart';

class ImageCard extends StatelessWidget {
  final ImageOS? image;
  final void Function()? onPressed;
  final void Function()? onSelect;

  ImageCard({
    this.image,
    this.onPressed,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      children: [
        MaterialButton(
          elevation: 0,
          color: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onPressed: onPressed,
          child: Container(
            child: Hero(
              tag: 'hero-image-${image!.idx}',
              child: Image.file(File(image!.imgPath)),
            ),
            height: size.height * 0.25,
            width: size.width * 0.38,
          ),
        ),
        (image!.selected)
            ? Positioned.fill(
                child: GestureDetector(
                  onTap: onPressed,
                  child: Container(
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(
                        width: 3,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.3),
                  ),
                ),
              )
            : Container(
                width: 0.0001,
                height: 0.0001,
              ),
        Positioned(
          bottom: 10,
          right: 10,
          child: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            radius: 13,
            child: Text(
              image!.idx.toString(),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
