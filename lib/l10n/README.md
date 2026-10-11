# Chinese locale resolution

The app advertises `zh_Hans` (Simplified Chinese) through `L10n.all`.
`app_zh_Hans.arb` inherits the translations in `app_zh.arb`: Flutter's
`gen-l10n` requires a base language ARB when a script-specific ARB exists.
The generated base `zh` locale is not advertised by the app.

`L10n.resolveLocales` prevents Flutter's language-only fallback from matching
Traditional Chinese to Simplified Chinese. An explicit `Hans` script is
supported in any region; without a script, `zh_CN` and `zh_SG` are supported.
Other Chinese locales (including bare `zh`) are skipped, allowing the next
preferred language to resolve normally, with English as the final fallback.
An explicit script takes precedence over the region.

After changing ARB files, run `flutter gen-l10n` and
`flutter test test/l10n/localizations_test.dart`.
