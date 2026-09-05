import 'package:flutter/material.dart';

/// The six-step type scale from the design doc, mapped onto the Material
/// text theme slots the widgets actually read.
///
/// Plus Jakarta Sans is the specified face. It is not bundled with the app,
/// so [fontFamily] stays null and the platform's default sans is used —
/// swap in the family name here once the font ships in `assets/fonts` and
/// every screen picks it up, because nothing sets a font family locally.
class OSTypography {
  static const String? fontFamily = null;

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.26,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.22,
  );

  static TextTheme textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      displayLarge: display.copyWith(color: onSurface),
      displayMedium: display.copyWith(color: onSurface),
      displaySmall: display.copyWith(color: onSurface),
      headlineLarge: display.copyWith(color: onSurface),
      headlineMedium: title.copyWith(color: onSurface),
      headlineSmall: title.copyWith(color: onSurface),
      titleLarge: title.copyWith(color: onSurface),
      titleMedium: subtitle.copyWith(color: onSurface),
      titleSmall: label.copyWith(color: onSurface),
      bodyLarge: body.copyWith(color: onSurface),
      bodyMedium: body.copyWith(color: onSurface),
      bodySmall: caption.copyWith(color: onSurfaceVariant),
      labelLarge: label.copyWith(color: onSurface),
      labelMedium: label.copyWith(color: onSurfaceVariant),
      labelSmall: caption.copyWith(color: onSurfaceVariant),
    );
  }
}

extension OSTextStyles on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
}
