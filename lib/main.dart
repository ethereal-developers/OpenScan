import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:openscan/config/globals.dart';
import 'package:openscan/core/appRouter.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/l10n/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundIsolateBinaryMessenger.ensureInitialized(
      RootIsolateToken.instance!);
  await _initializeCameras();
  runApp(const OpenScan());
}

Future<void> _initializeCameras() async {
  Globals.cameras = await availableCameras();
  debugPrint('Available Cameras:');
  for (final camera in Globals.cameras) {
    debugPrint(
        '${camera.name}: ${camera.lensDirection} (${camera.sensorOrientation})');
  }
}

class OpenScan extends StatelessWidget {
  const OpenScan({Key? key}) : super(key: key);

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: AppTheme.primaryColor,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: AppTheme.primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: AppTheme.primaryColor,
        statusBarBrightness: Brightness.dark,
      ),
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    _configureSystemUI();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.appTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppRouter
          .homeScreen, // Changed to lowercase to match Dart naming conventions
      onGenerateRoute: AppRouter.onGenerateRoute,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.all,
    );
  }
}
