import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:openscan/core/image_filter/filters/preset_filters.dart';
import 'package:path/path.dart';
import '../../../core/image_filter/filters/filters.dart';
import '../../screens/filter_screen.dart';
import '../../screens/preview_screen.dart';
import 'package:image/image.dart' as imageLib;

class PreviewScreenBottomBar extends StatelessWidget {
  const PreviewScreenBottomBar({
    Key? key,
    required this.cropOnPressed,
    required this.deleteOnPressed,
    required this.filterOnPressed,
    required this.isAppBarVisible,
  }) : super(key: key);

  final Function()? cropOnPressed;
  final Function()? deleteOnPressed;
  final Function()? filterOnPressed;
  final bool isAppBarVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      height: isAppBarVisible ? 60.0 : 0.0,
      child: BottomAppBar(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        elevation: 0,
        child: Container(
          height: 56.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.crop_rounded),
                onPressed: cropOnPressed,
              ),
              IconButton(
                icon: Icon(Icons.delete_rounded),
                onPressed: deleteOnPressed,
              ),
              IconButton(
                icon: Icon(
                  Icons.photo_filter_rounded,
                ),
                onPressed: filterOnPressed,
              ),
              Icon(
                Icons.more_vert_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
