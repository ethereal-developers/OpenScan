import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/data/native_android_util.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/core/data/database_helper.dart';
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
  final VoidCallback? cropOnPressed;
  final VoidCallback? deleteOnPressed;
  final VoidCallback? filterOnPressed;
  final int currentPage;

  @override
  State<PreviewScreenBottomBar> createState() => _PreviewScreenBottomBarState();
}

class _PreviewScreenBottomBarState extends State<PreviewScreenBottomBar>
    with SingleTickerProviderStateMixin {
  bool _isRotating = false;
  final DatabaseHelper _database = DatabaseHelper();

  late final AnimationController _controller;
  late final Animation<double> _sizeFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sizeFactor = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.isAppBarVisible) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant PreviewScreenBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAppBarVisible != widget.isAppBarVisible) {
      if (widget.isAppBarVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _rotateCurrent() async {
    if (_isRotating) return;
    setState(() => _isRotating = true);

    try {
      final state = context.read<DirectoryCubit>().state;
      final currentIndex = state.images!.indexWhere(
        (img) => img.imgPath == state.images![widget.currentPage].imgPath,
      );
      if (currentIndex == -1) return;

      final imagePath = state.images![currentIndex].imgPath;
      final directory = await getTemporaryDirectory();
      final rotatedImagePath =
          '${directory.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Rotate original in place.
      await NativeAndroidUtil.rotate(imagePath, 90);

      // Copy rotated content to a new temp path for your app's state.
      await File(imagePath).copy(rotatedImagePath);

      // Update in-memory state and DB.
      state.images![currentIndex] =
          state.images![currentIndex].copyWith(imgPath: rotatedImagePath);

      await _database.updateImagePath(
        tableName: state.dirName!,
        imgPath: rotatedImagePath,
        idx: state.images![currentIndex].idx!,
      );

      if (currentIndex == 0) {
        await _database.updateFirstImagePath(
          dirPath: state.dirPath!,
          imagePath: rotatedImagePath,
        );
      }

      // Remove old file.
      await File(imagePath).delete();

      // Refresh UI.
      context.read<DirectoryCubit>().emitState(state);
    } finally {
      if (mounted) setState(() => _isRotating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _sizeFactor,
        axisAlignment: -1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 8.0,
          ),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              BottomButton(
                icon: const Icon(
                  Icons.crop_rounded,
                  color: Colors.white,
                ),
                text: 'Crop',
                onPressed: widget.cropOnPressed,
              ),
              BottomButton(
                icon: _isRotating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.rotate_right_rounded,
                        color: Colors.white,
                      ),
                text: 'Rotate',
                onPressed: _isRotating ? null : _rotateCurrent,
              ),
              BottomButton(
                icon: const Icon(
                  Icons.photo_filter_rounded,
                  color: Colors.white,
                ),
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
          ),
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
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // No fixed height; use a comfortable minimum that fits icon+label.
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        minimumSize: const Size(64, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24, child: Center(child: icon)),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
