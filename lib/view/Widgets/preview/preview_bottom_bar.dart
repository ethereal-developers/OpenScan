import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/data/native_android_util.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PreviewScreenBottomBar extends StatefulWidget {
  const PreviewScreenBottomBar({
    Key? key,
    required this.cropOnPressed,
    required this.deleteOnPressed,
    required this.filterOnPressed,
    required this.isAppBarVisible,
    required this.currentPage,
  }) : super(key: key);

  final bool isAppBarVisible;
  final Function()? cropOnPressed;
  final Function()? deleteOnPressed;
  final Function()? filterOnPressed;
  final int currentPage;

  @override
  State<PreviewScreenBottomBar> createState() => _PreviewScreenBottomBarState();
}

class _PreviewScreenBottomBarState extends State<PreviewScreenBottomBar> {
  bool _isRotating = false;
  final DatabaseHelper _database = DatabaseHelper();
  final ValueNotifier<int> _pageNumber = ValueNotifier<int>(1);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.isAppBarVisible ? 100.0 : 0.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BottomButton(
                  icon: const Icon(Icons.crop_rounded),
                  text: 'Crop',
                  onPressed: widget.cropOnPressed,
                ),
                BottomButton(
                  icon: _isRotating
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.rotate_right_rounded),
                  text: 'Rotate',
                  onPressed: _isRotating
                      ? null
                      : () async {
                          setState(() {
                            _isRotating = true;
                          });

                          try {
                            final state = context.read<DirectoryCubit>().state;
                            final currentIndex = state.images!.indexWhere(
                                (img) =>
                                    img.imgPath ==
                                    state.images![widget.currentPage].imgPath);
                            if (currentIndex != -1) {
                              final imagePath =
                                  state.images![currentIndex].imgPath;
                              final directory = await getTemporaryDirectory();
                              final rotatedImagePath =
                                  '${directory.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';

                              // Rotate the image
                              await NativeAndroidUtil.rotate(imagePath, 90);

                              // Create a new file with the rotated image
                              await File(imagePath).copy(rotatedImagePath);

                              // Update the image path in state
                              state.images![currentIndex] =
                                  state.images![currentIndex].copyWith(
                                imgPath: rotatedImagePath,
                              );

                              // Update the database with the new image path
                              await _database.updateImagePath(
                                tableName: state.dirName!,
                                imgPath: rotatedImagePath,
                                idx: state.images![currentIndex].idx!,
                              );

                              // Update the master directory's firstImgPath if this is the first image
                              if (currentIndex == 0) {
                                await _database.updateFirstImagePath(
                                  dirPath: state.dirPath!,
                                  imagePath: rotatedImagePath,
                                );
                              }

                              // Delete the old file
                              await File(imagePath).delete();

                              // Refresh the image by triggering a rebuild
                              context.read<DirectoryCubit>().emitState(state);
                            }
                          } finally {
                            setState(() {
                              _isRotating = false;
                            });
                          }
                        },
                ),
                BottomButton(
                  icon: const Icon(Icons.photo_filter_rounded),
                  text: 'Filters',
                  onPressed: widget.filterOnPressed,
                ),
                BottomButton(
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: Colors.redAccent,
                  ),
                  text: 'Delete',
                  onPressed: widget.deleteOnPressed,
                ),
              ],
            );
          },
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

  final Widget icon;
  final String text;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: 40,
      minWidth: 40,
      padding: EdgeInsets.zero,
      elevation: 0,
      highlightElevation: 0,
      color: Colors.transparent,
      splashColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 24,
            child: icon,
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
      onPressed: onPressed,
    );
  }
}
