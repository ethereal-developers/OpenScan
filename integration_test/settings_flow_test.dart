import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openscan/core/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Settings, checked where it matters: a switch is only really flipped if
/// the preference behind it changed, since that is what the camera and the
/// storage pipeline read.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(prepareApp);
  tearDown(clearLibrary);

  Future<void> openSettings(WidgetTester tester) async {
    await pumpApp(tester);
    await tapAndSettle(tester, find.byIcon(Icons.more_vert_rounded));
    await tapAndSettle(tester, find.text('Settings'));
  }

  testWidgets('the scanning switches write through to the preferences',
      (tester) async {
    await openSettings(tester);

    final settings = AppSettings.instance;
    final wasKeeping = settings.keepOriginal;
    final wasSounding = settings.captureSound;

    await tapAndSettle(tester, find.text('Keep original image'));
    await tapAndSettle(tester, find.text('Capture sound'));

    expect(settings.keepOriginal, !wasKeeping);
    expect(settings.captureSound, !wasSounding);

    // And they are stored, not just held in memory: a fresh read of the
    // preferences sees the new values.
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(prefs.getBool('keepOriginal'), !wasKeeping);
    expect(prefs.getBool('captureSound'), !wasSounding);

    // Put them back, so the rest of the suite runs against the defaults.
    await tapAndSettle(tester, find.text('Keep original image'));
    await tapAndSettle(tester, find.text('Capture sound'));
    expect(settings.keepOriginal, wasKeeping);
  });

  testWidgets('auto-capture is the same setting the camera long-press writes',
      (tester) async {
    await openSettings(tester);

    final was = AppSettings.instance.autoCapture;
    await tapAndSettle(tester, find.text('Auto-capture'));
    expect(AppSettings.instance.autoCapture, !was);

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    // Shares its key with the live-scan screen's own preference.
    expect(prefs.getBool('liveScanAutoCaptureEnabled'), !was);

    await tapAndSettle(tester, find.text('Auto-capture'));
    expect(AppSettings.instance.autoCapture, was);
  });

  testWidgets('a default filter can be chosen and is shown as the value',
      (tester) async {
    await openSettings(tester);

    await tapAndSettle(tester, find.text('Default filter'));
    await tapAndSettle(tester, find.text('Grayscale').last);

    expect(AppSettings.instance.defaultFilter, 'Grayscale');
    expect(find.text('Grayscale'), findsOneWidget);

    // Back to none, so new pages in later tests arrive unfiltered.
    await tapAndSettle(tester, find.text('Default filter'));
    await tapAndSettle(tester, find.text('Original').last);
    expect(AppSettings.instance.defaultFilter, isNull);
  });

  testWidgets('theme can be switched to dark and back', (tester) async {
    await openSettings(tester);

    await tapAndSettle(tester, find.text('Theme'));
    await tapAndSettle(tester, find.text('Dark').last);

    expect(AppSettings.instance.themeMode, ThemeMode.dark);
    expect(Theme.of(tester.element(find.text('Theme'))).brightness,
        Brightness.dark);

    await tapAndSettle(tester, find.text('Theme'));
    await tapAndSettle(tester, find.text('System').last);
    expect(AppSettings.instance.themeMode, ThemeMode.system);
  });
}
