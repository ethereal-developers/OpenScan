import 'dart:io';

import 'package:flutter/material.dart';

import 'package:directory_picker/directory_picker.dart';
import 'package:images_to_pdf/images_to_pdf.dart';
import 'package:path_provider/path_provider.dart';

class ShareDocument extends StatefulWidget {
  static String route = "ShareDocument";
  final String dirName;

  ShareDocument({this.dirName});

  @override
  _ShareDocumentState createState() => _ShareDocumentState();
}

class _ShareDocumentState extends State<ShareDocument> {
  Directory selectedDirectory;

  File _pdfFile;
  String _status = "Not created";
  FileStat _pdfStat;
  bool _generating = false;

  String dirName;
  List<File> images = [];
  String fileName;

  @override
  void initState() {
    super.initState();
    dirName = widget.dirName;
    Directory(dirName)
        .list(recursive: false, followLinks: false)
        .listen((FileSystemEntity entity) {
      images.add(File(entity.path));
    });
    fileName =
        dirName.substring(dirName.lastIndexOf("/") + 1, dirName.length - 1);
  }

  Future<void> _pickDirectory(BuildContext context) async {
    Directory directory = selectedDirectory;
    if (Platform.isAndroid) {
      directory = Directory("/storage/emulated/0/");
    } else {
      directory = await getExternalStorageDirectory();
    }

    Directory newDirectory = await DirectoryPicker.pick(
        allowFolderCreation: true,
        context: context,
        rootDirectory: directory,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))));

    setState(() {
      selectedDirectory = newDirectory;
    });
  }

  Future<void> displayDialog() async {
    String displayText;

    if (_status.startsWith("PDF Generated"))
      displayText = "Success. File stored in the chosen folder.";
    else if (_status.startsWith("Failed to generate pdf"))
      displayText = "Failed to generate pdf. Try Again.";

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('$displayText'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createPdf() async {
    try {
      this.setState(() => _generating = true);

      final output = File("${selectedDirectory.path}/$fileName.pdf");

      this.setState(() => _status = 'Generating PDF');

      List<Size> dimensionsArr = [];
      int i = 0;
      var decodedImage;

      for (i = 0; i < images.length; i++) {
        decodedImage = await decodeImageFromList(images[i].readAsBytesSync());
        dimensionsArr.add(Size(
            decodedImage.width.toDouble(), decodedImage.height.toDouble()));
      }

      i = 0;
      await ImagesToPdf.createPdf(
        pages: images
            .map(
              (file) => PdfPage(
                imageFile: file,
                size: dimensionsArr[i++],
                compressionQuality: 0.5,
              ),
            )
            .toList(),
        output: output,
      );
      _pdfStat = await output.stat();
      this.setState(() {
        _pdfFile = output;
        _status = 'PDF Generated (${_pdfStat.size ~/ 1024}kb)';
      });
    } catch (e) {
      this.setState(() => _status = 'Failed to generate pdf: $e".');
    } finally {
      this.setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Share Document"),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
              onPressed: () async {
                await _pickDirectory(context);
                await _createPdf();
                displayDialog();
              },
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
