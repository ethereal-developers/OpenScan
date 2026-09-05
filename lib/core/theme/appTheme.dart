import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';

/// Builds the app's two themes from a single accent family.
///
/// Depth comes from surfaceContainer layering plus 1px outline hairlines
/// rather than shadow, so elevation is pinned to 0 nearly everywhere and
/// the few raised surfaces (FAB, sheets) carry their own soft shadow.
class AppTheme {
  /// Kept for the camera/preview chrome, which is fixed-dark in both
  /// themes and so cannot read a themed token.
  static const Color chromeColor = OSColors.chromeBackground;

  static ThemeData light(OSAccentFamily accent) =>
      _build(OSColors.light(accent), Brightness.light);

  static ThemeData dark(OSAccentFamily accent) =>
      _build(OSColors.dark(accent), Brightness.dark);

  /// The system-bar style that goes with a theme. Applied through
  /// [AppBarTheme.systemOverlayStyle] rather than a one-off imperative
  /// call, because every AppBar re-applies it — an imperative call made at
  /// startup does not survive a later theme switch.
  static SystemUiOverlayStyle systemOverlayStyle(OSColors os, Brightness b) {
    final isDark = b == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: os.surface,
      systemNavigationBarDividerColor: os.surface,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  /// For the inverted selection app bar, which paints itself in onSurface
  /// and so needs the status-bar icons flipped relative to the theme.
  static SystemUiOverlayStyle invertedOverlayStyle(
      OSColors os, Brightness b) {
    final barIsDark = b == Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: barIsDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: barIsDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: os.surface,
      systemNavigationBarDividerColor: os.surface,
      systemNavigationBarIconBrightness:
          b == Brightness.dark ? Brightness.light : Brightness.dark,
    );
  }

  /// The fixed-dark counterpart, for the camera/preview/crop/filter chrome
  /// that stays dark in both themes.
  static const SystemUiOverlayStyle chromeOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: OSColors.chromeBackground,
    systemNavigationBarDividerColor: OSColors.chromeBackground,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData _build(OSColors os, Brightness brightness) {
    final textTheme = OSTypography.textTheme(os.onSurface, os.onSurfaceVariant);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: os.accent,
      onPrimary: os.onAccent,
      primaryContainer: os.accentContainer,
      onPrimaryContainer: os.onAccentContainer,
      // `secondary` is what the pre-redesign screens reach for when they
      // mean "the accent"; keeping the two in step means no screen ends up
      // with a stale brand colour while it is being migrated.
      secondary: os.accent,
      onSecondary: os.onAccent,
      secondaryContainer: os.accentContainer,
      onSecondaryContainer: os.onAccentContainer,
      surface: os.surface,
      onSurface: os.onSurface,
      surfaceContainerHighest: os.surfaceContainer,
      onSurfaceVariant: os.onSurfaceVariant,
      outline: os.outline,
      outlineVariant: os.outline,
      error: os.danger,
      onError: os.onDanger,
      scrim: os.scrim,
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: os.surface,
      canvasColor: os.surface,
      primaryColor: os.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[os],
      appBarTheme: AppBarTheme(
        backgroundColor: os.surface,
        foregroundColor: os.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: OSTypography.subtitle.copyWith(color: os.onSurface),
        iconTheme: IconThemeData(color: os.onSurfaceVariant),
        actionsIconTheme: IconThemeData(color: os.onSurfaceVariant),
        systemOverlayStyle: systemOverlayStyle(os, brightness),
      ),
      iconTheme: IconThemeData(color: os.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: os.outline,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: os.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OSRadius.card),
          side: BorderSide(color: os.outline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: os.onSurfaceVariant,
        textColor: os.onSurface,
        // 48dp minimum row height, so a 130% text scale wraps rather than
        // crushing the row.
        minVerticalPadding: 12,
        titleTextStyle: OSTypography.body.copyWith(color: os.onSurface),
        subtitleTextStyle:
            OSTypography.caption.copyWith(color: os.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: os.accent,
          foregroundColor: os.onAccent,
          disabledBackgroundColor: os.surfaceContainer,
          disabledForegroundColor: os.onSurfaceVariant,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
              horizontal: OSSpace.lg, vertical: OSSpace.sm),
          textStyle: OSTypography.label.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OSRadius.card),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: os.onSurface,
          minimumSize: const Size(0, 44),
          textStyle: OSTypography.label.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OSRadius.card),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: os.onSurface,
          side: BorderSide(color: os.outline),
          minimumSize: const Size(0, 48),
          textStyle: OSTypography.label.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OSRadius.card),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: os.accent,
        foregroundColor: os.onAccent,
        elevation: 0,
        highlightElevation: 0,
        extendedTextStyle:
            OSTypography.label.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OSRadius.pill),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: os.surfaceVariant,
        hintStyle: OSTypography.body.copyWith(color: os.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: OSSpace.sm, vertical: OSSpace.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OSRadius.chip + 2),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OSRadius.chip + 2),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OSRadius.chip + 2),
          borderSide: BorderSide(color: os.accent, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? os.onAccent : os.surface),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? os.accent
                : os.surfaceContainer),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.transparent
                : os.outline),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? os.accent
                : Colors.transparent),
        checkColor: WidgetStateProperty.all(os.onAccent),
        side: BorderSide(color: os.outline, width: 1.5),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: os.accent,
        inactiveTrackColor: os.surfaceContainer,
        thumbColor: os.accent,
        overlayColor: os.accent.withValues(alpha: 0.12),
        trackHeight: 3,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: os.accent,
        linearTrackColor: os.surfaceContainer,
        circularTrackColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: os.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: os.surfaceContainer,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(OSRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: os.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: OSTypography.subtitle.copyWith(color: os.onSurface),
        contentTextStyle:
            OSTypography.body.copyWith(color: os.onSurfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OSRadius.sheet),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: os.onSurface,
        contentTextStyle: OSTypography.body.copyWith(color: os.surface),
        actionTextColor: os.accent,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(OSSpace.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OSRadius.card),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: os.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: OSTypography.body.copyWith(color: os.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OSRadius.card),
          side: BorderSide(color: os.outline),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: os.onSurface,
          borderRadius: BorderRadius.circular(OSRadius.chip),
        ),
        textStyle: OSTypography.caption.copyWith(color: os.surface),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: os.accent,
        selectionColor: os.accent.withValues(alpha: 0.3),
        selectionHandleColor: os.accent,
      ),
      // Shared-axis fade-through on both platforms: the crop -> filter ->
      // detail chain reads as one continuous edit rather than a stack of
      // pushes.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
