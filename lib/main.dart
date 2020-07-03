import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:openscan/screens/about_screen.dart';

import 'package:openscan/screens/home_screen.dart';
import 'package:openscan/screens/scan_document.dart';
import 'package:openscan/screens/share_document.dart';
import 'package:openscan/screens/view_document.dart';
import 'package:openscan/screens/about_screen.dart';
import 'package:openscan/Utilities/constants.dart';
import 'screens/splash_screen.dart';
import 'package:flutter/services.dart';

void main() async {
  // SystemChrome.setPreferredOrientations(
  //   [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp],
  // );
  // SystemChrome.setSystemUIOverlayStyle(
  //   SystemUiOverlayStyle(
  //     systemNavigationBarColor: primaryColor,
  //     systemNavigationBarIconBrightness: Brightness.light,
  //     statusBarColor: primaryColor,
  //     statusBarBrightness: Brightness.light,
  //   ),
  // );
  runApp(OpenScan());
}

class OpenScan extends StatefulWidget {
  @override
  _OpenScanState createState() => _OpenScanState();
}

class _OpenScanState extends State<OpenScan> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: SplashScreen.route,
      routes: {
        SplashScreen.route: (context) => SplashScreen(),
        HomeScreen.route: (context) => HomeScreen(),
        ViewDocument.route: (context) => ViewDocument(),
        ScanDocument.route: (context) => ScanDocument(),
        ShareDocument.route: (context) => ShareDocument(),
        AboutScreen.route: (context) => AboutScreen(),
      },
    );
  }
}
