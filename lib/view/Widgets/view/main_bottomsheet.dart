import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/delete_dialog.dart';
import 'package:openscan/view/Widgets/renameDialog.dart';
import 'package:openscan/view/Widgets/view/export_bottomsheet.dart';
import 'package:openscan/view/extensions.dart';
import 'package:openscan/view/screens/home_screen.dart';

class MainBottomSheet extends StatefulWidget {
  final bool imagesSelected;

  const MainBottomSheet({Key? key, this.imagesSelected = false})
      : super(key: key);
  // final String? fileName;
  // final Function? saveToDevice;
  // final Function? sharePdf;
  // final Function? shareImages;
  // final Function? qualitySelection;
  // final String? dirPath;

  // CustomBottomSheet({
  //   this.fileName,
  //   this.saveToDevice,
  //   this.sharePdf,
  //   this.shareImages,
  //   this.qualitySelection,
  //   this.dirPath,
  // });

  @override
  State<MainBottomSheet> createState() => _MainBottomSheetState();
}

class _MainBottomSheetState extends State<MainBottomSheet> {
  @override
  Widget build(BuildContext context) {
    // FileOperations fileOperations = FileOperations();
    // String selectedFileName;
    int imageQuality = 3;
    Size size = MediaQuery.of(context).size;

    return BottomSheet(
      enableDrag: false,
      onClosing: () {},
      builder: (context) {
        return Container(
          color: Theme.of(context).primaryColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(15, 10, 10, 5),
                child: BlocConsumer<DirectoryCubit, DirectoryState>(
                  listener: (context, state) {
                    // print('DirName updated: ${state.dirName}');q
                  },
                  builder: (context, state) {
                    print(state.firstImgPath);
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: Image.file(
                            File(state.firstImgPath!),
                          ).image,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
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
                              child: Row(
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                        maxWidth: size.width * .65),
                                    height: 20,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      children: [
                                        Text(
                                          state.newName ?? state.dirName ?? '',
                                          style: TextStyle()
                                              .appBarStyle
                                              .copyWith(
                                                fontWeight: FontWeight.normal,
                                                shadows: [
                                                  Shadow(
                                                      color: Colors.white,
                                                      offset: Offset(0, -4)),
                                                ],
                                                color: Colors.transparent,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationStyle:
                                                    TextDecorationStyle.dashed,
                                                decorationThickness: 2,
                                                decorationColor: Colors.white,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.edit,
                                    color: Colors.grey,
                                    size: 20,
                                  )
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${state.imageCount} ${(state.imageCount == 1) ? AppLocalizations.of(context)!.image : AppLocalizations.of(context)!.images}',
                              style: TextStyle(fontSize: 14),
                            )
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              // GestureDetector(
              //   onTap: () {
              //     Navigator.pop(context);
              //     showDialog(
              //       context: context,
              //       builder: (context) {
              //         return QualitySelector(
              //           imageQuality: imageQuality,
              //           qualitySelected: (quality) {
              //             imageQuality = quality;
              //             print('Selected Image Quality: ');
              //             Navigator.pop(context);
              // showModalBottomSheet(
              //   context: context,
              //   builder: (context) {
              //     return CustomBottomSheet();
              //   },
              // );
              //           },
              //         );
              //       },
              //     );
              //   },
              //   child: Container(
              //     child: Text(AppLocalizations.of(context)!.quality),
              //     padding:
              //         EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              //     decoration: BoxDecoration(
              //         border: Border.all(color: Colors.white),
              //         borderRadius: BorderRadius.circular(10)),
              //   ),
              // ),
              Divider(
                thickness: 0.2,
                indent: 8,
                endIndent: 8,
                color: Colors.white,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  BottomSheetActivityButton(
                    subtitle: 'Share',
                    icon: Icon(
                      Icons.share_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) {
                          return BlocProvider<DirectoryCubit>.value(
                            value: BlocProvider.of<DirectoryCubit>(context),
                            child: ExportBottomSheet(
                              imagesSelected: true,
                              share: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  BottomSheetActivityButton(
                    subtitle: 'Save to Device',
                    icon: Icon(
                      Icons.folder_rounded,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) {
                          return BlocProvider<DirectoryCubit>.value(
                            value: BlocProvider.of<DirectoryCubit>(context),
                            child: ExportBottomSheet(
                              imagesSelected: true,
                              save: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  BottomSheetActivityButton(
                    subtitle: 'Delete',
                    icon: Icon(
                      Icons.delete_rounded,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      //TODO: 0 images selected: Bug, Snackbar
                      showDialog(
                        context: context,
                        builder: (_) {
                          return DeleteDialog(
                            multipleFiles: true,
                            deleteOnPressed: () {
                              bool returnToHome =
                                  BlocProvider.of<DirectoryCubit>(context)
                                      .deleteSelectedImages(
                                context,
                                deleteAll: !widget.imagesSelected,
                              );
                              if (returnToHome)
                                Navigator.popUntil(context,
                                    ModalRoute.withName(HomeScreen.route));
                              else {
                                Navigator.pop(context);
                                setState(() {});
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 10)

              // ListTile(
              //   leading: Icon(Icons.picture_as_pdf_rounded),
              //   title: Text(AppLocalizations.of(context)!.share_pdf),
              //   onTap: () async {
              //     if (ViewScreen.selectionEnabled) {
              //     updateSelectedFileName();
              //     }
              //     List<ImageOS> selectedImages = [];
              //     for (var image in state.images) {
              //       if (ViewDocument.selectedImageIndex.elementAt(image.idx - 1)) {
              //         selectedImages.add(image);
              //       }
              //     }
              //     await fileOperations.saveToAppDirectory(
              //       context: context,
              //       fileName:
              //           (ViewScreen.selectionEnabled) ? selectedFileName : fileName,
              //     images:
              //         (ViewDocument.enableSelect) ? selectedImages : state.images,
              //     );
              //     Directory storedDirectory =
              //         await getApplicationDocumentsDirectory();
              //     ShareExtend.share(
              //         '${storedDirectory.path}/${(ViewScreen.selectionEnabled) ? selectedFileName : fileName}.pdf',
              //         'file');
              //     Navigator.pop(context);
              //   },
              // ),
              // ListTile(
              //   leading: Icon(Icons.phone_android_rounded),
              //   title: Text(AppLocalizations.of(context)!.save_to_device),
              //   onTap: () async {
              //     Navigator.pop(context);
              //     if (ViewScreen.selectionEnabled) {
              //     updateSelectedFileName();
              //     }
              //     List<ImageOS> selectedImages = [];
              //     for (var image in state.images) {
              //       if (ViewDocument.selectedImageIndex.elementAt(image.idx - 1)) {
              //         selectedImages.add(image);
              //       }
              //     }
              //     String savedDirectory;
              //     savedDirectory = await fileOperations.saveToDevice(
              //       context: context,
              //       fileName:
              //           (ViewScreen.selectionEnabled) ? selectedFileName : fileName,
              //     images:
              //         (ViewDocument.enableSelect) ? selectedImages : state.images,
              //       quality: imageQuality,
              //     );
              //     Navigator.pop(context);
              //     String displayText;
              //     (savedDirectory != null)
              //         ? displayText = "PDF Saved at\n"
              //         : displayText = "Failed to generate pdf. Try Again.";
              //     Fluttertoast.showToast(msg: displayText);
              //   },
              // ),
              // ListTile(
              //   leading: Icon(Icons.image_rounded),
              //   title: Text(AppLocalizations.of(context)!.share_images),
              //   onTap: () {
              //     List<String> selectedImagesPath = [];
              //     for (var image in state.images) {
              //       if (ViewDocument.selectedImageIndex.elementAt(image.idx - 1)) {
              //         selectedImagesPath.add(image.imgPath);
              //       }
              //     }
              //     ShareExtend.shareMultiple(
              //         (ViewDocument.enableSelect)
              //             ? selectedImagesPath
              //             : imageFilesPath,
              //         'file');
              //     Navigator.pop(context);
              //   },
              // ),
              // ListTile(
              //         leading: Icon(
              //           Icons.delete,
              //           color: Colors.redAccent,
              //         ),
              //         title: Text(
              //           'Delete All',
              //           style: TextStyle(color: Colors.redAccent),
              //         ),
              //         onTap: () {
              //           Navigator.pop(context);
              //           showDialog(
              //             context: context,
              //             builder: (context) {
              //               return DeleteDialog(
              //                 deleteOnPressed: () {
              //                   Directory(dirPath).deleteSync(recursive: true);
              //                   DatabaseHelper()..deleteDirectory(dirPath: dirPath);
              //                   Navigator.popUntil(
              //                     context,
              //                     ModalRoute.withName(HomeScreen.route),
              //                   );
              //                 },
              //                 cancelOnPressed: () => Navigator.pop(context),
              //               );
              //             },
              //           );
              //         },
              //       ),
            ],
          ),
        );
      },
    );
  }
}

class BottomSheetActivityButton extends StatelessWidget {
  final Icon icon;
  final Function()? onPressed;
  final String subtitle;

  const BottomSheetActivityButton({
    required this.icon,
    required this.onPressed,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: ShapeDecoration(
              shape: CircleBorder(side: BorderSide(color: Colors.white30)),
            ),
            child: icon,
          ),
          SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
