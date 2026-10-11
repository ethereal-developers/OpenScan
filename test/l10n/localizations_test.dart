import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/l10n/l10n.dart';

/// Guards the thing gen-l10n cannot: that every shipped locale actually
/// resolves, and that the plural messages pick a different form for
/// different counts rather than quietly falling back to one string.
Future<AppLocalizations> _load(Locale locale) =>
    AppLocalizations.delegate.load(locale);

void main() {
  const simplified = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');

  test('the app advertises only script-specific Simplified Chinese', () {
    expect(L10n.all.where((locale) => locale.languageCode == 'zh'), [
      simplified,
    ]);
  });

  for (final locale in [
    simplified,
    const Locale('zh', 'CN'),
    const Locale('zh', 'SG'),
    const Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
      countryCode: 'TW',
    ),
  ]) {
    test(
      '$locale resolves to Simplified Chinese and loads Chinese strings',
      () async {
        final resolved = L10n.resolveLocales([locale], L10n.all);
        expect(resolved, simplified);
        final l10n = await _load(resolved);
        expect(l10n.localeName, 'zh_Hans');
        expect(l10n.settings, '设置');
      },
    );
  }

  for (final locale in [
    const Locale('zh', 'TW'),
    const Locale('zh', 'HK'),
    const Locale('zh', 'MO'),
    const Locale('zh'),
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    const Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hant',
      countryCode: 'CN',
    ),
  ]) {
    test('$locale skips Simplified Chinese and honors the next language', () {
      expect(L10n.resolveLocales([locale], L10n.all), const Locale('en'));
      expect(
        L10n.resolveLocales([locale, const Locale('pl', 'PL')], L10n.all),
        const Locale('pl'),
      );
      expect(L10n.resolveLocales([locale, simplified], L10n.all), simplified);
    });
  }

  test(
    'empty and non-Chinese preferences retain normal Flutter resolution',
    () {
      expect(L10n.resolveLocales(null, L10n.all), const Locale('en'));
      expect(L10n.resolveLocales([], L10n.all), const Locale('en'));
      for (final locale in L10n.all.where((l) => l.languageCode != 'zh')) {
        expect(L10n.resolveLocales([locale, simplified], L10n.all), locale);
      }
      expect(
        L10n.resolveLocales([const Locale('fr', 'FR')], L10n.all),
        const Locale('en'),
      );
    },
  );

  testWidgets(
    'MaterialApp resolves Traditional locales without Simplified text',
    (tester) async {
      tester.binding.platformDispatcher.localesTestValue = [
        const Locale('zh', 'TW'),
        const Locale('pl', 'PL'),
      ];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: L10n.all,
          localeListResolutionCallback: L10n.resolveLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              return Text(AppLocalizations.of(context)!.settings);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text((await _load(const Locale('pl'))).settings),
        findsOneWidget,
      );
      expect(find.text('设置'), findsNothing);

      tester.binding.platformDispatcher.localesTestValue = [
        const Locale('zh', 'CN'),
      ];
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
    },
  );

  test('every locale in L10n.all has a delegate that loads', () async {
    for (final locale in L10n.all) {
      expect(
        AppLocalizations.delegate.isSupported(locale),
        isTrue,
        reason: '${locale.languageCode} is listed but unsupported',
      );
      await _load(locale);
    }
  });

  test('no locale leaves a string empty', () async {
    for (final locale in L10n.all) {
      final l10n = await _load(locale);
      for (final value in [
        l10n.library,
        l10n.settings,
        l10n.camera_access_body,
        l10n.no_documents_body,
        l10n.demo_scan_title,
        l10n.quality_high,
      ]) {
        expect(
          value.trim(),
          isNotEmpty,
          reason: 'empty string in ${locale.languageCode}',
        );
      }
    }
  });

  test('plurals resolve, and singular differs from plural', () async {
    for (final locale in L10n.all) {
      final l10n = await _load(locale);
      expect(
        l10n.pages_count(1),
        isNot(equals(l10n.pages_count(7))),
        reason: '${locale.languageCode} pages_count is not pluralized',
      );
      expect(
        l10n.skipped_files(1),
        isNot(equals(l10n.skipped_files(4))),
        reason: '${locale.languageCode} skipped_files is not pluralized',
      );
      // A plural that still contains its own placeholder never got
      // substituted — the usual sign of a malformed ICU message.
      expect(l10n.pages_count(3), isNot(contains('{')));
    }
  });

  test('Polish uses its few/many forms, not one form for both', () async {
    final pl = await _load(const Locale('pl'));
    // 2-4 takes "few", 5+ takes "many": if these match, the ARB collapsed
    // Polish into the English two-form model.
    expect(pl.pages_count(3), isNot(equals(pl.pages_count(9))));
  });

  test('placeholders are substituted, not printed', () async {
    for (final locale in L10n.all) {
      final l10n = await _load(locale);
      expect(l10n.no_results_for('tax'), contains('tax'));
      expect(l10n.export_title('Receipt'), contains('Receipt'));
      expect(l10n.page_x_of_y(2, 9), allOf(contains('2'), contains('9')));
      expect(l10n.cache_clear_action('4 MB'), contains('4 MB'));
    }
  });
}
