import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openscan/core/models.dart';

class ImageCard extends StatelessWidget {
  final ImageOS? image;
  final void Function()? onPressed;
  final void Function()? onSelect;

  const ImageCard({
    Key? key,
    this.image,
    this.onPressed,
    this.onSelect,
  }) : super(key: key);

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
              child: FutureBuilder<void>(
                future: precacheImage(FileImage(File(image!.imgPath)), context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return Image.file(
                    File(image!.imgPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading image: $error');
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                      );
                    },
                  );
                },
              ),
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
            : const SizedBox.shrink(),
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
