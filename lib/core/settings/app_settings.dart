import 'package:flutter/material.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the library grid is ordered.
enum LibrarySort { lastModified, created, name, pageCount }

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
  static const _kLiveDetection = 'liveScanDetectionEnabled';
  static const _kAutoCapture = 'liveScanAutoCaptureEnabled';
  static const _kBatchCapture = 'liveScanBatchMode';
  static const _kCaptureSound = 'captureSound';
  static const _kKeepOriginal = 'keepOriginal';
  static const _kDefaultFilter = 'defaultFilter';
  static const _kSort = 'librarySort';
  static const _kAvoidGestureStrip = 'cropAvoidGestureStrip';

  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  OSAccentFamily _accent = OSAccents.ember;
  bool _liveDetection = true;
  bool _autoCapture = false;
  bool _batchCapture = false;
  bool _captureSound = true;
  bool _keepOriginal = true;
  String? _defaultFilter;
  LibrarySort _sort = LibrarySort.lastModified;
  bool _avoidGestureStrip = false;

  ThemeMode get themeMode => _themeMode;
  OSAccentFamily get accent => _accent;

  /// Whether the camera looks for the page's edges while framing: the
  /// outline over the preview, auto-capture, and cropping each shot to that
  /// outline all hang off it. Off, the camera takes plain photos, stored
  /// whole and cropped afterwards on the crop screen — which runs its own
  /// detection on the still, so it keeps its suggested corners either way.
  bool get liveDetection => _liveDetection;
  bool get autoCapture => _autoCapture;

  /// Whether the camera stays open for page after page, each cropped to
  /// its detected edges and fixed afterwards. Off — the default — every
  /// shot goes through the crop screen before it is kept, and the session
  /// ends with that one page: the scan-then-crop flow the app had before
  /// live scanning, which is what most people scanning a page or two want.
  bool get batchCapture => _batchCapture;
  bool get captureSound => _captureSound;
  bool get keepOriginal => _keepOriginal;

  /// Whether the crop screen insets the page past the system's back-gesture
  /// strip, so a corner handle can't sit somewhere the system swallows the
  /// drag. Costs width on every page, and only helps on gesture navigation,
  /// so it is off unless the user has actually hit the problem.
  bool get avoidGestureStrip => _avoidGestureStrip;

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
    // Off unless the user turns it on: a shot that takes itself before the
    // page is framed was the most common complaint about 3.0, and a user
    // who hasn't asked for it doesn't know to look for the switch. The
    // key predates this class — it was the live-scan screen's own.
    _autoCapture = prefs.getBool(_kAutoCapture) ?? false;
    _liveDetection = prefs.getBool(_kLiveDetection) ?? true;
    _batchCapture = prefs.getBool(_kBatchCapture) ?? false;
    _captureSound = prefs.getBool(_kCaptureSound) ?? true;
    // On by default: a capture is cropped to its detected edges on the way
    // into the document, in place, so without a kept original the full
    // photo is gone the moment the page is stored — and a re-crop can then
    // only work off the already-cropped page. Worth the storage.
    _keepOriginal = prefs.getBool(_kKeepOriginal) ?? true;
    _defaultFilter = prefs.getString(_kDefaultFilter);
    _avoidGestureStrip = prefs.getBool(_kAvoidGestureStrip) ?? false;
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

  Future<void> setLiveDetection(bool value) async {
    _liveDetection = value;
    notifyListeners();
    await _prefs?.setBool(_kLiveDetection, value);
  }

  Future<void> setAutoCapture(bool value) async {
    _autoCapture = value;
    notifyListeners();
    await _prefs?.setBool(_kAutoCapture, value);
  }

  Future<void> setBatchCapture(bool value) async {
    _batchCapture = value;
    notifyListeners();
    await _prefs?.setBool(_kBatchCapture, value);
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

  Future<void> setAvoidGestureStrip(bool value) async {
    _avoidGestureStrip = value;
    notifyListeners();
    await _prefs?.setBool(_kAvoidGestureStrip, value);
  }

  Future<void> setSort(LibrarySort sort) async {
    _sort = sort;
    notifyListeners();
    await _prefs?.setString(_kSort, sort.name);
  }
}
