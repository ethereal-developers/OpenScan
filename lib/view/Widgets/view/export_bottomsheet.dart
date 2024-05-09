
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/appRouter.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/view/OSSwitch.dart';
import 'package:openscan/view/extensions.dart';
import 'package:openscan/view/screens/view_screen.dart';
import 'package:share_extend/share_extend.dart';

class ExportBottomSheet extends StatefulWidget {
  final bool imagesSelected;
  final bool share;
  final bool save;
  const ExportBottomSheet({
    Key? key,
    this.share = false,
    this.save = false,
    this.imagesSelected = false,
  }) : super(key: key);

  @override
  State<ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<ExportBottomSheet> {
  double quality = 70;
  FileOperations fileOperations = FileOperations();
  String exportType = 'PDF';

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return BottomSheet(
      enableDrag: false,
      onClosing: () {
        Navigator.popUntil(context, ModalRoute.withName(AppRouter.VIEW_SCREEN));
      },
      builder: (context) {
        return Container(
          color: Theme.of(context).primaryColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Export Document as: ',
                      style: TextStyle().appBarStyle,
                    ),
                    OSSwitch(
                      options: ['PDF', 'Image'],
                      onPressed: (String value) {
                        exportType = value;
                      },
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
              SizedBox(height: 20),
              Text(
                'Quality',
                style: TextStyle().appBarStyle,
              ),
              Slider(
                min: 30,
                max: 100,
                value: quality,
                divisions: 7,
                label: '${quality.toInt()}%',
                thumbColor: Theme.of(context).colorScheme.secondary,
                activeColor: Theme.of(context).colorScheme.secondary,
                inactiveColor: Colors.grey,
                onChanged: (value) {
                  setState(() {
                    quality = value;
                  });
                },
              ),
              SizedBox(height: 30),
              BlocBuilder<DirectoryCubit, DirectoryState>(
                builder: (context, state) {
                  return MaterialButton(
                    height: 50,
                    minWidth: size.width * 0.7,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Theme.of(context).colorScheme.secondary,
                    child: Text(
                      widget.share ? 'Share' : 'Save',
                      style: TextStyle().appBarStyle.copyWith(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    splashColor: Colors.transparent,
                    onPressed: () async {
                      // TODO: Change file naming convention - spl chars
                      String fileName = 'OpenScan';

                      if (exportType == 'PDF') {
                        if (widget.share) {
                          String? fileNameWithPath = await fileOperations
                              .saveToAppDirectory(
                                context: context,
                                imagesSelected: widget.imagesSelected,
                                fileName: fileName,
                                images: state.images!,
                              );
                          debugPrint('Filename => $fileNameWithPath');

                          if (fileNameWithPath != null) {
                            ShareExtend.share(
                              fileNameWithPath,
                              'file',
                              sharePanelTitle: 'Share',
                            );
                            Navigator.pop(context);
                            Navigator.pop(context);
                          } else {
                            // Fluttertoast.showToast(
                            //     msg: "Failed to generate pdf. Try Again.");
                          }
                        }
                        if (widget.save) {
                          String? fileNameWithPath;
                          fileNameWithPath = await fileOperations.saveToDevice(
                            context: context,
                            fileName: fileName,
                            images: state.images!,
                            // TODO: Change quality
                            quality: 2,
                          );
                          Navigator.pop(context);
                          Navigator.pop(context);

                          String displayText;
                          (fileNameWithPath != null)
                              ? displayText = "PDF Saved at\n"
                              : displayText =
                                  "Failed to generate pdf. Try Again.";
                          // Fluttertoast.showToast(msg: displayText);
                        }
                      } else if (exportType == 'Image') {
                        if (widget.share) {
                          // TODO: Get images path list
                          // ShareExtend.shareMultiple(,'file',);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                        if (widget.save) {
                          // TODO: Save images to device
                        }
                      }
                    },
                  );
                },
              ),
              SizedBox(height: 30),
            ],
          ),
        );
      },
    );
    //TODO: Close parent bottomsheet
  }
}
