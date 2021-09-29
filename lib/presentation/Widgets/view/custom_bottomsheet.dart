import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/presentation/Widgets/view/quality_selector.dart';
import 'package:openscan/presentation/screens/view_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_extend/share_extend.dart';

class CustomBottomSheet extends StatelessWidget {
  final String fileName;
  final Function saveToDevice;
  final Function sharePdf;
  final Function shareImages;
  final Function qualitySelection;
  final String dirPath;

  CustomBottomSheet({
    this.fileName,
    this.saveToDevice,
    this.sharePdf,
    this.shareImages,
    this.qualitySelection,
    this.dirPath,
  });

  @override
  Widget build(BuildContext context) {
    FileOperations fileOperations = FileOperations();
    String selectedFileName;
    int imageQuality = 3;

    return Container(
      color: Theme.of(context).primaryColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(25, 20, 25, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) {
                        return QualitySelector(
                          imageQuality: imageQuality,
                          qualitySelected: (quality) {
                            imageQuality = quality;
                            print('Selected Image Quality: ');
                            Navigator.pop(context);
                            // showModalBottomSheet(
                            //   context: context,
                            //   builder: (context) {
                            //     return CustomBottomSheet();
                            //   },
                            // );
                          },
                        );
                      },
                    );
                  },
                  child: Container(
                    child: Text('Quality'),
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            thickness: 0.2,
            indent: 8,
            endIndent: 8,
            color: Colors.white,
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf_rounded),
            title: Text('Share PDF'),
            onTap: () async {
              if (ViewScreen.enableSelect) {
                // updateSelectedFileName();
              }
              List<ImageOS> selectedImages = [];
              // for (var image in state.images) {
              //   if (ViewDocument.selectedImageIndex.elementAt(image.idx - 1)) {
              //     selectedImages.add(image);
              //   }
              // }
              await fileOperations.saveToAppDirectory(
                context: context,
                fileName:
                    (ViewScreen.enableSelect) ? selectedFileName : fileName,
                // images:
                //     (ViewDocument.enableSelect) ? selectedImages : state.images,
              );
              Directory storedDirectory =
                  await getApplicationDocumentsDirectory();
              ShareExtend.share(
                  '${storedDirectory.path}/${(ViewScreen.enableSelect) ? selectedFileName : fileName}.pdf',
                  'file');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.phone_android_rounded),
            title: Text('Save to device'),
            onTap: () async {
              if (ViewScreen.enableSelect) {
                // updateSelectedFileName();
              }
              List<ImageOS> selectedImages = [];
              // for (var image in state.images) {
              //   if (ViewDocument.selectedImageIndex.elementAt(image.idx - 1)) {
              //     selectedImages.add(image);
              //   }
              // }
              String savedDirectory;
              savedDirectory = await fileOperations.saveToDevice(
                context: context,
                fileName:
                    (ViewScreen.enableSelect) ? selectedFileName : fileName,
                // images:
                //     (ViewDocument.enableSelect) ? selectedImages : state.images,
                quality: imageQuality,
              );
              Navigator.pop(context);
              String displayText;
              (savedDirectory != null)
                  ? displayText = "PDF Saved at\n"
                  : displayText = "Failed to generate pdf. Try Again.";

              Fluttertoast.showToast(msg: displayText);
            },
          ),
          ListTile(
            leading: Icon(Icons.image_rounded),
            title: Text('Share images'),
            onTap: () {
              List<String> selectedImagesPath = [];
              // for (var image in state.images) {
              //   if (ViewDocument.selectedImageIndex.elementAt(image.idx - 1)) {
              //     selectedImagesPath.add(image.imgPath);
              //   }
              // }
              // ShareExtend.shareMultiple(
              //     (ViewDocument.enableSelect)
              //         ? selectedImagesPath
              //         : imageFilesPath,
              //     'file');
              Navigator.pop(context);
            },
          ),
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
  }
}
