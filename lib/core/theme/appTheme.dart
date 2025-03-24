import 'package:flutter/material.dart';

class AppTheme {
  // static Color backgroundColor = Color(0xFF010101);
  static const Color primaryColor = Color(0xFF000000); // Pure black background
  static const Color secondaryColor = Color(0xFFf37121); // Orange accent

  static final ThemeData appTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: primaryColor,
    colorScheme: const ColorScheme(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: primaryColor,
      background: primaryColor,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    cardTheme: CardTheme(
      color: primaryColor,
      elevation: 0,
    ),
    iconTheme: IconThemeData(
      color: Colors.white70,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white54),
    ),
  );
}
