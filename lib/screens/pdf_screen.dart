import 'package:flutter/material.dart';
import 'package:flutter_full_pdf_viewer/full_pdf_viewer_scaffold.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:share_extend/share_extend.dart';

class PDFScreen extends StatefulWidget {
  static String route = 'PDFScreen';

  PDFScreen({this.path});

  final String path;

  @override
  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> {
  @override
  Widget build(BuildContext context) {
    var fileName = widget.path
        .substring(widget.path.lastIndexOf("/") + 1, widget.path.length - 4);
    return PDFViewerScaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
          title: Text(fileName, style: TextStyle(fontSize: 16),),
          actions: <Widget>[
//            IconButton(
//              icon: Icon(Icons.share),
//              onPressed: () {
//                showDialog(
//                    context: context,
//                    builder: (context) {
//                      return AlertDialog(
//                        shape: RoundedRectangleBorder(
//                          borderRadius: BorderRadius.all(
//                            Radius.circular(10),
//                          ),
//                        ),
//                        title: Text('Share as PDF'),
//                        content: TextField(
//                          onChanged: (value) {
//                            fileName = '$value OpenScan';
//                          },
//                          controller: TextEditingController(
//                              text: fileName.substring(8, fileName.length)),
//                          cursorColor: secondaryColor,
//                          textCapitalization: TextCapitalization.words,
//                          decoration: InputDecoration(
//                            prefixStyle: TextStyle(color: Colors.white),
//                            suffixText: ' OpenScan.pdf',
//                            focusedBorder: UnderlineInputBorder(
//                                borderSide: BorderSide(color: secondaryColor)),
//                          ),
//                        ),
//                        actions: <Widget>[
//                          FlatButton(
//                            onPressed: () => Navigator.pop(context),
//                            child: Text('Cancel'),
//                          ),
//                          FlatButton(
//                            onPressed: () async {
//                              ShareExtend.share(
//                                  '/storage/emulated/0/OpenScan/PDF/$fileName.pdf',
//                                  'file');
//                              Navigator.pop(context);
//                            },
//                            child: Text(
//                              'Share',
//                            ),
//                          ),
//                        ],
//                      );
//                    });
//              },
//            ),
          ],
        ),
        path: widget.path);
  }
}
