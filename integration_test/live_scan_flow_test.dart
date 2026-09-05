import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openscan/config/globals.dart';
import 'package:openscan/core/settings/app_settings.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/l10n/l10n.dart';
import 'package:openscan/view/screens/live_scan/live_scan_screen.dart';

import 'helpers.dart';

/// The camera screen, as far as it can honestly be driven: its chrome, its
/// toggles, and what it hands back when nothing was captured.
///
/// What a shot *produces* isn't testable here — the phone photographs
/// whatever it is pointed at, so there is no page to detect and no result
/// to assert on. The detection pipeline that decides the crop is covered
/// by `test/cv/` instead, where the frames are synthetic and the expected
/// quad is known.
///
/// Needs the camera permission granted already; the Android permission
/// dialog belongs to another process and cannot be tapped from here. See
/// this directory's README.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Globals.cameras = await availableCameras();
  });
  setUp(() async {
    await prepareApp();
    // Auto-capture off for the whole file: with it on, the camera fires by
    // itself at whatever the phone happens to be lying on, and a session
    // that was supposed to end empty comes back with a page in it.
    await AppSettings.instance.setAutoCapture(false);
  });

  /// Opens the camera through the same call the document flow uses, and
  /// reports what the session resolves with.
  Future<void> openCamera(
    WidgetTester tester,
    void Function(List<LiveCapture>?) onReturn,
  ) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.all,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => onReturn(await captureWithLiveScan(context)),
              child: const Text('Scan'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    await settleUntil(
      tester,
      () => find.textContaining('AUTO ·').evaluate().isNotEmpty,
      reason: 'the camera to start',
      timeout: const Duration(seconds: 30),
    );
  }

  testWidgets('every control is on the one bar, with no caret to open',
      (tester) async {
    await openCamera(tester, (_) {});

    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(find.byIcon(Icons.grid_3x3_rounded), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);
    expect(find.textContaining('Done'), findsOneWidget);

    // The row that used to hide behind a caret, and the EV stepper in it,
    // are gone for good.
    expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
    expect(find.text('EV'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  });

  testWidgets('the magic button toggles auto-capture, and it sticks',
      (tester) async {
    await openCamera(tester, (_) {});

    expect(find.text('AUTO · OFF'), findsOneWidget);

    await tapAndSettle(tester, find.byIcon(Icons.auto_awesome_rounded));

    expect(find.text('AUTO · ON'), findsOneWidget);
    expect(AppSettings.instance.autoCapture, isTrue);

    // And it is the stored setting, not just this screen's state: the same
    // preference the Settings switch writes.
    await tapAndSettle(tester, find.byIcon(Icons.auto_awesome_rounded));
    expect(find.text('AUTO · OFF'), findsOneWidget);
    expect(AppSettings.instance.autoCapture, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  });

  testWidgets('leaving without capturing hands back nothing at all',
      (tester) async {
    List<LiveCapture>? captures = [];

    await openCamera(tester, (result) => captures = result);

    // Done is inert with no pages, so this leaves the way a user would.
    await tester.binding.handlePopRoute();
    await settleUntil(tester, () => captures == null,
        reason: 'the camera to close');

    // Null, not an empty list: that is what tells the caller no document
    // was started, so an untouched scan leaves nothing behind.
    expect(captures, isNull);
  });
}
