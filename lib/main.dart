import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openscan/config/globals.dart';
import 'package:openscan/core/appRouter.dart';
import 'package:openscan/l10n/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/appTheme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Globals.cameras = await availableCameras();
  print('Cameras => ');
  Globals.cameras.every((cameraDescription) {
    print(
        '${cameraDescription.name} : ${cameraDescription.lensDirection}: ${cameraDescription.sensorOrientation}');
    return true;
  });

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
      // theme: ThemeData.dark().copyWith(colorScheme.secondary: AppTheme.colorScheme.secondary),
      theme: AppTheme.appTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppRouter.HOME_SCREEN,
      onGenerateRoute: AppRouter.onGenerateRoute,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.all,
    );
  }
}
