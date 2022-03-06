import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/theme/appTheme.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex!);
    pageIndex = widget.initialIndex! + 1;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
          title: BlocConsumer<DirectoryCubit, DirectoryState>(
            listener: (context, state) {},
            builder: (context, state) {
              return RichText(
                text: TextSpan(
                  text: state.dirName,
                  style: TextStyle().appBarStyle,
                ),
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
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
                    controller: _pageController,
                    itemCount: state.imageCount,
                    itemBuilder: (context, index) {
                      return Container(
                        child: Center(
                          child: Image.file(File(state.images![index].imgPath!)),
                        ),
                      );
                    },
                    onPageChanged: (index) {
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
                          color: AppTheme.primaryColor.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
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
          color: AppTheme.primaryColor.withOpacity(0.3),
          elevation: 0,
          child: BlocConsumer<DirectoryCubit, DirectoryState>(
            listener: (context, state) {},
            builder: (context, state) {
              return Container(
                height: 56.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(
                      Icons.edit_rounded,
                    ),
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
