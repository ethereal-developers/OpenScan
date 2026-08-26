import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/l10n/l10n.dart';
import 'package:openscan/view/screens/crop/crop_screen.dart';

import 'helpers.dart';

/// The crop screen, end to end on a real device: open it on a page, use
/// the whole page as the crop, turn it, and confirm the file that comes
/// back really was turned.
///
/// Rotation used to be shown and then thrown away — the warp ran on the
/// unrotated image — which no unit test could catch, since the bug lived
/// in the wiring between the screen and the isolate rather than in either
/// of them.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late File page;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('crop_rotate');
    // A portrait page with a red band across its top: an asymmetric mark,
    // so a quarter turn is unmistakable in the result.
    final image = img.Image(width: 600, height: 900);
    img.fill(image, color: img.ColorRgb8(245, 245, 240));
    img.fillRect(image,
        x1: 0, y1: 0, x2: 599, y2: 89, color: img.ColorRgb8(220, 30, 30));
    page = File('${dir.path}/page.jpg')
      ..writeAsBytesSync(img.encodeJpg(image, quality: 92));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('Rotate turns the page that the crop screen returns',
      (tester) async {
    File? returned;

    await _openCropScreen(tester, page, (file) => returned = file);

    // Detection runs in an isolate before the screen is usable; Next stays
    // disabled until the page has been laid out and measured.
    await settleUntil(tester, () => _nextIsEnabled(tester),
        reason: 'the crop screen to finish detecting');

    // Take the whole page, so what comes back depends only on the turn.
    await tester.tap(find.text('No crop'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rotate'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await settleUntil(tester, () => returned != null,
        reason: 'the crop to finish',
        timeout: const Duration(seconds: 60));

    final result = img.decodeImage(returned!.readAsBytesSync())!;

    // Portrait went in, landscape came out.
    expect(result.width, greaterThan(result.height));
    expect(result.width / result.height, closeTo(900 / 600, 0.05));

    // And it turned clockwise: the band that was across the top is now
    // down the right-hand edge.
    final rightEdge = result.getPixel(result.width - 10, result.height ~/ 2);
    final leftEdge = result.getPixel(10, result.height ~/ 2);
    expect(rightEdge.r, greaterThan(150));
    expect(rightEdge.g, lessThan(120));
    expect(leftEdge.g, greaterThan(150));
  });

  testWidgets('backing out leaves the page exactly as it was', (tester) async {
    File? returned = File('sentinel');
    final before = page.readAsBytesSync();

    await _openCropScreen(tester, page, (file) => returned = file);
    await settleUntil(tester, () => _nextIsEnabled(tester),
        reason: 'the crop screen to finish detecting');

    await tapAndSettle(tester, find.byIcon(Icons.close_rounded));

    // Null is what tells a caller to leave the page it had alone.
    expect(returned, isNull);
    expect(page.readAsBytesSync(), before);
  });

  testWidgets('No crop returns the whole page', (tester) async {
    File? returned;

    await _openCropScreen(tester, page, (file) => returned = file);
    await settleUntil(tester, () => _nextIsEnabled(tester),
        reason: 'the crop screen to finish detecting');

    await tapAndSettle(tester, find.text('No crop'));
    await tapAndSettle(tester, find.text('Next'));
    await settleUntil(tester, () => returned != null,
        reason: 'the crop to finish',
        timeout: const Duration(seconds: 60));

    final result = img.decodeImage(returned!.readAsBytesSync())!;
    // The same page, near enough: a warp of the full frame reproduces it.
    expect(result.width / result.height, closeTo(600 / 900, 0.02));
    expect(result.getPixel(300, 20).r, greaterThan(150));
    expect(result.getPixel(300, 20).g, lessThan(120));
  });

  testWidgets('dragging a corner in crops the page down', (tester) async {
    File? returned;

    await _openCropScreen(tester, page, (file) => returned = file);
    await settleUntil(tester, () => _nextIsEnabled(tester),
        reason: 'the crop screen to finish detecting');

    await tapAndSettle(tester, find.text('No crop'));

    // The top-left corner now sits on the page's top-left; drag it well
    // inside, which should take the red band with it.
    final box = tester.getRect(find.byType(Image));
    await tester.dragFrom(box.topLeft + const Offset(2, 2),
        Offset(box.width * 0.35, box.height * 0.35));
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.text('Next'));
    await settleUntil(tester, () => returned != null,
        reason: 'the crop to finish',
        timeout: const Duration(seconds: 60));

    final result = img.decodeImage(returned!.readAsBytesSync())!;
    // The top edge now runs from well below the red band on the left up to
    // the untouched top-right corner, so the band survives on one side of
    // the result and not the other. (The warp keeps the longest of each
    // pair of opposite edges, so the output does not get narrower — what
    // changes is what is inside it.)
    final topLeft = result.getPixel(6, 6);
    final topRight = result.getPixel(result.width - 6, 6);
    expect(topLeft.g, greaterThan(150), reason: 'dragged past the red band');
    expect(topRight.r, greaterThan(150));
    expect(topRight.g, lessThan(120));
  });
}

/// Pumps a host screen and opens the crop screen on [file] through the
/// same entry point the app uses, reporting what it pops with.
Future<void> _openCropScreen(
  WidgetTester tester,
  File file,
  void Function(File?) onReturn,
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
            onPressed: () async => onReturn(await imageCropper(context, file)),
            child: const Text('Crop this'),
          ),
        ),
      ),
    ),
  ));

  await tester.tap(find.text('Crop this'));
  await tester.pumpAndSettle();
}

bool _nextIsEnabled(WidgetTester tester) {
  final button = tester.widgetList<TextButton>(find.byType(TextButton));
  return button.any((b) => b.onPressed != null);
}

