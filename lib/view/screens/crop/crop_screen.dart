import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openscan/core/cv/models/detection_result.dart';
import 'package:openscan/core/settings/app_settings.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/view/Widgets/cropper/polygon_painter.dart';
import 'package:openscan/view/screens/crop/crop_screen_state.dart';

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

/// Breathing room between the page and the edge of the screen.
const double _kCanvasPadding = 20.0;

/// Radius of the corner handles the polygon painter draws, so the side
/// padding can keep the whole dot out of the system gesture strip.
const double _kHandleRadius = 10.0;

class CropImage extends StatefulWidget {
  final File? file;

  CropImage({this.file});

  _CropImageState createState() => _CropImageState();
}

class _CropImageState extends State<CropImage>
    with SingleTickerProviderStateMixin {
  CropScreenState _cropScreen = CropScreenState();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool cropLoading = false;

  /// Drives the quarter-turn animation. One controller for the whole
  /// screen, rather than an implicit animation on the image alone: the
  /// polygon overlay and the magnifier are painted outside the image's
  /// subtree and have to be redrawn at the same angle on every frame of
  /// the turn, or they visibly lag the page they belong to.
  late final AnimationController _turnController = AnimationController(
    vsync: this,
    duration: OSMotion.standard,
  );
  Animation<double> _turnAnimation = const AlwaysStoppedAnimation(0);

  double get _animatedTurns => _turnAnimation.value;

  @override
  void dispose() {
    _turnController.dispose();
    super.dispose();
  }

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

    // On gesture navigation the system reserves a strip down each side of
    // the display for the back swipe. A touch that starts inside that
    // strip never reaches this screen's GestureDetector — dragging a
    // corner there pops the route instead of moving the point. Widening
    // the inset past that strip fixes it, at the cost of page width on
    // every scan, so it is the "Avoid back-gesture strip" setting rather
    // than the default. The dot's own radius is added on top of the strip
    // so the whole handle (not just its centre) sits clear of it.
    final gestureInsets = MediaQuery.of(context).systemGestureInsets;
    final avoidStrip = AppSettings.instance.avoidGestureStrip;
    final sidePadding = EdgeInsets.only(
      left: avoidStrip
          ? max(_kCanvasPadding, gestureInsets.left + _kHandleRadius)
          : _kCanvasPadding,
      right: avoidStrip
          ? max(_kCanvasPadding, gestureInsets.right + _kHandleRadius)
          : _kCanvasPadding,
      top: _kCanvasPadding,
      bottom: _kCanvasPadding,
    );
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
              // Touches land on the page as it is being shown; the polygon
              // lives in the page's own unrotated coordinates.
              _cropScreen.updatedPoint.value = DragUpdateDetails(
                globalPosition: updateDetails.globalPosition,
                localPosition:
                    _cropScreen.fromDisplay(updateDetails.localPosition),
                delta: updateDetails.delta,
              );
              _cropScreen.updatePolygon();
            },
            onPanStart: (startDetails) {
              _cropScreen.calculateAllSlopes();
              _cropScreen.getMovingPoint(DragStartDetails(
                globalPosition: startDetails.globalPosition,
                localPosition:
                    _cropScreen.fromDisplay(startDetails.localPosition),
              ));
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
                    padding: sidePadding,
                    alignment: Alignment.center,
                    child: !cropLoading
                        ? AnimatedBuilder(
                            animation: _turnController,
                            builder: ((_, __) {
                              return Transform.rotate(
                                angle: _animatedTurns * pi / 2,
                                child: Transform.scale(
                                  scale:
                                      _cropScreen.scaleForTurns(_animatedTurns),
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
                                    return AnimatedBuilder(
                                      animation: _turnController,
                                      builder: (context, _) {
                                        // The polygon is stored unrotated
                                        // and turned on its way to the
                                        // screen, so it describes the same
                                        // part of the photo at any angle.
                                        Offset at(Offset p) =>
                                            _cropScreen.toDisplay(p,
                                                turns: _animatedTurns);
                                        return CustomPaint(
                                          painter: PolygonPainter(
                                            accent: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            tl: at(_cropScreen.tl),
                                            tr: at(_cropScreen.tr),
                                            bl: at(_cropScreen.bl),
                                            br: at(_cropScreen.br),
                                            t: at(_cropScreen.t),
                                            l: at(_cropScreen.l),
                                            b: at(_cropScreen.b),
                                            r: at(_cropScreen.r),
                                          ),
                                        );
                                      },
                                    );
                                  }),
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
                            final at = _cropScreen
                                .toDisplay(_cropScreen.movingPoint.offset!);
                            return Positioned(
                              left: at.dx - 40,
                              top: at.dy - 120,
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

  /// Turns the page a quarter turn clockwise. The polygon is not rotated
  /// with it — it stays in the page's own unrotated coordinates and is
  /// transformed on its way to the screen, so the corners keep describing
  /// the same part of the photo however the page is being shown.
  void _rotate() {
    final from = _animatedTurns;
    setState(() => _cropScreen.turns++);
    _turnAnimation = Tween(
      begin: from,
      end: _cropScreen.turns.toDouble(),
    ).animate(CurvedAnimation(
      parent: _turnController,
      curve: OSMotion.emphasizedDecel,
    ));
    _turnController.forward(from: 0);
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
