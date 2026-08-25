import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/appRouter.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/os/os_components.dart';
import 'package:openscan/view/Widgets/preview/preview_bottom_bar.dart';
import 'package:openscan/view/screens/filter_screen.dart';

/// Full-bleed page preview. Tapping the page hides the chrome entirely so
/// the scan is the only thing on screen; every control comes back on the
/// next tap.
class PreviewScreen extends StatefulWidget {
  final int? initialIndex;

  const PreviewScreen({this.initialIndex});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with SingleTickerProviderStateMixin {
  late TapDownDetails _doubleTapDetails;
  final TransformationController _transformationController =
      TransformationController();
  bool enablePageScroll = true;
  late AnimationController animationController;
  Animation<Matrix4> _matrixAnimation =
      AlwaysStoppedAnimation(Matrix4.identity());
  bool _chromeVisible = true;
  int _pageNumber = 1;
  late PageController pageController;

  void doubleTapImageZoom() async {
    final position = _doubleTapDetails.localPosition;

    if (_transformationController.value == Matrix4.identity()) {
      _matrixAnimation = Matrix4Tween(
              begin: Matrix4.identity(),
              end: Matrix4.translationValues(-position.dx, -position.dy, 0)
                ..scaleByDouble(2.0, 2.0, 2.0, 1.0))
          .chain(CurveTween(curve: Curves.decelerate))
          .animate(animationController);

      await animationController.forward();

      setState(() {
        enablePageScroll = false;
      });
    } else {
      if (animationController.isDismissed) {
        _matrixAnimation = Matrix4Tween(
          begin: _transformationController.value,
          end: Matrix4.identity(),
        )
            .chain(CurveTween(curve: Curves.decelerate))
            .animate(animationController);

        await animationController.forward();
      }

      _matrixAnimation = Matrix4Tween(
        begin: Matrix4.identity(),
        end: _transformationController.value,
      )
          .chain(CurveTween(curve: Curves.decelerate))
          .animate(animationController);

      await animationController.reverse();

      setState(() {
        enablePageScroll = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.initialIndex ?? 0);
    _pageNumber = (widget.initialIndex ?? 0) + 1;
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    )..addListener(() {
        _transformationController.value = _matrixAnimation.value;
      });
    _transformationController.addListener(_handleTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformationChanged);
    _transformationController.dispose();
    animationController.dispose();
    pageController.dispose();
    super.dispose();
  }

  // Re-enables page swiping as soon as the image is back to its unzoomed
  // scale, instead of only checking once when a pinch gesture ends - which
  // left swipe-to-next-image permanently broken after any zoom-in/zoom-out.
  void _handleTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final shouldEnablePageScroll = scale <= 1.01;
    if (shouldEnablePageScroll != enablePageScroll) {
      setState(() {
        enablePageScroll = shouldEnablePageScroll;
      });
    }
  }

  // A pinch-out gesture rarely lands on exactly scale 1.0 - it's easy to
  // stop at, say, 1.08x without noticing. Snap the rest of the way back to
  // identity whenever the user ends a gesture "nearly" unzoomed, so a pinch
  // out reliably restores swiping the same way double-tap does.
  Future<void> _snapToIdentityIfNearlyUnzoomed() async {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale > 1.0 && scale <= 1.15) {
      _matrixAnimation = Matrix4Tween(
        begin: _transformationController.value,
        end: Matrix4.identity(),
      ).chain(CurveTween(curve: Curves.decelerate)).animate(animationController);

      animationController.value = 0;
      await animationController.forward();
    }
  }

  int get _currentIndex =>
      pageController.hasClients && pageController.page != null
          ? pageController.page!.round()
          : (widget.initialIndex ?? 0);

