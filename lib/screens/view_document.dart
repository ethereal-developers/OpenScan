import 'package:flutter/material.dart';

class ViewDocument extends StatefulWidget {

  static String route = "ViewDocument";

  @override
  _ViewDocumentState createState() => _ViewDocumentState();
}

class _ViewDocumentState extends State<ViewDocument> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('ViewDocument'),
    );
  }
}