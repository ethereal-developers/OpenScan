import 'package:flutter/material.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';

/// The shared parts every redesigned screen is built from. Nothing below
/// paints a literal colour — they all read [OSColors] — so an accent swap
/// or a theme change propagates without touching a screen.

enum OSButtonKind { primary, tonal, outline, text, danger }

/// One button spec with five kinds, so a screen never has to decide on
/// padding, radius or a disabled colour.
class OSButton extends StatelessWidget {
  const OSButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.kind = OSButtonKind.primary,
    this.icon,
    this.leading,
    this.expand = false,
    this.busy = false,
  }) : super(key: key);

  final String label;
  final VoidCallback? onPressed;
  final OSButtonKind kind;
  final IconData? icon;

  /// A leading widget for marks Material has no glyph for — the GitHub
  /// logo, say. Takes precedence over [icon]. It is built inside the
  /// button's IconTheme, so a `Builder` reading `IconTheme.of(context)`
  /// picks up the same foreground the label uses, disabled state included.
  final Widget? leading;

  final bool expand;

  /// Swaps the label for a spinner and blocks the tap, for the moment
  /// between "Export" and the export sheet's progress state.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final os = context.os;

    late final Color background;
    late final Color foreground;
    BorderSide side = BorderSide.none;

    switch (kind) {
      case OSButtonKind.primary:
        background = os.accent;
        foreground = os.onAccent;
        break;
      case OSButtonKind.tonal:
        background = os.surfaceContainer;
        foreground = os.onSurface;
        // Sheets are painted in surfaceContainer too, so a tonal button
        // sitting on one needs the hairline to have an edge at all.
        side = BorderSide(color: os.outline);
        break;
      case OSButtonKind.outline:
        background = Colors.transparent;
        foreground = os.onSurface;
        side = BorderSide(color: os.outline);
        break;
      case OSButtonKind.text:
        background = Colors.transparent;
        foreground = os.onSurface;
        break;
      case OSButtonKind.danger:
        background = os.danger;
        foreground = os.onDanger;
        break;
    }

    final enabled = onPressed != null && !busy;

    final child = busy
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: OSSpace.xs),
              ] else if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: OSSpace.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final button = Material(
      color: enabled ? background : os.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OSRadius.card),
        side: side,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        // Center with heightFactor 1 rather than Container's `alignment`:
        // an aligned Container expands to fill whatever bounded height it
        // is handed, which turned this into a full-screen button when used
        // as a Scaffold's bottomNavigationBar.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: OSSpace.lg, vertical: OSSpace.sm),
            child: Center(
              heightFactor: 1,
                  child: DefaultTextStyle(
                style: OSTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: enabled ? foreground : os.onSurfaceVariant,
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: enabled ? foreground : os.onSurfaceVariant,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A selectable pill. Selected state pairs the accent fill with a weight
/// change, so it never reads by colour alone.
class OSChip extends StatelessWidget {
  const OSChip({
    Key? key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
  }) : super(key: key);

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return Material(
      color: selected ? os.accentContainer : os.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OSRadius.chip),
        side: BorderSide(color: selected ? os.accent : os.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: OSSpace.sm, vertical: OSSpace.xs + 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16,
                    color:
                        selected ? os.onAccentContainer : os.onSurfaceVariant),
                const SizedBox(width: OSSpace.xxs + 2),
              ],
              Text(
                label,
                style: OSTypography.label.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? os.onAccentContainer : os.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented control (Export format, Theme mode).
class OSSegmented<T> extends StatelessWidget {
  const OSSegmented({
    Key? key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: os.surfaceVariant,
        borderRadius: BorderRadius.circular(OSRadius.card),
        border: Border.all(color: os.outline),
      ),
      child: Row(
        children: [
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(values[i]),
                child: AnimatedContainer(
                  duration: OSMotion.selection,
                  curve: OSMotion.standardCurve,
                  padding:
                      const EdgeInsets.symmetric(vertical: OSSpace.xs + 2),
                  decoration: BoxDecoration(
                    color: values[i] == selected ? os.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(OSRadius.chip + 1),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: OSTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: values[i] == selected
                          ? os.onAccent
                          : os.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Canonical empty state: icon plate, headline, one line of copy, and at
/// most one action.
class OSEmptyState extends StatelessWidget {
  const OSEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OSSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                color: os.surfaceVariant,
                borderRadius: BorderRadius.circular(OSSpace.lg),
              ),
              child: Icon(icon, size: 36, color: os.outline),
            ),
            const SizedBox(height: OSSpace.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: OSTypography.subtitle
                  .copyWith(color: os.onSurface, fontSize: 16),
            ),
            if (message != null) ...[
              const SizedBox(height: OSSpace.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: OSTypography.body.copyWith(color: os.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: OSSpace.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// The one bottom-sheet spec every sheet in the app inherits: grabber,
/// optional header, 16px sides, 24px + safe-area bottom padding, radius 16
/// on the top corners only.
class OSSheet extends StatelessWidget {
  const OSSheet({
    Key? key,
    required this.child,
    this.title,
    this.trailing,
  }) : super(key: key);

  final Widget child;
  final String? title;
  final Widget? trailing;

  /// Opens [builder] in a modal sheet already wrapped in this spec.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      barrierColor: Theme.of(context).extension<OSColors>()!.scrim,
      backgroundColor: Colors.transparent,
      builder: (context) => OSSheet(title: title, child: builder(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return Container(
      decoration: BoxDecoration(
        color: os.surfaceContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(OSRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber first, so a sheet that is still measuring its
            // content still reads as draggable the moment it slides in.
            Padding(
              padding: const EdgeInsets.only(top: OSSpace.sm),
              child: Container(
                height: 4,
                width: 36,
                decoration: BoxDecoration(
                  color: os.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    OSSpace.md, OSSpace.md, OSSpace.md, OSSpace.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style:
                            OSTypography.subtitle.copyWith(color: os.onSurface),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    OSSpace.md, OSSpace.xs, OSSpace.md, OSSpace.xl),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 48dp-minimum action row for use inside [OSSheet].
class OSSheetAction extends StatelessWidget {
  const OSSheetAction({
    Key? key,
    required this.icon,
    required this.label,
    this.onTap,
    this.destructive = false,
    this.trailing,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    final color = destructive ? os.danger : os.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OSRadius.card),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: OSSpace.xs),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: destructive ? os.danger : os.onSurfaceVariant),
            const SizedBox(width: OSSpace.sm),
            Expanded(
              child: Text(
                label,
                style: OSTypography.body.copyWith(color: color),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Uppercase section label used by Settings and the export sheet.
class OSSectionHeader extends StatelessWidget {
  const OSSectionHeader(this.label, {Key? key}) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          OSSpace.md, OSSpace.lg, OSSpace.md, OSSpace.xs),
      child: Text(
        label.toUpperCase(),
        style: OSTypography.caption.copyWith(
          color: os.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// The three snackbar variants — success, error, and an undoable action.
class OSSnack {
  static void success(BuildContext context, String message) =>
      _show(context, message, Theme.of(context).extension<OSColors>()!.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, Theme.of(context).extension<OSColors>()!.danger);

  static void undo(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
  }) {
    final os = Theme.of(context).extension<OSColors>()!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message,
            style: OSTypography.body.copyWith(color: os.surface)),
        backgroundColor: os.onSurface,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.undo,
          textColor: os.accent,
          onPressed: onUndo,
        ),
      ));
  }

  static void _show(BuildContext context, String message, Color leading) {
    final os = Theme.of(context).extension<OSColors>()!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: os.onSurface,
        content: Row(
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(color: leading, shape: BoxShape.circle),
            ),
            const SizedBox(width: OSSpace.sm),
            Expanded(
              child: Text(message,
                  style: OSTypography.body.copyWith(color: os.surface)),
            ),
          ],
        ),
      ));
  }
}

/// Canonical two-action dialog: title, optional body, cancel + confirm.
class OSDialog extends StatelessWidget {
  const OSDialog({
    Key? key,
    required this.title,
    this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel,
    this.destructive = false,
    this.content,
  }) : super(key: key);

  final String title;
  final String? message;
  final String confirmLabel;
  /// Null means the standard "Cancel", which can only be resolved once
  /// there is a [BuildContext] to read the locale from.
  final String? cancelLabel;
  final VoidCallback onConfirm;
  final bool destructive;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return AlertDialog(
      backgroundColor: os.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OSRadius.sheet),
      ),
      title: Text(title,
          style: OSTypography.subtitle.copyWith(color: os.onSurface)),
      content: content ??
          (message == null
              ? null
              : Text(message!,
                  style:
                      OSTypography.body.copyWith(color: os.onSurfaceVariant))),
      actionsPadding: const EdgeInsets.fromLTRB(
          OSSpace.sm, 0, OSSpace.sm, OSSpace.sm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelLabel ?? AppLocalizations.of(context)!.cancel,
              style: OSTypography.label.copyWith(
                  fontWeight: FontWeight.w700, color: os.onSurfaceVariant)),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(confirmLabel,
              style: OSTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: destructive ? os.danger : os.accent,
              )),
        ),
      ],
    );
  }
}
