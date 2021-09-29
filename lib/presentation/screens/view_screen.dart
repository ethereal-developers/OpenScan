import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/presentation/Widgets/FAB.dart';
import 'package:openscan/presentation/Widgets/view/custom_bottomsheet.dart';
import 'package:openscan/presentation/Widgets/view/icon_gesture.dart';
import 'package:openscan/presentation/Widgets/view/image_card.dart';
import 'package:openscan/presentation/Widgets/view/popup_menu_button.dart';
import 'package:openscan/presentation/extensions.dart';
import 'package:openscan/presentation/screens/preview_screen.dart';
import 'package:reorderables/reorderables.dart';

class ViewScreen extends StatefulWidget {
  static String route = "ViewDocument";

  // static List<bool> selectedImageIndex = [];

  // final DirectoryOS directoryOS;
  final bool quickScan;
  final bool fromGallery;

  ViewScreen({
    this.quickScan = false,
    // this.directoryOS,
    this.fromGallery = false,
  });

  @override
  _ViewScreenState createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  bool enableSelectionIcons = false;
  static bool selectionEnabled = false;
  static bool reorderEnabled = true;
  List<String> imageFilesPath = [];

  // selectionCallback({ImageOS imageOS}) {
  //   if (ViewDocument.selectedImageIndex.contains(true)) {
  //     setState(() {
  //       enableSelectionIcons = true;
  //     });
  //   } else {
  //     setState(() {
  //       enableSelectionIcons = false;
  //     });
  //   }
  // }
  // void fileEditCallback({ImageOS imageOS}) {
  //   bool isFirstImage = false;
  //   if (imageOS.imgPath == widget.directoryOS.firstImgPath) {
  //     isFirstImage = true;
  //   }
  //   // getDirectoryData(
  //   //   updateFirstImage: isFirstImage,
  //   //   updateIndex: true,
  //   // );
  // }
  // imageViewerCallback({ImageOS imageOS}) {
  //   setState(() {
  //     displayImage = imageOS;
  //     showImage = true;
  //   });
  // }
  // removeSelection() {
  //   setState(() {
  //     ViewDocument.selectedImageIndex =
  //         ViewDocument.selectedImageIndex.map((e) => false).toList();
  //     ViewDocument.enableSelect = false;
  //   });
  // }

  void handleClick(context, {String value}) {
    print(value);
    switch (value) {
      case 'Reorder':
        setState(() {
          reorderEnabled = false;
        });
        break;
      case 'Delete':
        // TODO: Delete Mutiple
        break;
      case 'Export':
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return CustomBottomSheet();
          },
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    reorderEnabled = true;
    selectionEnabled = false;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: WillPopScope(
        onWillPop: () {
          if (selectionEnabled || reorderEnabled) {
            // setState(() {
            selectionEnabled = false;
            // removeSelection();
            reorderEnabled = false;
            // showImage = false;
            // });
          } else {
            Navigator.pop(context);
          }
          return;
        },
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              // key: scaffoldKey,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Theme.of(context).primaryColor,
                leading: (selectionEnabled)
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 30,
                        ),
                        onPressed: (selectionEnabled)
                            ? () {
                                // removeSelection();
                              }
                            : () {
                                // TODO: Revert Reorder

                                // setState(() {
                                //   // Reverting reorder
                                //   directoryImages = [];
                                //   for (var image in initDirectoryImages) {
                                //     directoryImages.add(image);
                                //   }
                                //   enableReorder = false;
                                // });
                              },
                      )
                    : IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                title: BlocConsumer<DirectoryCubit, DirectoryState>(
                  listener: (context, state) {
                    print('DirName updated: ${state.dirName}');
                  },
                  buildWhen: (previousState, state) {
                    if (previousState.dirName != state.dirName) return true;
                    return false;
                  },
                  builder: (context, state) {
                    return Text(
                      state.dirName ?? '',
                      style: TextStyle().appBarStyle,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                actions: (selectionEnabled)
                    ? [
                        IconGestureDetector(
                          icon: Icon(Icons.select_all_rounded),
                          onTap: () {
                            print('select all');
                            // TODO: Select all images @DirectoryCubit
                          },
                        ),
                        IconGestureDetector(
                          icon: Icon(Icons.delete_rounded),
                          onTap: () {
                            print('delete');
                          },
                        ),
                      ]
                    : [
                        IconGestureDetector(
                          icon: Icon(Icons.share_rounded),
                          onTap: () {
                            print('share');
                          },
                        ),
                        IconGestureDetector(
                          icon: Icon(Icons.check_box_rounded),
                          onTap: () {
                            print('select');
                          },
                        ),
                        IconGestureDetector(
                          icon: Icon(Icons.delete_rounded),
                          onTap: () {
                            print('delete');
                          },
                        ),
                      ],
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.all(10),
                child: BlocConsumer<DirectoryCubit, DirectoryState>(
                  listener: (context, state) {},
                  builder: (context, state) {
                    if (state.images != null) {
                      return selectionEnabled
                          ? ReorderableWrap(
                              needsLongPressDraggable: false,
                              spacing: 10,
                              runSpacing: 10,
                              minMainAxisCount: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: getImageCards(state),
                              onReorder: (int oldIndex, int newIndex) {
                                BlocProvider.of<DirectoryCubit>(context)
                                    .onReorderImages(oldIndex, newIndex);
                              },
                              onNoReorder: (int index) {
                                debugPrint(
                                    '${DateTime.now().toString().substring(5, 22)} reorder cancelled. index:');
                              },
                              onReorderStarted: (int index) {
                                debugPrint(
                                    '${DateTime.now().toString().substring(5, 22)} reorder started: index:');
                              },
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: getImageCards(state),
                            );
                    }
                    // TODO: Loading
                    return Container();
                  },
                ),
              ),
              floatingActionButton: FAB(
                normalScanOnPressed: () {
                  BlocProvider.of<DirectoryCubit>(context).createImage(
                    context,
                    quickScan: false,
                  );
                },
                quickScanOnPressed: () {
                  BlocProvider.of<DirectoryCubit>(context).createImage(
                    context,
                    quickScan: true,
                  );
                },
                galleryOnPressed: () {
                  BlocProvider.of<DirectoryCubit>(context).createImage(
                    context,
                    quickScan: false,
                    fromGallery: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> getImageCards(state) {
    return state.images.map<Widget>((image) {
      return ImageCard(
        image: image,
        onLongPressed: () {
          // TODO: Select image
          setState(() {
            selectionEnabled = true;
          });
        },
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider<DirectoryCubit>.value(
                value: BlocProvider.of<DirectoryCubit>(context),
                child: PreviewScreen(
                  initialIndex: image.idx - 1,
                ),
              ),
            ),
          );
        },
        onSelect: () {},
      );
    }).toList();
  }
}
