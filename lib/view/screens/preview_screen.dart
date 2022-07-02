import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/delete_dialog.dart';
import 'package:openscan/view/extensions.dart';

class PreviewScreen extends StatefulWidget {
  final int? initialIndex;

  const PreviewScreen({this.initialIndex});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  PageController? _pageController;
  int? pageIndex;
  int? currentPageIndex;
  late TapDownDetails _doubleTapDetails;
  TransformationController _controller = TransformationController();
  bool enablePageScroll = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex!);
    pageIndex = widget.initialIndex! + 1;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.5),
          title: BlocConsumer<DirectoryCubit, DirectoryState>(
            listener: (context, state) {},
            builder: (context, state) {
              return Container(
                height: 20,
                constraints: BoxConstraints(maxWidth: size.width * .7),
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
              // return RichText(
              //   text: TextSpan(
              //     text: state.dirName,
              //     style: TextStyle().appBarStyle,
              //   ),
              //   overflow: TextOverflow.ellipsis,
              // );
            },
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            padding: EdgeInsets.fromLTRB(15, 8, 0, 8),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        body: Container(
          child: BlocConsumer<DirectoryCubit, DirectoryState>(
            listener: (context, state) {},
            builder: (context, state) {
              return Stack(
                children: [
                  PageView.builder(
                    physics: enablePageScroll
                        ? ClampingScrollPhysics()
                        : NeverScrollableScrollPhysics(),
                    controller: _pageController,
                    itemCount: state.imageCount,
                    itemBuilder: (context, index) {
                      currentPageIndex = index;
                      return GestureDetector(
                        onDoubleTapDown: (details) {
                          _doubleTapDetails = details;
                        },
                        onDoubleTap: () {
                          if (_controller.value != Matrix4.identity()) {
                            _controller.value = Matrix4.identity();
                            setState(() {
                              enablePageScroll = true;
                            });
                          } else {
                            final position = _doubleTapDetails.localPosition;
                            _controller.value = Matrix4.identity()
                              ..translate(-position.dx, -position.dy)
                              ..scale(2.0);
                            setState(() {
                              enablePageScroll = false;
                            });
                          }
                        },
                        child: InteractiveViewer(
                          transformationController: _controller,
                          onInteractionEnd: (scaleEndDetails) {
                            print(_controller.value.getColumn(0));
                            if (_controller.value.getColumn(0) ==
                                Matrix4.identity().getColumn(0)) {
                              setState(() {
                                enablePageScroll = true;
                              });
                            }
                          },
                          maxScale: 3,
                          child: Container(
                            child: Center(
                              child: Hero(
                                tag: 'hero-image-${index + 1}',
                                child: Image.file(
                                  File(state.images![index].imgPath!),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    onPageChanged: (index) {
                      _controller.value = Matrix4.identity();
                      setState(() {
                        pageIndex = index + 1;
                      });
                    },
                  ),
                  Positioned.fill(
                    bottom: 60,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        // TODO: Fix Page Index- wrong when image is deleted
                        child: Text(
                          '$pageIndex/${state.imageCount}',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          elevation: 0,
          child: BlocConsumer<DirectoryCubit, DirectoryState>(
            listener: (context, state) {},
            builder: (context, state) {
              return Container(
                height: 56.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // IconButton(onPressed: (){}, icon: Icon(Icons.)),
                    IconButton(
                      icon: Icon(Icons.crop_rounded),
                      onPressed: () {
                        BlocProvider.of<DirectoryCubit>(context).cropImage(
                          context,
                          state.images![_pageController!.page!.toInt()],
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return DeleteDialog(
                              deleteOnPressed: () {
                                BlocProvider.of<DirectoryCubit>(context)
                                    .deleteImage(
                                  context,
                                  imageToDelete: state
                                      .images![_pageController!.page!.toInt()],
                                );
                                Navigator.pop(context);
                                setState(() {
                                  pageIndex = currentPageIndex;
                                });
                                // pageIndex = _pageController!.page!.toInt() + 1;
                              },
                            );
                          },
                        );
                      },
                    ),
                    Icon(
                      Icons.more_vert_rounded,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
