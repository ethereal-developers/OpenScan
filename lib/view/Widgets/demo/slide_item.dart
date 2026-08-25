import 'package:flutter/material.dart';
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
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: OSSpace.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Center(child: _hero(slide.hero, accent))),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: OSTypography.title
                .copyWith(color: OSColors.chromeOnBackground, fontSize: 24),
          ),
          const SizedBox(height: OSSpace.sm),
          Text(
            slide.body,
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

class Slide {
  final SlideHero hero;
  final String title;
  final String body;

  const Slide({
    required this.hero,
    required this.title,
    required this.body,
  });
}

const slideList = [
  Slide(
    hero: SlideHero.detect,
    title: "Point, and it's scanned",
    body: 'OpenScan finds the page edges and captures automatically — no '
        'shutter tap needed.',
  ),
  Slide(
    hero: SlideHero.private,
    title: 'Everything stays on your phone',
    body: 'No accounts, no cloud uploads, no ads, no tracking — ever.',
  ),
  Slide(
    hero: SlideHero.camera,
    title: 'One last thing',
    body: "OpenScan needs your camera to scan pages. That's the only thing "
        "it's ever used for.",
  ),
];
