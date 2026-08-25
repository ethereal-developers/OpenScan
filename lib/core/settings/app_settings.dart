import 'package:flutter/material.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the library grid is ordered.
enum LibrarySort { lastModified, created, name, pageCount }

extension LibrarySortLabel on LibrarySort {
  String get label {
    switch (this) {
      case LibrarySort.lastModified:
        return 'Last modified';
      case LibrarySort.created:
        return 'Date created';
      case LibrarySort.name:
        return 'Name (A–Z)';
      case LibrarySort.pageCount:
        return 'Page count';
    }
  }
}

/// App-wide preferences, persisted to [SharedPreferences].
///
/// A plain [ChangeNotifier] rather than a Bloc: these are single values with
/// no transitions worth modelling, and the app root listens to exactly one
/// object to rebuild the theme. Exposed as a singleton because the camera
/// and the export sheet both read it far from any provider scope.
class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const _kThemeMode = 'themeMode';
  static const _kAccent = 'accentId';
  static const _kAutoCapture = 'liveScanAutoCaptureEnabled';
  static const _kCaptureSound = 'captureSound';
  static const _kKeepOriginal = 'keepOriginal';
  static const _kDefaultFilter = 'defaultFilter';
  static const _kSort = 'librarySort';

  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  OSAccentFamily _accent = OSAccents.ember;
  bool _autoCapture = true;
  bool _captureSound = true;
  bool _keepOriginal = true;
  String? _defaultFilter;
  LibrarySort _sort = LibrarySort.lastModified;

  ThemeMode get themeMode => _themeMode;
  OSAccentFamily get accent => _accent;
  bool get autoCapture => _autoCapture;
  bool get captureSound => _captureSound;
  bool get keepOriginal => _keepOriginal;

  /// [Filter.name] applied to new pages, or null for none.
  String? get defaultFilter => _defaultFilter;
  LibrarySort get sort => _sort;

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == prefs.getString(_kThemeMode),
      orElse: () => ThemeMode.system,
    );
    _accent = OSAccents.byId(prefs.getString(_kAccent));
    // Shares its key with the live-scan screen's own preference, which
    // predates this class — the two are the same setting, now surfaced in
    // Settings as well as behind the camera's long-press.
    _autoCapture = prefs.getBool(_kAutoCapture) ?? true;
    _captureSound = prefs.getBool(_kCaptureSound) ?? true;
    _keepOriginal = prefs.getBool(_kKeepOriginal) ?? true;
    _defaultFilter = prefs.getString(_kDefaultFilter);
    _sort = LibrarySort.values.firstWhere(
      (s) => s.name == prefs.getString(_kSort),
      orElse: () => LibrarySort.lastModified,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(_kThemeMode, mode.name);
  }

  Future<void> setAccent(OSAccentFamily accent) async {
    _accent = accent;
    notifyListeners();
    await _prefs?.setString(_kAccent, accent.id);
  }

  Future<void> setAutoCapture(bool value) async {
    _autoCapture = value;
    notifyListeners();
    await _prefs?.setBool(_kAutoCapture, value);
  }

  Future<void> setCaptureSound(bool value) async {
    _captureSound = value;
    notifyListeners();
    await _prefs?.setBool(_kCaptureSound, value);
  }

  Future<void> setKeepOriginal(bool value) async {
    _keepOriginal = value;
    notifyListeners();
    await _prefs?.setBool(_kKeepOriginal, value);
  }

  Future<void> setDefaultFilter(String? filterName) async {
    _defaultFilter = filterName;
    notifyListeners();
    if (filterName == null) {
      await _prefs?.remove(_kDefaultFilter);
    } else {
      await _prefs?.setString(_kDefaultFilter, filterName);
    }
  }

  Future<void> setSort(LibrarySort sort) async {
    _sort = sort;
    notifyListeners();
    await _prefs?.setString(_kSort, sort.name);
  }
}
