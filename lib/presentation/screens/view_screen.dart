import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/presentation/Widgets/FAB.dart';
import 'package:openscan/presentation/Widgets/view/custom_bottomsheet.dart';
import 'package:openscan/presentation/Widgets/view/image_card.dart';
import 'package:openscan/presentation/Widgets/view/popup_menu_button.dart';
import 'package:openscan/presentation/extensions.dart';
import 'package:openscan/presentation/screens/preview_screen.dart';
import 'package:reorderables/reorderables.dart';

class ViewScreen extends StatefulWidget {
  static String route = "ViewDocument";

  static bool enableSelect = false;
  static bool enableReorder = false;
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
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: WillPopScope(
        onWillPop: () {
          if (ViewScreen.enableSelect || ViewScreen.enableReorder) {
            // setState(() {
            ViewScreen.enableSelect = false;
            // removeSelection();
            ViewScreen.enableReorder = false;
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
                leading: (ViewScreen.enableSelect || ViewScreen.enableReorder)
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 30,
                        ),
                        onPressed: (ViewScreen.enableSelect)
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
                actions: [
                  (ViewScreen.enableSelect)
                      ? IconButton(
                          icon: Icon(
                            Icons.select_all_rounded,
                            color: (enableSelectionIcons)
                                ? Colors.white
                                : Colors.grey,
                          ),
                          onPressed: (enableSelectionIcons)
                              ? () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return CustomBottomSheet();
                                    },
                                  );
                                }
                              : () {},
                        )
                      : IconButton(
                          icon: Icon(Icons.picture_as_pdf_rounded),
                          onPressed: () async {
                            // TODO: Preview PDF
                            // await fileOperations.saveToAppDirectory(
                            //   context: context,
                            //   fileName: fileName,
                            //   images: state.images,
                            // );
                            // Directory storedDirectory =
                            //     await getApplicationDocumentsDirectory();
                            // final result = await OpenFile.open(
                            //     '${storedDirectory.path}/.pdf');
                            // setState(() {
                            // String _openResult =
                            //     "type=${result.type}  message=${result.message}";
                            // print(_openResult);
                            // });
                          },
                        ),
                  CustomPopupMenuButton(
                    onSelected: (value) => handleClick(
                      context,
                      value: value,
                    ),
                    itemsMap: {
                      'Export': Icons.share_rounded,
                      'Reorder': Icons.reorder_rounded,
                      'Delete': Icons.delete_rounded,
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.all(10),
                child: BlocConsumer<DirectoryCubit, DirectoryState>(
                  listener: (context, state) {
                    print('ImageCount => ${state.imageCount}');
                    // if (state.images.every((element) => !element.selected))
                    //   ViewDocument.enableSelect = true;
                    // else
                    //   ViewDocument.enableSelect = false;
                  },
                  builder: (context, state) {
                    if (state.images != null) {
                      return ReorderableWrap(
                        needsLongPressDraggable: false,
                        spacing: 10,
                        runSpacing: 10,
                        minMainAxisCount: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: state.images.map((image) {
                          return ImageCard(
                            image: image,
                            onLongPressed: () {
                              // TODO: Select image
                            },
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BlocProvider<DirectoryCubit>.value(
                                    value: BlocProvider.of<DirectoryCubit>(
                                        context),
                                    child: PreviewScreen(
                                      initialIndex: image.idx - 1,
                                    ),
                                  ),
                                ),
                              );
                            },
                            onReorder: () {},
                            onSelect: () {},
                          );
                        }).toList(),
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
}
