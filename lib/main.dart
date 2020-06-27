import 'package:flutter/material.dart';

import 'package:openscan/screens/home_screen.dart';
import 'package:openscan/screens/scan_document.dart';
import 'package:openscan/screens/share_document.dart';
import 'package:openscan/screens/view_document.dart';
//import 'package:camera/camera.dart';

void main() async{
//  WidgetsFlutterBinding.ensureInitialized();
//  final cameras = await availableCameras();
//  final firstCamera = cameras.first;
  runApp(OpenScan());
}

class OpenScan extends StatelessWidget {
//  final firstCamera;
//  OpenScan(this.firstCamera);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      initialRoute: HomeScreen.route,
      routes: {
        HomeScreen.route: (context) => HomeScreen(),
        ViewDocument.route: (context) => ViewDocument(),
//        TakePictureScreen.route: (context) => TakePictureScreen(camera: firstCamera,),
        ScanDocument.route: (context) => ScanDocument(),
        ShareDocument.route: (context) => ShareDocument(),
      },
    );
  }
}