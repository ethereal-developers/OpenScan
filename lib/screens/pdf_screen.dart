import 'package:flutter/material.dart';
import 'package:flutter_full_pdf_viewer/full_pdf_viewer_scaffold.dart';
import 'package:openscan/Utilities/constants.dart';

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
        ),
        path: widget.path);
  }
}
