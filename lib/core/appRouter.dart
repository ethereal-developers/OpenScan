import 'package:flutter/material.dart';
import 'package:openscan/presentation/screens/about_screen.dart';
import 'package:openscan/presentation/screens/crop_screen.dart';
import 'package:openscan/presentation/screens/demo_screen.dart';
import 'package:openscan/presentation/screens/home_screen.dart';
import 'package:openscan/presentation/screens/preview_screen.dart';
import 'package:openscan/presentation/screens/splash_screen.dart';
import 'package:openscan/presentation/screens/view_screen.dart';

class AppRouter {
  static const String ABOUT_SCREEN = 'AboutScreen';
  static const String CROP_SCREEN = 'CropImage';
  static const String DEMO_SCREEN = 'DemoScreen';
  static const String HOME_SCREEN = 'HomeScreen';
  static const String PREVIEW_SCREEN = 'PreviewScreen';
  static const String SPLASH_SCREEN = 'SplashScreen';
  static const String VIEW_SCREEN = 'ViewScreen';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouter.ABOUT_SCREEN:
        return MaterialPageRoute(
          settings: RouteSettings(name: AppRouter.ABOUT_SCREEN),
          builder: (_) => AboutScreen(),
        );
      case AppRouter.CROP_SCREEN:
        return MaterialPageRoute(
          settings: RouteSettings(name: AppRouter.CROP_SCREEN),
          builder: (_) => CropImage(),
        );
      case AppRouter.DEMO_SCREEN:
        return MaterialPageRoute(
          settings: RouteSettings(name: AppRouter.DEMO_SCREEN),
          builder: (_) => DemoScreen(),
        );
      case AppRouter.HOME_SCREEN:
        return MaterialPageRoute(
          settings: RouteSettings(name: AppRouter.HOME_SCREEN),
          builder: (_) => HomeScreen(),
        );
      case AppRouter.PREVIEW_SCREEN:
        return MaterialPageRoute(
          settings: RouteSettings(name: AppRouter.PREVIEW_SCREEN),
          builder: (_) => PreviewScreen(),
        );
      case AppRouter.SPLASH_SCREEN:
        return MaterialPageRoute(
          settings: RouteSettings(name: AppRouter.SPLASH_SCREEN),
          builder: (_) => SplashScreen(),
        );
      case AppRouter.VIEW_SCREEN:
        return MaterialPageRoute(
          settings: RouteSettings(name: AppRouter.VIEW_SCREEN),
          builder: (_) => ViewScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: RouteSettings(name: AppRouter.DEMO_SCREEN),
          builder: (_) => DemoScreen(),
        );
    }
  }
}
