import 'package:flutter/material.dart';

class AppTheme {
  // static Color backgroundColor = Color(0xFF010101);
  static const Color primaryColor = Color(0xFF111011);
  static const Color secondaryColor = Color(0xFFf37121);

  static final ThemeData appTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: const ColorScheme(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: primaryColor,
      background: primaryColor,
      error: Colors.red,
      onPrimary: secondaryColor,
      onSecondary: primaryColor,
      onSurface: Colors.white,
      onBackground: secondaryColor,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    // brightness: Brightness.dark,
    // iconTheme: IconThemeData(color: Colors.white),
    // textTheme: TextTheme(
    //   subtitle1: TextStyle(color: Colors.white),
    //   subtitle2: TextStyle(color: Colors.white),
    //   bodyText1: TextStyle(color: Colors.white),
    //   bodyText2: TextStyle(color: Colors.white),
    //   caption: TextStyle(color: Colors.white),
    // ),
  );
}
