import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:image_cropper/image_cropper.dart';

class ScanDocument extends StatefulWidget {
  static String route = "ScanDocument";
  final image;
  ScanDocument({this.image});

  @override
  _ScanDocumentState createState() => _ScanDocumentState();
}

class _ScanDocumentState extends State<ScanDocument> {
  File imageFile;

  @override
  void initState() {
    super.initState();
    imageFile = widget.image;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Scan Document"),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(imageFile),
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: RaisedButton(
                      onPressed: () {
                        _cropImage();
                      },
                      child: Icon(Icons.crop),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: RaisedButton(
                      onPressed: () {},
                      color: Colors.lightGreen,
                      child: Text("Done"),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Null> _cropImage() async {
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]
            : [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,
                CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio16x9
              ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.black45,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        ));
    if (croppedFile != null) {
      setState(() {
        imageFile = croppedFile;
      });
    }
  }
}

//class TakePictureScreen extends StatefulWidget {
//  static String route = "TakePicture";
//  final CameraDescription camera;
//
//  const TakePictureScreen({@required this.camera});
//
//  @override
//  TakePictureScreenState createState() => TakePictureScreenState();
//}
//
//class TakePictureScreenState extends State<TakePictureScreen> {
//  CameraController _controller;
//  Future<void> _initializeControllerFuture;
//
//  @override
//  void initState() {
//    super.initState();
//    _controller = CameraController(
//      widget.camera,
//      ResolutionPreset.medium,
//    );
//
//  }
//
//  @override
//  void dispose() {
//    _controller.dispose();
//    super.dispose();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(title: Text('Take a picture')),
//      body: FutureBuilder<void>(
//        future: _initializeControllerFuture,
//        builder: (context, snapshot) {
//          if (snapshot.connectionState == ConnectionState.done) {
//            return CameraPreview(_controller);
//          } else {
//            return Center(child: CircularProgressIndicator());
//          }
//        },
//      ),
//      floatingActionButton: FloatingActionButton(
//        child: Icon(Icons.camera_alt),
//        onPressed: () async {
//          try {
//            await _initializeControllerFuture;
//            final path = join((await getTemporaryDirectory()).path,'${DateTime.now()}.png',);
//
//            await _controller.takePicture(path);
//
//            Navigator.push(
//              context,
//              MaterialPageRoute(
//                builder: (context) => ScanDocument(imagePath: path),
//              ),
//            );
//          } catch (e) {
//            print(e);
//          }
//        },
//      ),
//    );
//  }
//}
