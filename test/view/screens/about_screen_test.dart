import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/l10n/l10n.dart';
import 'package:openscan/view/screens/about_screen.dart';

/// The developer cards sit in a Row inside a ListView, which is exactly the
/// arrangement that asks for infinite height if the cross-axis alignment is
/// wrong. When it went wrong the whole body rendered blank — the AppBar
/// still drew, so it looked like an empty page rather than a crash, and
/// nothing reached logcat. Hence a test that simply builds the screen.

Widget _app({String lang = 'en', double scale = 1.0}) => MaterialApp(
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
      home: AboutScreen(),
    );

void main() {
  for (final size in [const Size(320, 480), const Size(411, 914)]) {
    for (final scale in [1.0, 2.0]) {
      for (final locale in L10n.all) {
        testWidgets(
            'builds at ${size.width.toInt()}x${size.height.toInt()} '
            '${scale}x in ${locale.languageCode}', (tester) async {
          tester.view.physicalSize = size * 3;
          tester.view.devicePixelRatio = 3.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(_app(lang: locale.languageCode, scale: scale));
          await tester.pump();

          // The body actually drew something, not just the AppBar.
          expect(find.byType(ListView), findsOneWidget);
          expect(find.textContaining('OpenScan'), findsWidgets);
        });
      }
    }
  }

  testWidgets('both developers are present and announced as links',
      (tester) async {
    tester.view.physicalSize = const Size(411, 914) * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    for (final name in ['Vijay', 'Vikram']) {
      expect(find.text(name), findsOneWidget);
      expect(
        find.bySemanticsLabel('$name, ${l10n.view_on_linkedin}'),
        findsOneWidget,
        reason: '$name should be announced as a link to LinkedIn',
      );
    }
    expect(find.text('LinkedIn'), findsNWidgets(2));
    handle.dispose();
  });
}
