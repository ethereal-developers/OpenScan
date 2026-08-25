import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:openscan/config/globals.dart';
import 'package:openscan/core/appRouter.dart';
import 'package:openscan/core/settings/app_settings.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/l10n/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    final settings = AppSettings.instance;

    // One listenable drives the whole theme: changing the accent or theme
    // mode in Settings rebuilds MaterialApp and nothing else has to know.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final light = AppTheme.light(settings.accent);
        final dark = AppTheme.dark(settings.accent);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: dark,
          themeMode: settings.themeMode,
          initialRoute: AppRouter.homeScreen,
          onGenerateRoute: AppRouter.onGenerateRoute,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.all,
          builder: (context, child) {
            // Covers routes with no AppBar of their own; every AppBar
            // re-applies the same style via AppBarTheme.systemOverlayStyle,
            // which is what makes a theme switch stick.
            final theme = Theme.of(context);
            SystemChrome.setSystemUIOverlayStyle(
              AppTheme.systemOverlayStyle(
                theme.extension<OSColors>()!,
                theme.brightness,
              ),
            );
            return child!;
          },
        );
      },
    );
  }
}
