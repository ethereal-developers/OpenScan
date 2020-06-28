import 'package:flutter/material.dart';
import 'package:openscan/screens/share_document.dart';

class ViewDocument extends StatefulWidget {
  static String route = "ViewDocument";

  @override
  _ViewDocumentState createState() => _ViewDocumentState();
}

class _ViewDocumentState extends State<ViewDocument> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("View Document"),
        ),
        body: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Name of the document",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17.0),
              ),
            ),
            FlatButton(
              // TODO: Implement how to change the name of the document
              onPressed: () {},
              child: Text("Change the name of the document"),
            ),
            Placeholder(),
            Placeholder(),
            FlatButton(
              onPressed: () {
                Navigator.pushNamed(context, ShareDocument.route);
              },
              child: Text("Share Document as PDF"),
              color: Colors.green,
            )
          ],
        ),
      ),
    );
  }
}