  void _confirmDelete(DirectoryState state) {
    showDialog(
      context: context,
      builder: (_) => OSDialog(
        title: 'Delete page?',
        message: "This can't be undone.",
        confirmLabel: 'Delete',
        destructive: true,
        onConfirm: () async {
          final index = _currentIndex;
          Navigator.pop(context); // the dialog
          final directoryDeleted =
              await BlocProvider.of<DirectoryCubit>(context)
                  .deleteImage(context, imageToDelete: state.images![index]);
          if (!mounted) return;
          if (directoryDeleted) {
            Navigator.popUntil(
                context, ModalRoute.withName(AppRouter.homeScreen));
            return;
          }
          setState(() {
            _pageNumber = (index + 1).clamp(1, state.imageCount);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: OSColors.chromeBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: OSColors.chromeBackground,
        body: BlocBuilder<DirectoryCubit, DirectoryState>(
          builder: (context, state) {
            if ((state.images ?? const []).isEmpty) {
              return const SizedBox.shrink();
            }

            return Stack(
              children: [
                PageView.builder(
                  physics: enablePageScroll
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  controller: pageController,
                  itemCount: state.imageCount,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onDoubleTapDown: (details) =>
                          _doubleTapDetails = details,
                      onDoubleTap: doubleTapImageZoom,
                      onTap: () =>
                          setState(() => _chromeVisible = !_chromeVisible),
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        onInteractionEnd: (_) =>
                            _snapToIdentityIfNearlyUnzoomed(),
                        maxScale: 5,
                        child: Center(
                          child: Hero(
                            tag: 'hero-image-${index + 1}',
                            child: Image.file(
                              File(state.images![index].imgPath),
                              frameBuilder: (context, child, frame, sync) {
                                if (sync) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  onPageChanged: (index) {
                    _transformationController.value = Matrix4.identity();
                    setState(() => _pageNumber = index + 1);
                  },
                ),
                _topChrome(state),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: PreviewScreenBottomBar(
                    visible: _chromeVisible,
                    cropOnPressed: () =>
                        BlocProvider.of<DirectoryCubit>(context).cropImage(
                      context,
                      state.images![_currentIndex],
                    ),
                    deleteOnPressed: () => _confirmDelete(state),
                    filterOnPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider<DirectoryCubit>.value(
                            value: BlocProvider.of<DirectoryCubit>(context),
                            child: FilterScreen(pageIndex: _currentIndex),
                          ),
                        ),
                      );
                    },
                    rescanOnPressed: () {
                      // Re-scan adds a fresh capture rather than
                      // overwriting this page — the page it supersedes
                      // stays until the user deletes it deliberately.
                      // Deliberately does not pop first: the camera route
                      // is pushed from this context, which a pop would
                      // have already torn down.
                      BlocProvider.of<DirectoryCubit>(context)
                          .createImage(context, liveScan: true);
                    },
                  ),
                ),
                // Knowing where you are in a 12-page document is worth one
                // small pill even with the chrome hidden — but only then:
                // while the chrome is up the top bar already says it, and
                // showing both reads as two different counters.
                if (!_chromeVisible)
                  Positioned(
                    bottom: OSSpace.xl,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: OSSpace.sm, vertical: OSSpace.xxs + 2),
                        decoration: BoxDecoration(
                          color: OSColors.chromeScrim,
                          borderRadius: BorderRadius.circular(OSRadius.sheet),
                        ),
                        child: Text(
                          '$_pageNumber / ${state.imageCount}',
                          style: OSTypography.caption
                              .copyWith(color: OSColors.chromeOnBackground),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topChrome(DirectoryState state) {
    return IgnorePointer(
      ignoring: !_chromeVisible,
      child: AnimatedOpacity(
        opacity: _chromeVisible ? 1 : 0,
        duration: OSMotion.selection,
        child: Container(
          color: OSColors.chromeScrim,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: OSColors.chromeOnBackground),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    '$_pageNumber / ${state.imageCount}',
                    textAlign: TextAlign.center,
                    style: OSTypography.label
                        .copyWith(color: OSColors.chromeOnBackground),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
