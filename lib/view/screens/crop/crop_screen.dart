import 'dart:async';
import 'dart:io';
import 'dart:math' show Point;
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openscan/view/Widgets/cropper/polygon_painter.dart';
import 'package:openscan/view/screens/crop/crop_screen_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:openscan/core/data/native_android_util.dart';
import 'package:openscan/view/Widgets/hovering_snackbar.dart';

Future<File?> imageCropper(
  BuildContext context,
  File srcImage,
) async {
  Directory cacheDir = await getTemporaryDirectory();
  File resultImage = File(
    cacheDir.path + '/' + DateTime.now().toString() + '.jpg',
  );

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CropImage(
        srcImage: srcImage,
        destImage: resultImage,
      ),
    ),
  );

  // Return null if crop was cancelled or failed
  if (result == null) {
    return null;
  }

  // Verify the result file exists and has content
  if (!await resultImage.exists() || await resultImage.length() == 0) {
    return null;
  }

  return resultImage;
}

class CropImage extends StatefulWidget {
  final File? srcImage;
  final File? destImage;

  const CropImage({
    Key? key,
    this.srcImage,
    this.destImage,
  }) : super(key: key);

  @override
  _CropImageState createState() => _CropImageState();
}

class _CropImageState extends State<CropImage> {
  late final CropScreenState _cropScreen;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _cropScreen = CropScreenState();
    _initializeCropScreen();
  }

  Future<void> _initializeCropScreen() async {
    if (widget.srcImage == null || widget.destImage == null) {
      Navigator.pop(context, null);
      return;
    }

    await _cropScreen.initialize(widget.srcImage!, widget.destImage!);
  }

  @override
  Widget build(BuildContext context) {
    _cropScreen.screenSize = MediaQuery.of(context).size;

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, null);
          return false;
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).primaryColor,
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.crop,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            centerTitle: true,
            elevation: 0.0,
            backgroundColor: Theme.of(context).primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              padding: const EdgeInsets.fromLTRB(15, 8, 0, 8),
              onPressed: () => Navigator.pop(context, null),
            ),
          ),
          body: ValueListenableBuilder<CropScreenStatus>(
            valueListenable: _cropScreen.status,
            builder: (context, status, _) {
              switch (status) {
                case CropScreenStatus.initial:
                case CropScreenStatus.loading:
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                case CropScreenStatus.error:
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _cropScreen.errorMessage ?? 'An error occurred',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializeCropScreen,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                case CropScreenStatus.ready:
                case CropScreenStatus.processing:
                  return _buildCropContent();
              }
            },
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildCropContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _cropScreen.screenSize = Size(constraints.maxWidth, constraints.maxHeight);
    return Container(
      color: Theme.of(context).primaryColor,
          child: Column(
            children: [
              Expanded(
      child: Stack(
        children: [
                    // Image Container (no padding)
                    Center(
            child: Image(
              key: _cropScreen.imageKey,
              image: FileImage(_cropScreen.srcImage!, scale: 1.0),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _cropScreen.getSize().catchError((error) {
                      print('Error getting size: $error');
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _cropScreen.getSize().catchError((e) {
                          print('Error getting size after retry: $e');
                        });
                      });
                    });
                  });
                  return child;
                }
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.error_rounded,
                    color: Colors.red,
                    size: 30,
                  ),
                );
              },
            ),
          ),

          // Points Container
          ValueListenableBuilder(
            valueListenable: _cropScreen.renderBoxReady,
            builder: (BuildContext context, bool value, Widget? child) {
                        if (!value || _cropScreen.displayedImageRect == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              }

                        final rect = _cropScreen.displayedImageRect!;
                        return Positioned(
                          left: rect.left,
                          top: rect.top,
                          width: rect.width,
                          height: rect.height,
                child: GestureDetector(
                  key: _cropScreen.bodyKey,
                            behavior: HitTestBehavior.translucent,
                  onPanStart: (startDetails) {
                    _cropScreen.calculateAllSlopes();
                    _cropScreen.onPanStart(startDetails);
                    if (_cropScreen.movingPoint.name != 'none') {
                      _cropScreen.showMagnifier.value = true;
                      final pointOffsetInCanvas = _cropScreen.getMovingPointOffset();
                      final canvasOffset = _cropScreen.displayedImageRect!.topLeft;
                      _cropScreen.magnifierPosition.value = pointOffsetInCanvas + canvasOffset;
                    }
                  },
                  onPanUpdate: (updateDetails) {
                    _cropScreen.updatedPoint.value = updateDetails;
                    _cropScreen.updatePolygon();
                    final pointOffsetInCanvas = _cropScreen.getMovingPointOffset();
                    final canvasOffset = _cropScreen.displayedImageRect!.topLeft;
                    _cropScreen.magnifierPosition.value = pointOffsetInCanvas + canvasOffset;
                  },
                  onPanEnd: (details) {
                    _cropScreen.movingPoint.name = 'none';
                    _cropScreen.movingPoint.offset = Point<num>(0, 0);
                    _cropScreen.showMagnifier.value = false;
                    _cropScreen.magnifierPosition.value = null;
                  },
                  child: ValueListenableBuilder(
                              valueListenable: _cropScreen.polygonVersion,
                    builder: (context, _, __) {
                      return CustomPaint(
                                  size: Size(rect.width, rect.height),
                        painter: PolygonPainter(
                                    tl: Offset(_cropScreen.tl.x.toDouble(), _cropScreen.tl.y.toDouble()),
                                    tr: Offset(_cropScreen.tr.x.toDouble(), _cropScreen.tr.y.toDouble()),
                                    bl: Offset(_cropScreen.bl.x.toDouble(), _cropScreen.bl.y.toDouble()),
                                    br: Offset(_cropScreen.br.x.toDouble(), _cropScreen.br.y.toDouble()),
                                    t: Offset(_cropScreen.t.x.toDouble(), _cropScreen.t.y.toDouble()),
                                    l: Offset(_cropScreen.l.x.toDouble(), _cropScreen.l.y.toDouble()),
                                    b: Offset(_cropScreen.b.x.toDouble(), _cropScreen.b.y.toDouble()),
                                    r: Offset(_cropScreen.r.x.toDouble(), _cropScreen.r.y.toDouble()),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Magnifier Container
          ValueListenableBuilder<Offset?>(
            valueListenable: _cropScreen.magnifierPosition,
            builder: (context, dragOffset, __) {
              if (dragOffset == null || _cropScreen.movingPoint.name == 'none') {
                return const SizedBox.shrink();
              }

              const magnifierSize = 80.0;
              const verticalOffset = 30.0; // Doubled the space between magnifier and point

              // Determine horizontal offset based on which side the point is on
              double horizontalOffset = 0.0;
              if (_cropScreen.movingPoint.name != null) {
                final pointName = _cropScreen.movingPoint.name!;
                if (pointName.contains('r') || pointName == 'tr' || pointName == 'br') {
                  // Right-side points: offset magnifier to the left
                  horizontalOffset = -20.0;
                } else if (pointName.contains('l') || pointName == 'tl' || pointName == 'bl') {
                  // Left-side points: offset magnifier to the right
                  horizontalOffset = 20.0;
                }
              }

              return Positioned(
                left: dragOffset.dx - (magnifierSize / 2) + horizontalOffset,
                top: dragOffset.dy - magnifierSize - verticalOffset,
                child: RawMagnifier(
                  size: const Size(magnifierSize, magnifierSize),
                  decoration: const MagnifierDecoration(
                    shape: CircleBorder(),
                  ),
                  magnificationScale: 2,
                  focalPointOffset:
                      Offset(-horizontalOffset, magnifierSize / 2 + verticalOffset),
                ),
              );
            },
          ),
        ],
      ),
    ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _buildBottomBarButton(
            icon: Icons.aspect_ratio_rounded,
            label: 'No Crop',
            onPressed: () {
              _cropScreen.setPointsToDisplayedImageRect();
              setState(() {});
            },
          ),
          _buildBottomBarButton(
            icon: Icons.document_scanner_rounded,
            label: 'Auto-Detect',
            onPressed: () async {
              await _cropScreen.handleAutoDetect();
              setState(() {});
            },
          ),
          _buildBottomBarButton(
            icon: Icons.done,
            label: 'Done',
            onPressed: () async {
              if (_cropScreen.renderBoxReady.value) {
                bool success = await _cropScreen.crop();
                if (success) {
                  Navigator.pop(context, _cropScreen.destImage);
                } else {
                  HoveringSnackBarHelper.showError(
                    context,
                    message: AppLocalizations.of(context)!.cropFailed,
                  );
                }
              }
            },
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return MaterialButton(
      elevation: 0,
      highlightElevation: 0,
      color: isPrimary
          ? Theme.of(context).colorScheme.secondary
          : Colors.transparent,
      splashColor: Colors.transparent,
      disabledColor: isPrimary
          ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
          : null,
      disabledTextColor: Colors.white.withOpacity(0.5),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          Text(
            label,
            style: const TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }
}
