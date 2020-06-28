import 'package:flutter/material.dart';

class ShareDocument extends StatefulWidget {
  static String route = "ShareDocument";

  @override
  _ShareDocumentState createState() => _ShareDocumentState();
}

class _ShareDocumentState extends State<ShareDocument> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Share Document"),
        ),
        body: Column(
          // TODO: Center the elements horizontally

          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
              onPressed: () {},
              child: Text("Save to device"),
            ),
            FlatButton(
              onPressed: () {},
              child: Icon(Icons.whatshot),
            ),
            FlatButton(
              onPressed: () {},
              child: Icon(Icons.face),
            ),
            FlatButton(
              onPressed: () {},
              child: Icon(Icons.message),
            ),
          ],
        ),
      ),
    );
  }
}
