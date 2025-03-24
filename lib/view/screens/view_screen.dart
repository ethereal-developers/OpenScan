import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/FAB.dart';
import 'package:openscan/view/Widgets/renameDialog.dart';
import 'package:openscan/view/Widgets/view/main_bottomsheet.dart';
import 'package:openscan/view/Widgets/view/icon_gesture.dart';
import 'package:openscan/view/Widgets/view/image_card.dart';
import 'package:openscan/view/extensions.dart';
import 'package:openscan/view/screens/preview_screen.dart';
import 'package:reorderables/reorderables.dart';

class ViewScreen extends StatefulWidget {
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
  GlobalKey scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final ScrollController _scrollController = ScrollController();
  final Map<int, Widget> _imageCardCache = {};

  @override
  void initState() {
    super.initState();
    BlocProvider.of<DirectoryCubit>(context).disableSelection();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _imageCardCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (BlocProvider.of<DirectoryCubit>(context)
              .state
              .isSelectionEnabled) {
            BlocProvider.of<DirectoryCubit>(context).resetSelection();
          } else {
            Navigator.pop(context);
            return true;
          }
          return false;
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            leading: BlocBuilder<DirectoryCubit, DirectoryState>(
              builder: (context, state) {
                return state.isSelectionEnabled
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 30,
                        ),
                        padding: const EdgeInsets.fromLTRB(15, 8, 0, 8),
                        onPressed: () {
                          BlocProvider.of<DirectoryCubit>(context)
                              .resetSelection();
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        padding: const EdgeInsets.fromLTRB(15, 8, 0, 8),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      );
              },
            ),
            title: BlocConsumer<DirectoryCubit, DirectoryState>(
              listener: (context, state) {
                // debugPrint('DirName updated: ${state.dirName}');
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
                  child: Container(
                    constraints: BoxConstraints(maxWidth: size.width * .6),
                    height: 20,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Text(
                          state.newName ?? state.dirName ?? '',
                          style: TextStyle().appBarStyle.copyWith(
                                fontWeight: FontWeight.normal,
                                shadows: [
                                  Shadow(
                                      color: Colors.white,
                                      offset: Offset(0, -4)),
                                ],
                                color: Colors.transparent,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dashed,
                                decorationThickness: 1,
                                decorationColor: Colors.white,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            actions: [
              BlocBuilder<DirectoryCubit, DirectoryState>(
                builder: (context, state) {
                  if (state.isSelectionEnabled) {
                    return Row(
                      children: [
                        IconGestureDetector(
                          icon: Icon(Icons.select_all_rounded),
                          onTap: () {
                            debugPrint('select all');
                            BlocProvider.of<DirectoryCubit>(context)
                                .selectAllImages();
                          },
                        ),
                        IconGestureDetector(
                          icon: Icon(Icons.more_vert_rounded),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (_) {
                                return BlocProvider<DirectoryCubit>.value(
                                  value:
                                      BlocProvider.of<DirectoryCubit>(context),
                                  child: MainBottomSheet(
                                    imagesSelected: true,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        IconGestureDetector(
                          icon: Icon(Icons.picture_as_pdf_rounded),
                          onTap: () {
                            // TODO: Implement PDF export functionality
                            debugPrint('Export as PDF');
                          },
                        ),
                        IconGestureDetector(
                          icon: Icon(Icons.more_vert_rounded),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (_) {
                                return BlocProvider<DirectoryCubit>.value(
                                  value:
                                      BlocProvider.of<DirectoryCubit>(context),
                                  child: MainBottomSheet(
                                    showSelectOption: true,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                key: const PageStorageKey('view_screen_scroll'),
                padding: const EdgeInsets.all(10),
                child: BlocConsumer<DirectoryCubit, DirectoryState>(
                  listener: (context, state) {
                    // Clear the image card cache when state changes
                    _imageCardCache.clear();
                  },
                  builder: (context_, state) {
                    if (state.images == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (state.images!.isEmpty) {
                      return const Center(
                        child: Text('No images found'),
                      );
                    }
                    return BlocBuilder<DirectoryCubit, DirectoryState>(
                      builder: (context, state) {
                        return state.isSelectionEnabled
                            ? Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: _getImageCards(state),
                              )
                            : ReorderableWrap(
                                spacing: 10,
                                runSpacing: 10,
                                minMainAxisCount: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: _getImageCards(state),
                                onReorder: (int oldIndex, int newIndex) {
                                  BlocProvider.of<DirectoryCubit>(context_)
                                      .updateImageIndex(oldIndex, newIndex);
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
                      },
                    );
                  },
                ),
              ),
              BlocBuilder<DirectoryCubit, DirectoryState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Processing images...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
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

  List<Widget> _getImageCards(DirectoryState state) {
    if (state.images == null) return [];

    return state.images!.map<Widget>((image) {
      if (_imageCardCache.containsKey(image.idx)) {
        return _imageCardCache[image.idx]!;
      }

      final card = ImageCard(
        key: ValueKey(image.idx),
        image: image,
        onPressed: () {
          if (state.isSelectionEnabled) {
            BlocProvider.of<DirectoryCubit>(context).selectImage(image);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider<DirectoryCubit>.value(
                  value: BlocProvider.of<DirectoryCubit>(context),
                  child: PreviewScreen(
                    initialIndex: (image.idx ?? 1) - 1,
                  ),
                ),
              ),
            );
          }
        },
        onSelect: () {},
      );

      _imageCardCache[image.idx!] = card;
      return card;
    }).toList();
  }
}
