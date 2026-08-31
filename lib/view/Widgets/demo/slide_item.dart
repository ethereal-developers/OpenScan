import 'package:flutter/material.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';

/// One onboarding slide: a drawn hero, a headline, and one sentence.
///
/// The heroes are drawn from theme tokens rather than shipped as
/// screenshots — a screenshot of the app goes stale the first time a screen
/// changes, and these have to survive an accent swap anyway.
class SlideItem extends StatelessWidget {
  final int index;

  SlideItem(this.index);

  @override
  Widget build(BuildContext context) {
    final slide = slideList[index];
    final l10n = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: OSSpace.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Center(child: _hero(slide.hero, accent))),
          Text(
            slide.title(l10n),
            textAlign: TextAlign.center,
            style: OSTypography.title
                .copyWith(color: OSColors.chromeOnBackground, fontSize: 24),
          ),
          const SizedBox(height: OSSpace.sm),
          Text(
            slide.body(l10n),
            textAlign: TextAlign.center,
            style: OSTypography.body.copyWith(color: OSColors.chromeMuted),
          ),
          const SizedBox(height: OSSpace.xxl),
        ],
      ),
    );
  }

  Widget _hero(SlideHero hero, Color accent) {
    switch (hero) {
      case SlideHero.detect:
        // A page sitting inside a locked detection quad — the one gesture
        // the whole app is built around.
        return Container(
          height: 220,
          width: 170,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF9),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: accent, spreadRadius: 3, blurRadius: 0),
              const BoxShadow(
                color: Color(0x66000000),
                blurRadius: 30,
                offset: Offset(0, 12),
              ),
            ],
          ),
        );
      case SlideHero.private:
        return Container(
          height: 220,
          width: 170,
          decoration: BoxDecoration(
            color: const Color(0xFF221E18),
            borderRadius: BorderRadius.circular(OSRadius.pill),
            border: Border.all(color: const Color(0xFF3A342C)),
          ),
          child: Icon(Icons.lock_rounded, size: 56, color: accent),
        );
      case SlideHero.camera:
        return Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF221E18),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.photo_camera_rounded, size: 48, color: accent),
        );
    }
  }
}

enum SlideHero { detect, private, camera }

/// One slide's content.
///
/// The text is looked up rather than stored, because the list itself is a
/// compile-time constant and a translated string is not: [slideList] fixes
/// the order and the artwork, and the words arrive with the locale.
class Slide {
  final SlideHero hero;

  const Slide(this.hero);

  String title(AppLocalizations l10n) {
    switch (hero) {
      case SlideHero.detect:
        return l10n.demo_detect_title;
      case SlideHero.private:
        return l10n.demo_private_title;
      case SlideHero.camera:
        return l10n.demo_camera_title;
    }
  }

  String body(AppLocalizations l10n) {
    switch (hero) {
      case SlideHero.detect:
        return l10n.demo_detect_body;
      case SlideHero.private:
        return l10n.demo_private_body;
      case SlideHero.camera:
        return l10n.demo_camera_body;
    }
  }
}

const slideList = [
  Slide(SlideHero.detect),
  Slide(SlideHero.private),
  Slide(SlideHero.camera),
];
