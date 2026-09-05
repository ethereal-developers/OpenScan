import 'package:flutter/material.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/view/Widgets/demo/demo_mockups.dart';

/// One tutorial slide: a working miniature of the screen being taught, a
/// headline, and one sentence naming the gesture.
///
/// The mockup takes the room that is left after the words, never the other
/// way round, and the whole slide scrolls. A fixed-height illustration
/// pushed the copy off the bottom of small screens and off *every* screen
/// at large text sizes, so the illustration is the part that yields.
class SlideItem extends StatelessWidget {
  final int index;

  SlideItem(this.index);

  @override
  Widget build(BuildContext context) {
    final slide = slideList[index];
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: OSSpace.xl),
        child: ConstrainedBox(
          // Fill the viewport when there is room, scroll when there is not.
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: OSSpace.md),
              // A share of the viewport, not a flex child: inside a scroll
              // view the incoming height is unbounded, and a flex child
              // under an unbounded main axis is an assertion, not a layout.
              // Measuring against the viewport keeps the mockup the same
              // proportion of every screen and lets the copy below it push
              // the slide into scrolling instead of off the bottom.
              SizedBox(
                height: box.maxHeight * 0.60,
                child: DemoMockupView(slide.mockup),
              ),
              const SizedBox(height: OSSpace.xl),
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
              const SizedBox(height: OSSpace.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// One slide's content.
///
/// The text is looked up rather than stored, because the list itself is a
/// compile-time constant and a translated string is not: [slideList] fixes
/// the order and the artwork, and the words arrive with the locale.
class Slide {
  final DemoMockup mockup;

  const Slide(this.mockup);

  String title(AppLocalizations l10n) {
    switch (mockup) {
      case DemoMockup.scan:
        return l10n.demo_scan_title;
      case DemoMockup.pages:
        return l10n.demo_pages_title;
      case DemoMockup.adjust:
        return l10n.demo_adjust_title;
      case DemoMockup.organise:
        return l10n.demo_organise_title;
      case DemoMockup.export:
        return l10n.demo_export_title;
      case DemoMockup.privacy:
        return l10n.demo_privacy_title;
    }
  }

  String body(AppLocalizations l10n) {
    switch (mockup) {
      case DemoMockup.scan:
        return l10n.demo_scan_body;
      case DemoMockup.pages:
        return l10n.demo_pages_body;
      case DemoMockup.adjust:
        return l10n.demo_adjust_body;
      case DemoMockup.organise:
        return l10n.demo_organise_body;
      case DemoMockup.export:
        return l10n.demo_export_body;
      case DemoMockup.privacy:
        return l10n.demo_privacy_body;
    }
  }
}

/// The walkthrough, in the order a first document actually happens:
/// shoot it, keep shooting, fix it, order it, send it.
const slideList = [
  Slide(DemoMockup.scan),
  Slide(DemoMockup.pages),
  Slide(DemoMockup.adjust),
  Slide(DemoMockup.organise),
  Slide(DemoMockup.export),
  Slide(DemoMockup.privacy),
];
