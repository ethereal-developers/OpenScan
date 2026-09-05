import 'package:flutter/material.dart';

/// Design tokens for the OpenScan redesign.
///
/// The palette is warm white + a single accent: grey neutrals would compete
/// with the actual white pages the app photographs, so every surface is
/// warm-tinted and the accent is the only saturated colour on screen.
/// Everything a screen paints comes from [OSColors]; nothing hard-codes a
/// hex outside this file.

/// Spacing scale (4/8).
class OSSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

/// Corner radii: 8 chips/steppers, 12 buttons/cards, 16 sheets/dialogs,
/// 28 shutter/FAB pill.
class OSRadius {
  static const double chip = 8;
  static const double card = 12;
  static const double sheet = 16;
  static const double pill = 28;
}

/// Durations and curves for the transitions named in the design doc.
class OSMotion {
  static const Duration selection = Duration(milliseconds: 160);
  static const Duration shutter = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration filterToDetail = Duration(milliseconds: 240);
  static const Duration sheet = Duration(milliseconds: 260);
  static const Duration cameraToCrop = Duration(milliseconds: 280);
  static const Duration autoCaptureCue = Duration(milliseconds: 600);

  static const Curve emphasizedDecel = Curves.easeOutCubic;
  static const Curve standardCurve = Curves.easeInOut;
}

/// One accent family: the four tokens that change when the user swaps
/// accent colour, in both themes. Everything else in the palette is fixed.
///
/// Built from a fixed lightness+chroma in OKLCH with hue as the only
/// variable, so any pick clears the same contrast bars. [onAccent] is a
/// near-black ink rather than white for every hue except Deep Blue, which
/// sits dark enough (L 0.40) to need white instead.
class OSAccentFamily {
  final String id;
  final String label;

  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;

  final Color darkAccent;
  final Color darkOnAccent;
  final Color darkAccentContainer;
  final Color darkOnAccentContainer;

  const OSAccentFamily({
    required this.id,
    required this.label,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.darkAccent,
    required this.darkOnAccent,
    required this.darkAccentContainer,
    required this.darkOnAccentContainer,
  });
}

class OSAccents {
  static const OSAccentFamily ember = OSAccentFamily(
    id: 'ember',
    label: 'Ember',
    accent: Color(0xFFF37121),
    onAccent: Color(0xFF1F1500),
    accentContainer: Color(0xFFFFE3CC),
    onAccentContainer: Color(0xFF7A2E00),
    darkAccent: Color(0xFFFF8A3D),
    darkOnAccent: Color(0xFF1A0E00),
    darkAccentContainer: Color(0xFF5A2E0E),
    darkOnAccentContainer: Color(0xFFFFD9B8),
  );

  static const OSAccentFamily teal = OSAccentFamily(
    id: 'teal',
    label: 'Signal Teal',
    accent: Color(0xFF1D9A8E),
    onAccent: Color(0xFF00201C),
    accentContainer: Color(0xFFC9F0EA),
    onAccentContainer: Color(0xFF00453D),
    darkAccent: Color(0xFF3ECBBB),
    darkOnAccent: Color(0xFF00201C),
    darkAccentContainer: Color(0xFF0B4A43),
    darkOnAccentContainer: Color(0xFFB8EDE5),
  );

  static const OSAccentFamily blue = OSAccentFamily(
    id: 'blue',
    label: 'Deep Blue',
    accent: Color(0xFF3E63E0),
    // The one hue that breaks the dark-ink rule: blue sits at L 0.40, so
    // dark-on-accent fails where every other accent passes.
    onAccent: Color(0xFFFFFFFF),
    accentContainer: Color(0xFFDBE2FF),
    onAccentContainer: Color(0xFF1F2E7A),
    darkAccent: Color(0xFF8AA4FF),
    darkOnAccent: Color(0xFF0A1233),
    darkAccentContainer: Color(0xFF24347F),
    darkOnAccentContainer: Color(0xFFDBE2FF),
  );

  static const OSAccentFamily green = OSAccentFamily(
    id: 'green',
    label: 'Meadow Green',
    accent: Color(0xFF34995A),
    onAccent: Color(0xFF04170C),
    accentContainer: Color(0xFFCFF0DC),
    onAccentContainer: Color(0xFF0F4A29),
    darkAccent: Color(0xFF5FC685),
    darkOnAccent: Color(0xFF04170C),
    darkAccentContainer: Color(0xFF12492A),
    darkOnAccentContainer: Color(0xFFCFF0DC),
  );

  static const OSAccentFamily violet = OSAccentFamily(
    id: 'violet',
    label: 'Violet',
    accent: Color(0xFFB85CF0),
    onAccent: Color(0xFF230236),
    accentContainer: Color(0xFFF2DBFF),
    onAccentContainer: Color(0xFF551A79),
    darkAccent: Color(0xFFCE8CFF),
    darkOnAccent: Color(0xFF230236),
    darkAccentContainer: Color(0xFF4A1A6B),
    darkOnAccentContainer: Color(0xFFF2DBFF),
  );

  static const OSAccentFamily crimson = OSAccentFamily(
    id: 'crimson',
    label: 'Crimson',
    accent: Color(0xFFE0533F),
    onAccent: Color(0xFF2E0500),
    accentContainer: Color(0xFFFFDBD3),
    onAccentContainer: Color(0xFF7A1D0F),
    darkAccent: Color(0xFFFF8A76),
    darkOnAccent: Color(0xFF2E0500),
    darkAccentContainer: Color(0xFF6B2216),
    darkOnAccentContainer: Color(0xFFFFDBD3),
  );

  static const List<OSAccentFamily> all = [
    ember,
    teal,
    blue,
    green,
    violet,
    crimson,
  ];

  static OSAccentFamily byId(String? id) =>
      all.firstWhere((a) => a.id == id, orElse: () => ember);
}
