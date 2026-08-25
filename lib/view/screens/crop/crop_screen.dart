import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openscan/core/cv/models/detection_result.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/view/Widgets/cropper/polygon_painter.dart';
import 'package:openscan/view/screens/crop/crop_screen_state.dart';
import 'package:vector_math/vector_math.dart' as vector;

/// Pushes the crop screen for [image].
///
/// Returns the cropped file (the same path — the crop is written in
/// place), or null if the user backed out without cropping. Callers that
/// want "unchanged image" semantics on cancel can fall back to [image]
/// themselves; callers re-cropping an existing page use the null to leave
/// that page alone.
Future<File?> imageCropper(BuildContext context, File image) async {
  return await Navigator.push<File?>(
    context,
    MaterialPageRoute(
      builder: (context) => CropImage(
        file: image,
      ),
    ),
  );
}

class CropImage extends StatefulWidget {
  final File? file;

  CropImage({this.file});

  _CropImageState createState() => _CropImageState();
}

class _CropImageState extends State<CropImage> {
  CropScreenState _cropScreen = CropScreenState();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool cropLoading = false;
  bool _showNotFoundBanner = true;

  @override
  initState() {
    super.initState();
    _cropScreen.imageFile = widget.file;

    /// Runs detection, then waits for the next frame (so the image is
    /// guaranteed to be laid out) before computing canvas geometry and
    /// initial points exactly once — replacing the old pattern of doing
    /// this inside the widget's build() callback on every rebuild.
    _cropScreen.detectDocument().then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _cropScreen.getRenderedBoxSize();
          _cropScreen.initPoints();
        });
      });
    });

    _cropScreen.canvasSize = Size(0, 0);
    _cropScreen.rotationAngle = 0;
    _cropScreen.originalCanvasSize = Size(0, 0);
    _cropScreen.tl = Offset(0, 0);
    _cropScreen.tr = Offset(0, 0);
    _cropScreen.bl = Offset(0, 0);
    _cropScreen.br = Offset(0, 0);
    _cropScreen.t = Offset(0, 0);
    _cropScreen.l = Offset(0, 0);
    _cropScreen.b = Offset(0, 0);
    _cropScreen.r = Offset(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    _cropScreen.screenSize = MediaQuery.of(context).size;
    debugPrint(
        'Screen size=> ${_cropScreen.screenSize.width} / ${_cropScreen.screenSize.height}');
    return SafeArea(
      child: PopScope(
        canPop: true,
        child: Scaffold(
          // Fixed-dark chrome, like the viewfinder this screen follows on
          // from: the captured page is the brightest thing on screen and
          // shouldn't sit inside a warm-white frame.
          backgroundColor: OSColors.chromeBackground,
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(
              'Adjust edges',
              style: OSTypography.subtitle
                  .copyWith(color: OSColors.chromeOnBackground),
            ),
            centerTitle: true,
            elevation: 0.0,
            backgroundColor: OSColors.chromeBackground,
            systemOverlayStyle: AppTheme.chromeOverlayStyle,
            leading: IconButton(
              icon: Icon(Icons.close_rounded,
                  color: OSColors.chromeOnBackground),
              onPressed: () {
                Navigator.pop(context, null);
              },
            ),
            actions: [nextAction()],
          ),
          body: GestureDetector(
            key: _cropScreen.bodyKey,
            onPanUpdate: (updateDetails) {
              _cropScreen.updatedPoint.value = updateDetails;
              _cropScreen.updatePolygon();
            },
            onPanStart: (startDetails) {
              _cropScreen.calculateAllSlopes();
              _cropScreen.getMovingPoint(startDetails);
              if (_cropScreen.movingPoint.name != 'none')
                _cropScreen.showMagnifier.value = true;
            },
            onPanEnd: (details) {
              _cropScreen.movingPoint.name = 'none';
              _cropScreen.movingPoint.offset = Offset.zero;
              _cropScreen.showMagnifier.value = false;
            },
            child: Container(
              // width: _cropScreen.screenSize.width,
              // height: _cropScreen.screenSize.height,
              color: OSColors.chromeBackground,
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(13),
                    alignment: Alignment.center,
                    child: !cropLoading
                        ? TweenAnimationBuilder(
                            tween: Tween(
                                begin: 1.0,
                                end: _cropScreen.scaleImage
                                    ? _cropScreen.aspectRatio
                                    : 1.0),
                            duration: Duration(milliseconds: 100),
                            builder: ((_, double scale, __) {
                              return Transform.rotate(
                                angle: _cropScreen.rotationAngle,
                                child: Transform.scale(
                                  scale: scale,
                                  child: Image(
                                    key: _cropScreen.imageKey,
                                    image: FileImage(_cropScreen.imageFile!),
                                    loadingBuilder:
                                        ((context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      );
                                    }),
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.error_rounded,
                                          color: Colors.red,
                                          size: 30,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }),
                          )
                        : CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _cropScreen.detectionState,
                    builder: (context, CropDetectionState state, _) {
                      if (state == CropDetectionState.loading) {
                        return Positioned.fill(
                          child: Container(
                            color: OSColors.chromeBackground
                                .withValues(alpha: 0.7),
                            child: Center(
                              child:
                                  CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        );
                      }

                      if (!_cropScreen.imageRendered.value) return Container();

                      return Positioned.fill(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ValueListenableBuilder(
                                  valueListenable: _cropScreen.updatedPoint,
                                  builder: (context, _updatedPoint, _) {
                                    return CustomPaint(
                                      painter: PolygonPainter(
                                        accent: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        tl: _cropScreen.tl,
                                        tr: _cropScreen.tr,
                                        bl: _cropScreen.bl,
                                        br: _cropScreen.br,
                                        t: _cropScreen.t,
                                        l: _cropScreen.l,
                                        b: _cropScreen.b,
                                        r: _cropScreen.r,
                                      ),
                                    );
                                  }),
                            ),
                            if (state == CropDetectionState.notFound &&
                                _showNotFoundBanner)
                              Positioned(
                                top: 12,
                                left: 12,
                                right: 12,
                                child: Material(
                                  color: context.os.warning
                                      .withValues(alpha: 0.16),
                                  borderRadius:
                                      BorderRadius.circular(OSRadius.card),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "Couldn't detect edges automatically — adjust the corners below.",
                                            style: OSTypography.caption
                                                .copyWith(
                                                    color: OSColors
                                                        .chromeOnBackground),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close,
                                              color: Colors.white, size: 18),
                                          onPressed: () => setState(() =>
                                              _showNotFoundBanner = false),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: _cropScreen.showMagnifier,
                    builder: (context, bool _showMagnifier, _) {
                      if (_showMagnifier)
                        return ValueListenableBuilder(
                          valueListenable: _cropScreen.updatedPoint,
                          builder:
                              (context, DragUpdateDetails _updatedPoint, _) {
                            return Positioned(
                              left: _cropScreen.movingPoint.offset!.dx - 40,
                              top: _cropScreen.movingPoint.offset!.dy - 120,
                              child: RawMagnifier(
                                decoration: MagnifierDecoration(
                                  shadows: const <BoxShadow>[
                                    BoxShadow(
                                        blurRadius: 1.5,
                                        offset: Offset(0, 2),
                                        spreadRadius: 1,
                                        color: Color.fromARGB(25, 0, 0, 0))
                                  ],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    side: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: .15,
                                    ),
                                  ),
                                ),
                                size: Size(80, 80),
                                magnificationScale: 1.5,
                                focalPointOffset: Offset(0, 80),
                              ),
                            );
                          },
                        );
                      return Container();
                    },
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: bottomBar(),
        ),
      ),
    );
  }

  /// The primary action, in the app bar rather than the bottom row: the
  /// row below is for adjusting the quad, and Next is the thing you press
  /// when you are done adjusting it.
  Widget nextAction() {
    return ValueListenableBuilder(
      valueListenable: _cropScreen.imageRendered,
      builder: (context, bool imageRendered, _) {
        final enabled = imageRendered && !cropLoading;
        return TextButton(
          onPressed: enabled ? _cropAndPop : null,
          child: Text(
            AppLocalizations.of(context)!.next,
            style: OSTypography.label.copyWith(
              fontWeight: FontWeight.w700,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : OSColors.chromeMuted,
            ),
          ),
        );
      },
    );
  }

  Future<void> _cropAndPop() async {
    setState(() => cropLoading = true);
    final result = await _cropScreen.crop();
    if (!mounted) return;
    setState(() => cropLoading = false);

    if (result is CropSuccess) {
      Navigator.pop(context, _cropScreen.imageFile);
    } else if (result is CropFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't crop the image — please try again.")),
      );
    }
  }

  /// Rotates the page a quarter turn, keeping the polygon canvas in step.
  void _rotate() {
    setState(() {
      _cropScreen.rotationAngle =
          (_cropScreen.rotationAngle + pi / 2) % (2 * pi);
      debugPrint(
          'rotationAngle => ${vector.degrees(_cropScreen.rotationAngle)}');

      /// Scaling image before rotation- solves Transform.rotate issue
      _cropScreen.scaleImage = _cropScreen.rotationAngle % pi == pi / 2;

      /// Updates canvas size to be passed to PolygonBuilder
      _cropScreen.canvasSize = _cropScreen.scaleImage
          ? Size(_cropScreen.canvasSize.height * _cropScreen.aspectRatio,
              _cropScreen.canvasSize.width * _cropScreen.aspectRatio)
          : _cropScreen.imageBox.size;
    });
  }

  Widget bottomBar() {
    return Container(
      color: OSColors.chromeBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: OSSpace.sm, vertical: OSSpace.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _CropAction(
                icon: Icons.auto_awesome_rounded,
                label: 'Automatic crop',
                accent: true,
                onPressed: () => setState(_cropScreen.initPoints),
              ),
              _CropAction(
                icon: Icons.crop_free_rounded,
                label: 'No crop',
                onPressed: () => setState(_cropScreen.resetPointsToCorners),
              ),
              _CropAction(
                icon: Icons.rotate_right_rounded,
                label: 'Rotate',
                onPressed: _rotate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One control in the crop screen's action row.
class _CropAction extends StatelessWidget {
  const _CropAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// Marks the suggested action, so "Automatic crop" reads as the one to
  /// reach for when the corners have been dragged somewhere wrong.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color =
        accent ? Theme.of(context).colorScheme.primary : OSColors.chromeOnBackground;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(OSRadius.card),
      child: Container(
        constraints: const BoxConstraints(minWidth: 88, minHeight: 48),
        padding: const EdgeInsets.symmetric(
            horizontal: OSSpace.sm, vertical: OSSpace.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: OSSpace.xs),
            Text(label, style: OSTypography.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
