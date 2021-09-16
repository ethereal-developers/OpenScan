import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/core/appRouter.dart';
import 'package:openscan/presentation/screens/about_screen.dart';
import 'package:openscan/presentation/screens/demo_screen.dart';
import 'package:openscan/presentation/screens/home_screen.dart';
import 'package:openscan/presentation/screens/splash_screen.dart';
import 'package:openscan/presentation/screens/view_screen.dart';

import 'core/theme/appTheme.dart';

void main() async {
  runApp(OpenScan());
}

class OpenScan extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: AppTheme.primaryColor,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: AppTheme.primaryColor,
      statusBarBrightness: Brightness.light,
    ));
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: AppTheme.primaryColor,
        accentColor: AppTheme.accentColor,
      ),
      themeMode: ThemeMode.dark,
      initialRoute: AppRouter.SPLASH_SCREEN,
      onGenerateRoute: AppRouter.onGenerateRoute,
      // routes: {
      //   SplashScreen.route: (context) => SplashScreen(),
      //   DemoScreen.route: (context) => DemoScreen(),
      //   HomeScreen.route: (context) => HomeScreen(),
      //   ViewScreen.route: (context) => ViewScreen(),
      //   AboutScreen.route: (context) => AboutScreen(),
      // },
    );
  }
}
