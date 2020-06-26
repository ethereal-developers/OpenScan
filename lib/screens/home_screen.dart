import 'package:flutter/material.dart';
import 'package:openscan/screens/scan_document.dart';
import 'package:openscan/screens/view_document.dart';

class HomeScreen extends StatelessWidget {
  static String route = "HomeScreen";

  List<ListTile> getDocuments({@required BuildContext context, int temp}) {
    List<ListTile> documentsList = [];
    for (int i = 0; i < temp; i++) {
      documentsList.add(
        ListTile(
          leading: Icon(Icons.landscape),
          title: Text("Name of the document"),
          subtitle: Text("Date and size of the file"),
          trailing: Icon(Icons.arrow_right),
          onTap: () {
            Navigator.pushNamed(context, ViewDocument.route);
          },
        ),
      );
    }
    return documentsList;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Home"),
        ),
        body: ListView(
          children: getDocuments(context: context ,temp: 10),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, ScanDocument.route);
          },
          child: Icon(Icons.camera),
        ),
      ),
    );
  }
}
