import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as imageLib;
import 'package:openscan/core/appRouter.dart';
import 'package:openscan/core/image_filter/filters/preset_filters.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/logic/cubit/filter_cubit.dart';
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
  late int _currentPageIndex;
  late TapDownDetails _doubleTapDetails;
  TransformationController _transformationController =
      TransformationController();
  bool enablePageScroll = true;
  late AnimationController animationController;
  Animation<Matrix4> _matrixAnimation =
      AlwaysStoppedAnimation(Matrix4.identity());
  bool isAppBarVisible = true;
  imageLib.Image? imageBytes;
  Widget loader = Center(child: CircularProgressIndicator());
  late PageController pageController;
  bool _isZoomed = false;

  void doubleTapImageZoom() async {
    final position = _doubleTapDetails.localPosition;

    if (!_isZoomed) {
      // Zoom in
      _matrixAnimation = Matrix4Tween(
        begin: Matrix4.identity(),
        end: Matrix4.translationValues(-position.dx, -position.dy, 0)
          ..scale(2.0),
      )
          .chain(CurveTween(curve: Curves.decelerate))
          .animate(animationController);

      await animationController.forward();
      setState(() {
        _isZoomed = true;
        enablePageScroll = false;
      });
    } else {
      // Zoom out
      _matrixAnimation = Matrix4Tween(
        begin: _transformationController.value,
        end: Matrix4.identity(),
      )
          .chain(CurveTween(curve: Curves.decelerate))
          .animate(animationController);

      await animationController.forward();
      setState(() {
        _isZoomed = false;
        enablePageScroll = true;
      });
    }
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    if (_transformationController.value.getColumn(0) !=
        Matrix4.identity().getColumn(0)) {
      setState(() {
        _isZoomed = true;
        enablePageScroll = false;
      });
    } else {
      setState(() {
        _isZoomed = false;
        enablePageScroll = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.initialIndex!);
    _pageNumber = ValueNotifier(widget.initialIndex! + 1);
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        _transformationController.value = _matrixAnimation.value;
      });
  }

  @override
  void dispose() {
    pageController.dispose();
    _pageNumber.dispose();
    animationController.dispose();
    super.dispose();
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
          listener: (context, state) {
            // debugPrint('${state.images![pageController.page!.round()]}');
          },
          builder: (context, state) {
            return Stack(
              children: [
                PageView.builder(
                  physics: enablePageScroll
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  controller: pageController,
                  itemCount: state.imageCount,
                  itemBuilder: (context, index) {
                    GlobalKey imageKey = GlobalKey();
                    // _currentPageIndex = index;

                    // TODO: Apply Future builder
                    // imageBytes = PreviewScreen.previewModel
                    //     .getImageBytes(state.images![index].imgPath);
                    // imageBytes!.getBytes();
                    // imageLib.decodeImage(imageBytes!.getBytes());
                    // imageBytes = imageLib.decodeImage(imageBytes!.getBytes());

                    return GestureDetector(
                      onDoubleTapDown: (details) {
                        _doubleTapDetails = details;
                      },
                      onDoubleTap: doubleTapImageZoom,
                      onTap: () {
                        setState(() {
                          isAppBarVisible = !isAppBarVisible;
                        });
                      },
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        onInteractionEnd: _handleInteractionEnd,
                        maxScale: 5,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
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
                      _isZoomed = false;
                      enablePageScroll = true;
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
                        Theme.of(context).primaryColor.withOpacity(0.5),
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
              ],
            );
          },
        ),
        bottomNavigationBar: BlocConsumer<DirectoryCubit, DirectoryState>(
          listener: (context, state) {},
          builder: (context, state) {
            return PreviewScreenBottomBar(
              isAppBarVisible: isAppBarVisible,
              currentPage: _pageNumber.value - 1,
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

                // debugPrint(_pageNumber.value);
                // debugPrint(state.images![_pageNumber.value - 1]);
                // var image = imageLib.decodeImage(
                //     await File(state.images![_pageNumber.value - 1].imgPath)
                //         .readAsBytes());
                // image = imageLib.copyResize(image!, width: 600);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider<DirectoryCubit>.value(
                          value: BlocProvider.of<DirectoryCubit>(context),
                        ),
                        BlocProvider(
                          create: (context) => FilterCubit(
                            selectedFilter: presetFiltersList[0],
                            cachedFilters: {},
                          ),
                        ),
                      ],
                      child: FilterScreen(
                        pageIndex: pageController.page!.round(),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
