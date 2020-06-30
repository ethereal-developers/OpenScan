import 'dart:io';
import 'dart:ui';
import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:image_cropper/image_cropper.dart';
import 'package:openscan/screens/home_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openscan/Utilities/cropper.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/Utilities/Image_Card.dart';

class ScanDocument extends StatefulWidget {
  static String route = "ScanDocument";

  @override
  _ScanDocumentState createState() => _ScanDocumentState();
}

class _ScanDocumentState extends State<ScanDocument> {
  File imageFile;
  List<File> imageFiles = [];
  String appName = 'OpenScan';
  String appPath;
  String docPath;

  @override
  void initState() {
    super.initState();
    createDirectoryName();
    createImage();
  }

  Future<String> getAppPath() async {
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$appName/');

    if (await _appDocDirFolder.exists()) {
      return _appDocDirFolder.path;
    } else {
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
  }

  var image;
  Future _openCamera() async {
    final _picker = ImagePicker();
    var picture = await _picker.getImage(source: ImageSource.camera);
    setState(() {
      final requiredPicture = File(picture.path);
      print(picture.path);
      image = requiredPicture;
    });
  }

  Future createImage() async{
    await _openCamera();
    if (image != null) {
      Cropper cropper = Cropper();
      var imageFile = await cropper.cropImage(image);
      imageFiles.add(imageFile);
      setState(() {});
    }
  }

  Future<void> createDirectoryName() async {
    Directory appDir = await getExternalStorageDirectory();
    print(appDir);
    docPath = "${appDir.path}/OpenScan ${DateTime.now()}";
  }

  Future<void> _saveImage(File image) async {
    if (await Directory(docPath).exists() != true) {
      new Directory(docPath).create();
    }

    File tempPic = File("$docPath/${imageFiles.length - 1}.png");
    image.copy(tempPic.path);
  }

  Future<void> _deleteTemporaryFiles() async {
    // Delete the temporary files created by the image_picker package
    Directory appDocDir = await getExternalStorageDirectory();
    String appDocPath = "${appDocDir.path}/Pictures/";
    Directory del = Directory(appDocPath);
    if (await del.exists()) {
      del.deleteSync(recursive: true);
    }
    // print(" something ");
    // print(await del.exists());
    new Directory(appDocPath).create();
    // print(await del.exists());
  }

  Future<bool> _onBackPressed() async {
    return (await showDialog(
      context: context,
      builder: (context){
        return AlertDialog(
          title: Text('Do you want to discard the documents?',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600
            ),
          ),
          backgroundColor: primaryColor,
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName(HomeScreen.route)),
              child: Text('Yes'),
            ),
            FlatButton(
              onPressed: () => Navigator.pop(context,false),
              child: Text('No',
                style: TextStyle(color: secondaryColor),
              ),
            ),
          ],
        );
      },) ?? false);
  }

  @override
  void dispose() {
    super.dispose();
    imageFile = null;
    image = null;
    imageFiles = null;
    appName = null;
    appPath = null;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
          backgroundColor: primaryColor,
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: primaryColor,
            leading: IconButton(
              onPressed: _onBackPressed,
              icon: Icon(Icons.arrow_back_ios, color: secondaryColor,),
            ),
            title:RichText(
              text: TextSpan(
                text: 'Scan ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                children: [TextSpan(
                    text: 'Document',
                    style: TextStyle(color: secondaryColor)
                )],
              ),
            ),
          ),
          // TODO: Use Image Card
          body: ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: ((imageFiles.length) / 2).round(),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ImageCard(
                      imageWidget: Image.file(imageFiles[index * 2]),
                    ),
                    if (index * 2 + 1 < imageFiles.length)
                      ImageCard(
                        imageWidget: Image.file(imageFiles[index * 2 + 1]),
                      ),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal:15, vertical: 10),
            child: RaisedButton(
              onPressed: () async {
                await _deleteTemporaryFiles();
                for(var i in imageFiles)
                  await _saveImage(i);
                Navigator.pop(context);
              },
              color: secondaryColor,
              textColor: primaryColor,
              child: Container(
                alignment: Alignment.center,
                height: 55,
                child: Text("Done", style: TextStyle(fontSize: 20),),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: secondaryColor ,
            onPressed: createImage,
            child: Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}


//ListView.separated(
//shrinkWrap: true,
//scrollDirection: Axis.vertical,
//itemCount: imageFiles.length,
//itemBuilder: (context, index) {
//return Container(child: imageFiles[index]);
//},
//separatorBuilder: (BuildContext context, _) => Divider(),
//),