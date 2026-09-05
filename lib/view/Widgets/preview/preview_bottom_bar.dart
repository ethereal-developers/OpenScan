import 'package:flutter/material.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';

/// The page preview's action row. Fixed-dark in both themes, like the
/// viewfinder: a full-bleed scan is already the highest-contrast context
/// on screen, so the chrome around it doesn't retheme.
class PreviewScreenBottomBar extends StatelessWidget {
  const PreviewScreenBottomBar({
    Key? key,
    required this.visible,
    required this.cropOnPressed,
    required this.deleteOnPressed,
    required this.filterOnPressed,
    required this.rescanOnPressed,
  }) : super(key: key);

  final bool visible;
  final VoidCallback? cropOnPressed;
  final VoidCallback? deleteOnPressed;
  final VoidCallback? filterOnPressed;
  final VoidCallback? rescanOnPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: OSMotion.selection,
        child: Container(
          color: OSColors.chromeScrim,
          padding: const EdgeInsets.only(top: OSSpace.xs, bottom: OSSpace.xs),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PreviewAction(
                  icon: Icons.crop_rounded,
                  label: l10n.crop,
                  onPressed: cropOnPressed,
                ),
                _PreviewAction(
                  icon: Icons.delete_outline_rounded,
                  label: l10n.delete,
                  onPressed: deleteOnPressed,
                ),
                _PreviewAction(
                  icon: Icons.tune_rounded,
                  label: l10n.filter_action,
                  onPressed: filterOnPressed,
                ),
                _PreviewAction(
                  icon: Icons.photo_camera_rounded,
                  label: l10n.rescan,
                  onPressed: rescanOnPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewAction extends StatelessWidget {
  const _PreviewAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(OSRadius.card),
      child: Container(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: OSSpace.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: OSColors.chromeOnBackground, size: 22),
            const SizedBox(height: OSSpace.xxs),
            Text(label,
                style: OSTypography.caption
                    .copyWith(color: OSColors.chromeOnBackground)),
          ],
        ),
      ),
    );
  }
}
