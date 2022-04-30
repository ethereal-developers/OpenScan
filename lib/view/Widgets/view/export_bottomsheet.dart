import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/view/OSSwitch.dart';
import 'package:openscan/view/extensions.dart';
import 'package:path_provider/path_provider.dart';
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
  double quality = 80;
  FileOperations fileOperations = FileOperations();

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      enableDrag: false,
      onClosing: () {},
      builder: (context) {
        return Container(
          color: Theme.of(context).primaryColor,
          child: Column(
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
                    BlocBuilder<DirectoryCubit, DirectoryState>(
                      builder: (context, state) {
                        return OSSwitch(
                          onPressed: (String value) async {
                            // TODO: File naming convention
                            String fileName = 'OpenScan';

                            if (value == 'PDF') {
                              if (widget.share) {
                                await fileOperations.saveToAppDirectory(
                                  context: context,
                                  imagesSelected: widget.imagesSelected,
                                  fileName: fileName,
                                  images: state.images!,
                                );
                                Directory storedDirectory =
                                    await getApplicationDocumentsDirectory();
                                ShareExtend.share(
                                  '${storedDirectory.path}/$fileName.pdf',
                                  'file',
                                  sharePanelTitle: 'Share',
                                );
                                Navigator.pop(context);
                                Navigator.pop(context);
                              }
                              if (widget.save) {
                                String? savedDirectory;
                                savedDirectory =
                                    await fileOperations.saveToDevice(
                                  context: context,
                                  fileName: fileName,
                                  images: state.images!,
                                  // TODO: Change quality
                                  quality: 2,
                                );
                                Navigator.pop(context);
                                Navigator.pop(context);
                                String displayText;
                                (savedDirectory != null)
                                    ? displayText =
                                        "PDF Saved at\n$savedDirectory"
                                    : displayText =
                                        "Failed to generate pdf. Try Again.";
                                Fluttertoast.showToast(msg: displayText);
                              }
                            } else if (value == 'Image') {
                              if (widget.share) {
                                // TODO: Get images path list
                                // ShareExtend.shareMultiple(,'file',);
                                Navigator.pop(context);
                                Navigator.pop(context);
                              }
                              if (widget.save) {}
                            }
                          },
                          options: ['PDF', 'Image'],
                        );
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
              SizedBox(height: 10),
              Text(
                'Quality',
                style: TextStyle().appBarStyle,
              ),
              Slider(
                min: 0,
                max: 100,
                value: quality,
                divisions: 10,
                label: '${quality.toInt()}%',
                thumbColor: Theme.of(context).colorScheme.secondary,
                activeColor: Theme.of(context).colorScheme.secondary,
                inactiveColor: Colors.grey,
                onChanged: (value) {
                  setState(() {
                    if (quality >= 30) quality = value;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
    //TODO: Close parent bottomsheet
  }
}
