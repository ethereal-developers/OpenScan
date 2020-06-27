import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

//import 'package:camera/camera.dart';
//import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

class ScanDocument extends StatefulWidget {
  static String route = "ScanDocument";
  final image;
  ScanDocument({this.image});

  @override
  _ScanDocumentState createState() => _ScanDocumentState();
}

class _ScanDocumentState extends State<ScanDocument> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Scan Document"),
        ),
        body: Center(
          child: Image.file(widget.image),
        ),
      ),
    );
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
