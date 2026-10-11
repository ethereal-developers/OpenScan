import 'package:flutter/material.dart';

/// The locales the app ships translations for.
///
/// Order is the order Flutter tries them in when resolving the system
/// locale, with English first as the fallback every key is guaranteed to
/// have.
class L10n {
  static final all = [
    const Locale('en'),
    const Locale('el'),
    const Locale('hi'),
    const Locale('hu'),
    const Locale('pl'),
    const Locale('ta'),
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// Flutter's default language-only fallback can match Hant to Hans.
  /// Only offer our Chinese translation for an explicit Simplified script
  /// or a scriptless locale from a Simplified Chinese region. Keep the rest
  /// of the user's preferred languages in order before falling back to English.
  static Locale resolveLocales(
    List<Locale>? preferredLocales,
    Iterable<Locale> supportedLocales,
  ) {
    final candidates = <Locale>[];
    for (final locale in preferredLocales ?? const <Locale>[]) {
      if (locale.languageCode != 'zh') {
        candidates.add(locale);
      } else if (locale.scriptCode == 'Hans' ||
          (locale.scriptCode == null &&
              (locale.countryCode == 'CN' || locale.countryCode == 'SG'))) {
        candidates.add(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        );
      }
    }
    return basicLocaleListResolution(candidates, supportedLocales);
  }
}
