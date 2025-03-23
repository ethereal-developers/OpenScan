import 'package:flutter/material.dart';
import 'package:openscan/view/screens/about_screen.dart';
import 'package:openscan/view/screens/crop/crop_screen.dart';
import 'package:openscan/view/screens/demo_screen.dart';
import 'package:openscan/view/screens/home_screen.dart';
import 'package:openscan/view/screens/preview_screen.dart';
import 'package:openscan/view/screens/view_screen.dart';
import 'package:openscan/view/screens/camera_screen.dart';

class AppRouter {
  static const String aboutScreen = 'AboutScreen';
  static const String cropScreen = 'CropImage';
  static const String demoScreen = 'DemoScreen';
  static const String homeScreen = 'HomeScreen';
  static const String previewScreen = 'PreviewScreen';
  static const String viewScreen = 'ViewScreen';
  static const String cameraScreen = 'CameraScreen';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case aboutScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: aboutScreen),
          builder: (_) => AboutScreen(),
        );
      case cropScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: cropScreen),
          builder: (_) => CropImage(),
        );
      case demoScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: demoScreen),
          builder: (_) => DemoScreen(),
        );
      case homeScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: homeScreen),
          builder: (_) => HomeScreen(),
        );
      case previewScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: previewScreen),
          builder: (_) => PreviewScreen(),
        );
      case viewScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: viewScreen),
          builder: (_) => ViewScreen(),
        );
      case cameraScreen:
        return MaterialPageRoute(
          settings: RouteSettings(name: cameraScreen),
          builder: (_) => CameraScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: const RouteSettings(name: demoScreen),
          builder: (_) => DemoScreen(),
        );
    }
  }
}
