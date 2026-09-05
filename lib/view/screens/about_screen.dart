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

/// The two people who wrote the app, as the v2 About screen had them.
/// Names are not localised: they are names.
const List<_Developer> _developers = [
  _Developer(
    name: 'Vijay',
    photo: 'assets/vj_jpg.JPG',
    linkedIn: 'https://www.linkedin.com/in/vijay-t-s/',
  ),
  _Developer(
    name: 'Vikram',
    photo: 'assets/vikkiboi.jpg',
    linkedIn: 'https://www.linkedin.com/in/vikram-harikrishnan/',
  ),
];

class _Developer {
  const _Developer({
    required this.name,
    required this.photo,
    required this.linkedIn,
  });

  final String name;
  final String photo;
  final String linkedIn;
}

/// Opens [url] in the browser, and says so when it cannot.
///
/// A dead link that prints to the debug console and nothing else looks
/// exactly like a card that is not a link at all, which is how the missing
/// browser <queries> entry stayed invisible.
Future<void> launchWebsite(BuildContext context, Uri url) async {
  var launched = false;
  try {
    launched = await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Could not launch $url: $e');
  }
  if (!launched && context.mounted) {
    OSSnack.error(context, AppLocalizations.of(context)!.couldnt_launch_url);
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
          // Every locale writes app_description to follow the app's name
          // inline — "is an open-source app…", "είναι…", "एक … है" — so the
          // name has to lead the paragraph or it opens mid-sentence.
          Text.rich(
            TextSpan(
              text: 'Open',
              style: OSTypography.body.copyWith(
                color: os.onSurface,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(text: 'Scan', style: TextStyle(color: os.accent)),
                TextSpan(
                  text: ' ${l10n.app_description}',
                  style: OSTypography.body.copyWith(
                    color: os.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
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
          // Written out rather than using OSSectionHeader, which carries the
          // settings list's own gutter and would indent past this page's text.
          Text(
            l10n.developers.toUpperCase(),
            style: OSTypography.caption.copyWith(
              color: os.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: OSSpace.sm),
          // IntrinsicHeight so the two cards match height whatever the
          // names do — `stretch` alone asks for infinite height inside a
          // list, which silently blanks the whole page.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < _developers.length; i++) ...[
                  if (i > 0) const SizedBox(width: OSSpace.sm),
                  Expanded(child: _DeveloperCard(_developers[i])),
                ],
              ],
            ),
          ),
          const SizedBox(height: OSSpace.lg),
          OSButton(
            label: l10n.open_source_github,
            // The real mark rather than a code glyph. github-mark carries
            // the Octocat in its alpha channel — the v2 asset drew it in
            // luminance inside an opaque disc, which tinted to a blob — so
            // it takes the button's foreground in either theme.
            leading: Builder(
              builder: (context) => Image.asset(
                'assets/github-mark.png',
                height: 18,
                width: 18,
                color: IconTheme.of(context).color,
              ),
            ),
            kind: OSButtonKind.tonal,
            expand: true,
            onPressed: () => launchWebsite(context, Uri.parse(_repositoryUrl)),
          ),
        ],
      ),
    );
  }
}

/// One developer, tappable through to their LinkedIn.
///
/// The card states where it goes rather than only implying it: a bare
/// portrait gives no clue that it is a link at all, which is what the v2
/// card left to a commented-out "Tap for more".
class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard(this.developer, {Key? key}) : super(key: key);

  final _Developer developer;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      label: '${developer.name}, ${l10n.view_on_linkedin}',
      // The card is one link, so it announces once. Without this the name
      // and the word "LinkedIn" come through as separate nodes and the
      // label never reaches the reader.
      excludeSemantics: true,
      child: Material(
        color: os.surfaceVariant,
        borderRadius: BorderRadius.circular(OSRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(OSRadius.card),
          onTap: () => launchWebsite(context, Uri.parse(developer.linkedIn)),
          child: Container(
            padding: const EdgeInsets.symmetric(
                vertical: OSSpace.md, horizontal: OSSpace.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(OSRadius.card),
              border: Border.all(color: os.outline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: os.accent, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: os.surfaceContainer,
                    backgroundImage: AssetImage(developer.photo),
                  ),
                ),
                const SizedBox(height: OSSpace.sm),
                Text(
                  developer.name,
                  style: OSTypography.label.copyWith(
                    color: os.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: OSSpace.xxs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new_rounded,
                        size: 12, color: os.onSurfaceVariant),
                    const SizedBox(width: OSSpace.xxs),
                    Flexible(
                      child: Text(
                        'LinkedIn',
                        overflow: TextOverflow.ellipsis,
                        style: OSTypography.caption
                            .copyWith(color: os.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
