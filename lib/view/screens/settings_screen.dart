import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openscan/core/image_filter/filters/document_filters.dart';
import 'package:openscan/core/settings/app_settings.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/view/Widgets/os/os_components.dart';
import 'package:path_provider/path_provider.dart';

/// Settings, grouped by what the user is actually deciding: how scanning
/// behaves, how the app looks, and what happens to their data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _cacheBytes;

  @override
  void initState() {
    super.initState();
    _measureCache();
  }

  Future<void> _measureCache() async {
    try {
      final dir = await getTemporaryDirectory();
      var total = 0;
      if (dir.existsSync()) {
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File) total += entity.lengthSync();
        }
      }
      if (mounted) setState(() => _cacheBytes = total);
    } catch (e) {
      debugPrint('Could not measure cache: $e');
      if (mounted) setState(() => _cacheBytes = 0);
    }
  }

  Future<void> _clearCache() async {
    Navigator.pop(context); // the confirm dialog
    try {
      final dir = await getTemporaryDirectory();
      if (dir.existsSync()) {
        for (final entity in dir.listSync()) {
          entity.deleteSync(recursive: true);
        }
      }
      await _measureCache();
      if (mounted) OSSnack.success(context, 'Cache cleared');
    } catch (e) {
      debugPrint('Could not clear cache: $e');
      if (mounted) OSSnack.error(context, "Couldn't clear the cache");
    }
  }

  String get _cacheLabel {
    final bytes = _cacheBytes;
    if (bytes == null) return '…';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _pickTheme(AppSettings settings) {
    OSSheet.show(
      context: context,
      title: 'Theme',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final mode in ThemeMode.values)
            OSSheetAction(
              icon: mode == ThemeMode.light
                  ? Icons.light_mode_rounded
                  : mode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.brightness_auto_rounded,
              label: _themeLabel(mode),
              trailing: settings.themeMode == mode
                  ? Icon(Icons.check_rounded,
                      size: 20, color: sheetContext.os.accent)
                  : null,
              onTap: () {
                settings.setThemeMode(mode);
                Navigator.pop(sheetContext);
              },
            ),
        ],
      ),
    );
  }

  void _pickDefaultFilter(AppSettings settings) {
    OSSheet.show(
      context: context,
      title: 'Default filter',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final filter in documentFiltersList)
            OSSheetAction(
              icon: Icons.tune_rounded,
              label: filter.name,
              trailing: (settings.defaultFilter ??
                          defaultDocumentFilter.name) ==
                      filter.name
                  ? Icon(Icons.check_rounded,
                      size: 20, color: sheetContext.os.accent)
                  : null,
              onTap: () {
                settings.setDefaultFilter(
                    filter.name == defaultDocumentFilter.name
                        ? null
                        : filter.name);
                Navigator.pop(sheetContext);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    final settings = AppSettings.instance;
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Scaffold(
        backgroundColor: os.surface,
        appBar: AppBar(
          backgroundColor: os.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Settings',
              style: OSTypography.subtitle
                  .copyWith(color: os.onSurface, fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: OSSpace.xxl),
          children: [
            const OSSectionHeader('Scanning'),
            _SwitchRow(
              label: 'Auto-capture',
              description: 'Take the shot as soon as the page holds still.',
              value: settings.autoCapture,
              onChanged: settings.setAutoCapture,
            ),
            _SwitchRow(
              label: 'Capture sound',
              value: settings.captureSound,
              onChanged: settings.setCaptureSound,
            ),
            _SwitchRow(
              label: 'Keep original image',
              description:
                  'Keeps the uncropped photo so a page can be re-cropped '
                  'from the full capture.',
              value: settings.keepOriginal,
              onChanged: settings.setKeepOriginal,
            ),
            _ValueRow(
              label: 'Default filter',
              value: settings.defaultFilter ?? l10n.filter_original,
              onTap: () => _pickDefaultFilter(settings),
            ),
            const OSSectionHeader('Appearance'),
            _ValueRow(
              label: 'Theme',
              value: _themeLabel(settings.themeMode),
              onTap: () => _pickTheme(settings),
            ),
            _AccentRow(settings: settings),
            _ValueRow(
              label: 'Language',
              value: Localizations.localeOf(context).languageName,
              // Language follows the system locale: the app ships four
              // translations and no in-app override, so this reports
              // rather than pretends to set.
              onTap: null,
            ),
            const OSSectionHeader('Privacy & storage'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: OSSpace.md),
              child: Container(
                padding: const EdgeInsets.all(OSSpace.sm),
                decoration: BoxDecoration(
                  color: os.surfaceVariant,
                  borderRadius: BorderRadius.circular(OSRadius.card),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 18, color: os.onSurfaceVariant),
                    const SizedBox(width: OSSpace.xs),
                    Expanded(
                      child: Text(
                        'OpenScan never sends your documents anywhere. No '
                        'accounts, no cloud, no telemetry.',
                        style: OSTypography.caption
                            .copyWith(color: os.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ValueRow(
              label: 'Cache',
              value: '$_cacheLabel · Clear',
              onTap: () => showDialog(
                context: context,
                builder: (_) => OSDialog(
                  title: 'Clear cache?',
                  message:
                      'Frees $_cacheLabel of thumbnail data. Your documents '
                      'are not affected.',
                  confirmLabel: 'Clear',
                  destructive: true,
                  onConfirm: _clearCache,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A settings row that wraps rather than truncates: at a 130% text scale
/// the value drops to its own line and nothing overlaps.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.trailing,
    this.description,
    this.onTap,
  });

  final String label;
  final Widget trailing;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
            horizontal: OSSpace.md, vertical: OSSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: OSTypography.body.copyWith(color: os.onSurface)),
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(description!,
                          style: OSTypography.caption
                              .copyWith(color: os.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: OSSpace.sm),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      label: label,
      description: description,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return _SettingRow(
      label: label,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.4),
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: OSTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                color: onTap == null ? os.onSurfaceVariant : os.accent,
              ),
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded,
                size: 18, color: os.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// The accent picker: six swatches, each of which only swaps the four
/// accent tokens. Selection is a ring plus a check, never colour alone.
class _AccentRow extends StatelessWidget {
  const _AccentRow({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SettingRow(
      label: 'Accent color',
      trailing: Wrap(
        spacing: OSSpace.xs,
        children: [
          for (final accent in OSAccents.all)
            GestureDetector(
              onTap: () => settings.setAccent(accent),
              child: Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: isDark ? accent.darkAccent : accent.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: settings.accent.id == accent.id
                        ? os.onSurface
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: settings.accent.id == accent.id
                    ? Icon(Icons.check_rounded,
                        size: 16,
                        color: isDark ? accent.darkOnAccent : accent.onAccent)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

extension on Locale {
  /// The language's own name, so the row reads as the user's language
  /// rather than as a code.
  String get languageName {
    switch (languageCode) {
      case 'el':
        return 'Ελληνικά';
      case 'hu':
        return 'Magyar';
      case 'pl':
        return 'Polski';
      default:
        return 'English';
    }
  }
}
