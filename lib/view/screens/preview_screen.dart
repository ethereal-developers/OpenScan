import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/appRouter.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/delete_dialog.dart';
import 'package:openscan/view/extensions.dart';
import 'package:openscan/view/screens/filter_screen.dart';

import '../Widgets/preview/preview_bottom_bar.dart';

class PreviewScreen extends StatefulWidget {
  final int? initialIndex;

  const PreviewScreen({this.initialIndex});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with SingleTickerProviderStateMixin {
  late ValueNotifier<int> _pageNumber;
  late TapDownDetails _doubleTapDetails;
  TransformationController _transformationController =
      TransformationController();
  bool enablePageScroll = true;
  late AnimationController animationController;
  Animation<Matrix4> _matrixAnimation =
      AlwaysStoppedAnimation(Matrix4.identity());
  bool isAppBarVisible = true;
  Widget loader = Center(child: CircularProgressIndicator());
  late PageController pageController;

  void doubleTapImageZoom() async {
    debugPrint(
        (_transformationController.value == Matrix4.identity()).toString());

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
    debugPrint(animationController.status.toString());
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.initialIndex!);
    _pageNumber = ValueNotifier(widget.initialIndex! + 1);
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
    _pageNumber.dispose();
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Theme.of(context).primaryColor,
        body: BlocConsumer<DirectoryCubit, DirectoryState>(
          listener: (context, state) {},
          builder: (context, state) {
            return Stack(
              children: [
                PageView.builder(
                  physics: enablePageScroll
                      ? ClampingScrollPhysics()
                      : NeverScrollableScrollPhysics(),
                  controller: pageController,
                  itemCount: state.imageCount,
                  itemBuilder: (context, index) {
                    GlobalKey imageKey = GlobalKey();

                    return GestureDetector(
                      onDoubleTapDown: (details) {
                        _doubleTapDetails = details;
                      },
                      onDoubleTap: () {
                        doubleTapImageZoom();
                      },
                      onTap: () {
                        setState(() {
                          isAppBarVisible = !isAppBarVisible;
                        });
                      },
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        onInteractionEnd: (details) {
                          _snapToIdentityIfNearlyUnzoomed();
                        },
                        maxScale: 5,
                        child: Container(
                          child: Center(
                            child: Hero(
                              tag: 'hero-image-${index + 1}',
                              child: Image.file(
                                File(state.images![index].imgPath),
                                key: imageKey,
                                frameBuilder: (BuildContext context,
                                    Widget child,
                                    int? frame,
                                    bool wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded) {
                                    return child;
                                  }
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
                      ),
                    );
                  },
                  onPageChanged: (index) {
                    _transformationController.value = Matrix4.identity();
                    setState(() {
                      _pageNumber.value = index + 1;
                    });
                  },
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  height: isAppBarVisible ? 60.0 : 0.0,
                  child: AppBar(
                    elevation: 0,
                    centerTitle: true,
                    backgroundColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.5),
                    title: BlocConsumer<DirectoryCubit, DirectoryState>(
                      listener: (context, state) {},
                      builder: (context, state) {
                        return Container(
                          height: 20,
                          constraints:
                              BoxConstraints(maxWidth: size.width * .7),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              Text(
                                state.dirName!,
                                style: TextStyle().appBarStyle,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_ios),
                      padding: EdgeInsets.fromLTRB(15, 8, 0, 8),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Visibility(
                  visible: isAppBarVisible,
                  child: Positioned.fill(
                    bottom: 65,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        // TODO: [Bug] Fix Page Index- wrong when image is deleted
                        child: Text(
                          '${_pageNumber.value}/${state.imageCount}',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: BlocConsumer<DirectoryCubit, DirectoryState>(
          listener: (context, state) {},
          builder: (context, state) {
            return PreviewScreenBottomBar(
              isAppBarVisible: isAppBarVisible,
              cropOnPressed: () {
                BlocProvider.of<DirectoryCubit>(context).cropImage(
                  context,
                  state.images![pageController.page!.round()],
                );
              },
              deleteOnPressed: () {
                showDialog(
                  context: context,
                  builder: (_) {
                    return DeleteDialog(
                      deleteOnPressed: () async {
                        bool directoryDeleted =
                            await BlocProvider.of<DirectoryCubit>(context)
                                .deleteImage(
                          context,
                          imageToDelete:
                              state.images![pageController.page!.toInt()],
                        );
                        Navigator.pop(context);
                        if (directoryDeleted) {
                          Navigator.popUntil(context,
                              ModalRoute.withName(AppRouter.homeScreen));
                          // Navigator.pop(context);
                          // Navigator.pop(context);
                        }

                        setState(() {
                          if (state.imageCount + 1 == _pageNumber.value) {
                            _pageNumber.value = pageController.page!.toInt();
                          } else
                            _pageNumber.value =
                                pageController.page!.toInt() + 1;

                          debugPrint(
                              'Controller Page: ${pageController.page} : ${state.imageCount} : ${_pageNumber.value}');
                        });
                        // pageIndex = _pageController!.page!.toInt() + 1;
                      },
                    );
                  },
                );
              },
              filterOnPressed: () async {
                if (!isAppBarVisible) {
                  setState(() {
                    isAppBarVisible = true;
                  });
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider<DirectoryCubit>.value(
                      value: BlocProvider.of<DirectoryCubit>(context),
                      child: FilterScreen(
                        pageIndex: pageController.page!.round(),
                      ),
                    ),
                  ),
                );
              },
              moreOnPressed: () {},
            );
          },
        ),
      ),
    );
  }
}
