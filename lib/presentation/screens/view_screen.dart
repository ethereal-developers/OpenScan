import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/presentation/Widgets/FAB.dart';
import 'package:openscan/presentation/Widgets/delete_dialog.dart';
import 'package:openscan/presentation/Widgets/renameDialog.dart';
import 'package:openscan/presentation/Widgets/view/icon_gesture.dart';
import 'package:openscan/presentation/Widgets/view/image_card.dart';
import 'package:openscan/presentation/extensions.dart';
import 'package:openscan/presentation/screens/preview_screen.dart';
import 'package:reorderables/reorderables.dart';

class ViewScreen extends StatefulWidget {
  static String route = "ViewDocument";
  final bool quickScan;
  final bool fromGallery;

  ViewScreen({
    this.quickScan = false,
    this.fromGallery = false,
  });

  @override
  _ViewScreenState createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  static bool selectionEnabled = false;

  @override
  void initState() {
    super.initState();
    selectionEnabled = false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (selectionEnabled) {
            selectionEnabled = false;
          } else {
            Navigator.pop(context);
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          // key: scaffoldKey,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            leading: selectionEnabled
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 30,
                    ),
                    onPressed: () {
                      BlocProvider.of<DirectoryCubit>(context).resetSelection();
                      setState(() {
                        selectionEnabled = false;
                      });
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
                // print('DirName updated: ${state.dirName}');
              },
              builder: (context, state) {
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) {
                        return RenameDialog(
                          onConfirm: (newName) {
                            BlocProvider.of<DirectoryCubit>(context)
                                .renameDocument(newName);
                          },
                          docTableName: state.dirName!,
                          fileName: state.newName ?? state.dirName!,
                        );
                      },
                    );
                  },
                  child: Text(
                    state.newName ?? state.dirName ?? '',
                    style: TextStyle().appBarStyle.copyWith(
                      shadows: [
                        Shadow(color: Colors.white, offset: Offset(0, -4)),
                      ],
                      color: Colors.transparent,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dashed,
                      decorationThickness: 1,
                      decorationColor: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
            actions: (selectionEnabled)
                ? [
                    IconGestureDetector(
                      icon: Icon(Icons.select_all_rounded),
                      onTap: () {
                        print('select all');
                        BlocProvider.of<DirectoryCubit>(context)
                            .selectAllImages();
                      },
                    ),
                    IconGestureDetector(
                      icon: Icon(Icons.share_rounded),
                      onTap: () {
                        print('selective share');
                      },
                    ),
                    IconGestureDetector(
                      icon: Icon(Icons.delete_rounded),
                      onTap: () {
                        //TODO: 0 images selected: Bug, Snackbar
                        showDialog(
                          context: context,
                          builder: (_) {
                            return DeleteDialog(
                              deleteOnPressed: () {
                                // showDialog(
                                //   context: context,
                                //   builder: (context) {
                                //     return LoadingWidget();
                                //   },
                                // );
                                BlocProvider.of<DirectoryCubit>(context)
                                    .deleteMultipleImages(context);
                                Navigator.pop(context);
                                setState(() {
                                  selectionEnabled = false;
                                });
                              },
                            );
                          },
                        );
                        // Navigator.pop(context);
                      },
                    ),
                  ]
                : [
                    IconGestureDetector(
                      icon: Icon(Icons.check_box_rounded),
                      onTap: () {
                        setState(() {
                          selectionEnabled = true;
                          print('selection Enabled');
                        });
                      },
                    ),
                    IconGestureDetector(
                      icon: Icon(Icons.share_rounded),
                      onTap: () {
                        print('share');
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
                      ? Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: getImageCards(state)!,
                        )
                      : ReorderableWrap(
                          spacing: 10,
                          runSpacing: 10,
                          minMainAxisCount: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: getImageCards(state)!,
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
      ),
    );
  }

  List<Widget>? getImageCards(state) {
    return state.images.map<Widget>((image) {
      return ImageCard(
        image: image,
        onPressed: selectionEnabled
            ? () => BlocProvider.of<DirectoryCubit>(context).selectImage(image)
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider<DirectoryCubit>.value(
                      value: BlocProvider.of<DirectoryCubit>(context),
                      child: PreviewScreen(
                        initialIndex: image.idx - 1,
                      ),
                    ),
                  ),
                ),
        onSelect: () {},
      );
    }).toList();
  }
}
