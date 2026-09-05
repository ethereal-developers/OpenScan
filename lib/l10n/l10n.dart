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
  ];
}
