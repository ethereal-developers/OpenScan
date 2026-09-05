import 'package:flutter/material.dart';
import 'package:openscan/core/theme/os_tokens.dart';

/// The full token set for one theme, reachable from any widget via
/// `context.os`.
///
/// Material's own [ColorScheme] carries most of these, but not all: the
/// design separates `surfaceContainer` from `surfaceVariant`, pairs the
/// accent with a near-black ink rather than Material's derived `onPrimary`,
/// and adds success/warning/overlayChrome roles Material has no slot for.
/// Keeping them in one extension means a screen never has to decide which
/// of the two systems a colour came from.
@immutable
class OSColors extends ThemeExtension<OSColors> {
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceContainer;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;

  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;

  final Color success;
  final Color warning;
  final Color danger;
  final Color onDanger;

  final Color scrim;
  final Color overlayChrome;

  const OSColors({
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceContainer,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.success,
    required this.warning,
    required this.danger,
    required this.onDanger,
    required this.scrim,
    required this.overlayChrome,
  });

  factory OSColors.light(OSAccentFamily accent) => OSColors(
        surface: const Color(0xFFFFFCF9),
        surfaceVariant: const Color(0xFFF5F0EA),
        surfaceContainer: const Color(0xFFEFE8DF),
        onSurface: const Color(0xFF1F1B18),
        onSurfaceVariant: const Color(0xFF6F655C),
        outline: const Color(0xFFDDD3C7),
        accent: accent.accent,
        onAccent: accent.onAccent,
        accentContainer: accent.accentContainer,
        onAccentContainer: accent.onAccentContainer,
        success: const Color(0xFF2E7D4F),
        warning: const Color(0xFF9C6B00),
        danger: const Color(0xFFC0392B),
        onDanger: const Color(0xFFFFFFFF),
        scrim: const Color(0x9914100C),
        overlayChrome: const Color(0x8C0F0D0B),
      );

  factory OSColors.dark(OSAccentFamily accent) => OSColors(
        surface: const Color(0xFF17140F),
        surfaceVariant: const Color(0xFF221E18),
        surfaceContainer: const Color(0xFF2A251E),
        onSurface: const Color(0xFFF3EDE6),
        onSurfaceVariant: const Color(0xFFB7ACA0),
        outline: const Color(0xFF3A342C),
        accent: accent.darkAccent,
        onAccent: accent.darkOnAccent,
        accentContainer: accent.darkAccentContainer,
        onAccentContainer: accent.darkOnAccentContainer,
        success: const Color(0xFF4CAF7D),
        warning: const Color(0xFFD9A441),
        danger: const Color(0xFFE5675A),
        onDanger: const Color(0xFF1A0E00),
        scrim: const Color(0xB3000000),
        overlayChrome: const Color(0xA60A0908),
      );

  /// The fixed-dark chrome used by the camera and the page preview in
  /// *both* themes: a viewfinder or a full-bleed scan is already the
  /// darkest, highest-contrast context there is, so it doesn't retheme.
  static const Color chromeBackground = Color(0xFF0F0D0A);
  static const Color chromeOnBackground = Color(0xFFFFFFFF);
  static const Color chromeMuted = Color(0xFFB7ACA0);
  static const Color chromeScrim = Color(0x8C0F0D0A);
  static const Color chromeControl = Color(0x1FFFFFFF);

  @override
  OSColors copyWith({
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceContainer,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? success,
    Color? warning,
    Color? danger,
    Color? onDanger,
    Color? scrim,
    Color? overlayChrome,
  }) {
    return OSColors(
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      scrim: scrim ?? this.scrim,
      overlayChrome: overlayChrome ?? this.overlayChrome,
    );
  }

  @override
  OSColors lerp(ThemeExtension<OSColors>? other, double t) {
    if (other is! OSColors) return this;
    return OSColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      surfaceContainer:
          Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      onAccentContainer:
          Color.lerp(onAccentContainer, other.onAccentContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      overlayChrome: Color.lerp(overlayChrome, other.overlayChrome, t)!,
    );
  }
}

extension OSColorsContext on BuildContext {
  /// The design tokens for the theme in force here.
  OSColors get os => Theme.of(this).extension<OSColors>()!;
}
