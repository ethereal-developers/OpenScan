import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/core/appRouter.dart';

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
      systemNavigationBarDividerColor: AppTheme.primaryColor,
      statusBarIconBrightness: Brightness.light,
      statusBarColor: AppTheme.primaryColor,
      statusBarBrightness: Brightness.dark,
    ));
    // SystemChrome.setEnabledSystemUIOverlays([
    //   SystemUiOverlay.bottom,
    //   SystemUiOverlay.top,
    // ]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // theme: ThemeData.dark().copyWith(accentColor: AppTheme.accentColor),
      theme: AppTheme.appTheme,
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
