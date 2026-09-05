import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/l10n/l10n.dart';
import 'package:openscan/view/screens/demo_screen.dart';
import 'package:openscan/view/Widgets/demo/slide_item.dart';

/// The tutorial has to survive the two things that broke it before: a short
/// screen, and a large text scale. Both used to push the copy off the bottom
/// silently — a `RenderFlex overflowed` is only a red stripe in debug, and
/// nobody ships a phone to a reviewer at 200% text.
///
/// flutter_test fails a test on any overflow or assertion raised during a
/// pump, so walking every slide without an exception is the assertion.

Widget _app({required Widget home, String lang = 'en', double scale = 1.0}) =>
    MaterialApp(
      theme: AppTheme.light(OSAccents.ember),
      locale: Locale(lang),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.all,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    );

Future<void> _walkEverySlide(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  for (var i = 0; i < slideList.length - 1; i++) {
    await tester.tap(find.byType(FilledButton));
    // Twice: once to start the page transition, once to land it.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  group('lays out without overflowing', () {
    // 320x480 is the smallest screen worth supporting; 411x914 is a current
    // mid-range phone.
    const sizes = [Size(320, 480), Size(360, 640), Size(411, 914)];
    const scales = [1.0, 1.3, 2.0];

    for (final size in sizes) {
      for (final scale in scales) {
        for (final locale in L10n.all) {
          final lang = locale.languageCode;
          testWidgets(
              '${size.width.toInt()}x${size.height.toInt()} '
              'at ${scale}x in $lang', (tester) async {
            tester.view.physicalSize = size * 3;
            tester.view.devicePixelRatio = 3.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
                _app(home: DemoScreen(), lang: lang, scale: scale));
            await _walkEverySlide(tester);
          });
        }
      }
    }
  });

  testWidgets('first launch offers Skip and ends on the permission ask',
      (tester) async {
    tester.view.physicalSize = const Size(411, 914) * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(home: DemoScreen()));
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.skip), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

    await _walkEverySlide(tester);
    expect(find.text(l10n.allow_camera_access), findsOneWidget);
  });

  testWidgets('opened from settings offers Back and ends on Done',
      (tester) async {
    tester.view.physicalSize = const Size(411, 914) * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(home: DemoScreen(showSkip: false)));
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.skip), findsNothing);

    // The back affordance belongs on the leading edge; it used to render
    // into the right-aligned slot the Skip button owns.
    final back = find.byIcon(Icons.arrow_back_rounded);
    expect(back, findsOneWidget);
    expect(tester.getCenter(back).dx, lessThan(411 / 2));

    await _walkEverySlide(tester);
    expect(find.text(l10n.done), findsOneWidget);
    expect(find.text(l10n.allow_camera_access), findsNothing);
  });
}
