import 'package:flutter/material.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/l10n/app_localizations.dart';

/// The canonical blocking-progress overlay: a small card on the scrim
/// rather than a bare spinner, so it reads as "the app is working" instead
/// of "the app has frozen".
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return Dialog(
      backgroundColor: os.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OSRadius.sheet),
      ),
      child: Padding(
        padding: const EdgeInsets.all(OSSpace.xl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: os.accent),
            ),
            const SizedBox(width: OSSpace.md),
            Text(
              '${AppLocalizations.of(context)!.loading}…',
              style: OSTypography.body.copyWith(color: os.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
