import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openscan/core/constants.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/presentation/Widgets/delete_dialog.dart';
import 'package:openscan/presentation/screens/home_screen.dart';
import 'package:openscan/presentation/screens/view_document.dart';

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
    return Container(
      color: primaryColor,
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
                  onTap: qualitySelection,
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
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Share PDF'),
            onTap: sharePdf,
          ),
          ListTile(
            leading: Icon(Icons.phone_android),
            title: Text('Save to device'),
            onTap: saveToDevice,
          ),
          ListTile(
            leading: Icon(Icons.image),
            title: Text('Share images'),
            onTap: shareImages,
          ),
          (enableSelect)
              ? Container()
              : ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    'Delete All',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) {
                        return DeleteDialog(
                          deleteOnPressed: () {
                            Directory(dirPath).deleteSync(recursive: true);
                            DatabaseHelper()..deleteDirectory(dirPath: dirPath);
                            Navigator.popUntil(
                              context,
                              ModalRoute.withName(HomeScreen.route),
                            );
                          },
                          cancelOnPressed: () => Navigator.pop(context),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
