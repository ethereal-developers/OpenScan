import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/screens/about_screen.dart';
import 'package:openscan/screens/getting_started_screen.dart';
import 'package:openscan/screens/home_screen.dart';
import 'package:openscan/screens/loading_screen.dart';
import 'package:openscan/screens/view_document.dart';

import 'screens/splash_screen.dart';

void main() async {
  runApp(OpenScan());
}

class OpenScan extends StatefulWidget {
  @override
  _OpenScanState createState() => _OpenScanState();
}

class _OpenScanState extends State<OpenScan> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: primaryColor,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: primaryColor,
      statusBarBrightness: Brightness.light,
    ));
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: SplashScreen.route,
      routes: {
        SplashScreen.route: (context) => SplashScreen(),
        GettingStartedScreen.route: (context) => GettingStartedScreen(),
        LoadingScreen.route: (context) => LoadingScreen(),
        HomeScreen.route: (context) => HomeScreen(),
        ViewDocument.route: (context) => ViewDocument(),
        AboutScreen.route: (context) => AboutScreen(),
      },
    );
  }
}
