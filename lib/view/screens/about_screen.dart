import 'package:flutter/material.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/view/Widgets/os/os_components.dart';
import 'package:url_launcher/url_launcher.dart';

const String _repositoryUrl =
    'https://github.com/Ethereal-Developers-Inc/OpenScan';
const String _appVersion = '3.0.0';

Future<void> launchWebsite(Uri url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    debugPrint("Couldn't launch the url");
  }
}

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final os = context.os;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: os.surface,
      appBar: AppBar(
        backgroundColor: os.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.about,
            style: OSTypography.subtitle
                .copyWith(color: os.onSurface, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            OSSpace.md + 2, OSSpace.xs, OSSpace.md + 2, OSSpace.xxl),
        children: [
          Center(
            child: Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                color: os.accentContainer,
                borderRadius: BorderRadius.circular(OSSpace.lg),
              ),
              child: Icon(Icons.document_scanner_rounded,
                  size: 40, color: os.onAccentContainer),
            ),
          ),
          const SizedBox(height: OSSpace.md),
          Center(
            child: Text.rich(
              TextSpan(
                text: 'Open',
                style: OSTypography.title.copyWith(color: os.onSurface),
                children: [
                  TextSpan(text: 'Scan', style: TextStyle(color: os.accent)),
                ],
              ),
            ),
          ),
          Center(
            child: Text('${l10n.version} $_appVersion',
                style:
                    OSTypography.caption.copyWith(color: os.onSurfaceVariant)),
          ),
          const SizedBox(height: OSSpace.lg),
          Text(
            l10n.app_description,
            style: OSTypography.body.copyWith(color: os.onSurfaceVariant),
          ),
          const SizedBox(height: OSSpace.md),
          Container(
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
                    l10n.app_description_2,
                    style: OSTypography.caption
                        .copyWith(color: os.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: OSSpace.lg),
          OSButton(
            label: l10n.open_source_github,
            icon: Icons.code_rounded,
            kind: OSButtonKind.tonal,
            expand: true,
            onPressed: () => launchWebsite(Uri.parse(_repositoryUrl)),
          ),
        ],
      ),
    );
  }
}
