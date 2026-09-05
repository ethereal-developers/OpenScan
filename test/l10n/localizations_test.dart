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
  test('every locale in L10n.all has a delegate that loads', () async {
    for (final locale in L10n.all) {
      expect(AppLocalizations.delegate.isSupported(locale), isTrue,
          reason: '${locale.languageCode} is listed but unsupported');
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
        expect(value.trim(), isNotEmpty,
            reason: 'empty string in ${locale.languageCode}');
      }
    }
  });

  test('plurals resolve, and singular differs from plural', () async {
    for (final locale in L10n.all) {
      final l10n = await _load(locale);
      expect(l10n.pages_count(1), isNot(equals(l10n.pages_count(7))),
          reason: '${locale.languageCode} pages_count is not pluralized');
      expect(l10n.skipped_files(1), isNot(equals(l10n.skipped_files(4))),
          reason: '${locale.languageCode} skipped_files is not pluralized');
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
