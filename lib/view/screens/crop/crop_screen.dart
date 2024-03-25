import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openscan/view/Widgets/cropper/polygon_painter.dart';
import 'package:openscan/view/screens/crop/crop_screen_state.dart';

Future<File> generateTempFileAndCropImage(BuildContext context, File srcImage, String dirPath) async {
  debugPrint("directory path --> " + dirPath);
  File temp = File(
    dirPath + '/' + DateTime.now().toString() + '.jpg',
  );
  return imageCropper(context, srcImage, temp);
}

Future<File> imageCropper(
  BuildContext context,
  File srcImage,
  File resultImage,
) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CropImage(
        srcImage: srcImage,
        destImage: resultImage,
      ),
    ),
  );
  return resultImage;
}

class CropImage extends StatefulWidget {
  final File? srcImage;
  final File? destImage;

  CropImage({this.srcImage, this.destImage});

  _CropImageState createState() => _CropImageState();
}

class _CropImageState extends State<CropImage> {
  CropScreenState _cropScreen = CropScreenState();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool cropLoading = false;

  @override
  initState() {
    super.initState();
    _cropScreen.srcImage = widget.srcImage;
    _cropScreen.destImage = widget.destImage;
    _cropScreen.canvasSize = Size(0, 0);
    _cropScreen.tl = Offset(0, 0);
    _cropScreen.tr = Offset(0, 0);
    _cropScreen.bl = Offset(0, 0);
    _cropScreen.br = Offset(0, 0);
    _cropScreen.t = Offset(0, 0);
    _cropScreen.l = Offset(0, 0);
    _cropScreen.b = Offset(0, 0);
    _cropScreen.r = Offset(0, 0);
    _cropScreen.detectDocument();
  }

  @override
  Widget build(BuildContext context) {
    _cropScreen.screenSize = MediaQuery.of(context).size;
    // debugPrint(
    //     'Screen size=> ${_cropScreen.screenSize.width} / ${_cropScreen.screenSize.height}');
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          // Navigator.pop(context, null);
          return true;
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).primaryColor,
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.crop,
              // style: TextStyle().appBarStyle,
            ),
            centerTitle: true,
            elevation: 0.0,
            backgroundColor: Theme.of(context).primaryColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              padding: EdgeInsets.fromLTRB(15, 8, 0, 8),
              onPressed: () {
                Navigator.pop(context, null);
              },
            ),
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
              color: Theme.of(context).primaryColor,
              child: Stack(
                children: [
                  /// Image Container
                  Container(
                    padding: EdgeInsets.all(13),
                    alignment: Alignment.center,
                    child: !cropLoading
                        ? TweenAnimationBuilder(
                            tween: Tween(
                              begin: 1.0,
                              end: _cropScreen.scaleImage
                                  ? _cropScreen.aspectRatio
                                  : 1.0,
                            ),
                            duration: Duration(milliseconds: 100),
                            builder: ((_, double scale, __) {
                              return Transform.scale(
                                scale: scale,
                                child: Image(
                                  key: _cropScreen.imageKey,
                                  image: FileImage(_cropScreen.srcImage!),
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

                  /// Points Container
                  ValueListenableBuilder(
                    valueListenable: _cropScreen.detectionCompleted,
                    builder: (context, bool _documentDetected, _) {
                      if (_cropScreen.isCroppingLoading) {
                        return Positioned.fill(
                          child: Container(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.7),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }
                      if (_documentDetected) {
                        /// This snippet is crucial, but idk how it works
                        _cropScreen.getRenderedBoxSize();
                        _cropScreen.initPoints();
                      }
                      return _documentDetected
                          ? _cropScreen.imageRendered.value
                              ? Positioned.fill(
                                  child: ValueListenableBuilder(
                                      valueListenable: _cropScreen.updatedPoint,
                                      builder: (context, _updatedPoint, _) {
                                        return CustomPaint(
                                          painter: PolygonPainter(
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
                                )
                              : Container()
                          : Positioned.fill(
                              child: Container(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.7),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                    },
                  ),

                  /// Magnifier Container
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

  Widget bottomBar() {
    return Container(
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          MaterialButton(
            elevation: 0,
            highlightElevation: 0,
            color: Colors.transparent,
            splashColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restore_page),
                Text(
                  // TODO: i18n
                  'Reset',
                  style: TextStyle(fontSize: 9),
                )
              ],
            ),
            onPressed: () async {
              setState(() {
                _cropScreen.isReset = true;
              });
            },
          ),
          MaterialButton(
            elevation: 0,
            highlightElevation: 0,
            color: Colors.transparent,
            splashColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.document_scanner_rounded),
                Text(
                  // TODO: i18n
                  'Auto-Detect',
                  style: TextStyle(fontSize: 9),
                )
              ],
            ),
            onPressed: () async {
              setState(() {});
            },
          ),
          ValueListenableBuilder(
            valueListenable: _cropScreen.imageRendered,
            builder: (context, bool _imageRendered, _) {
              return MaterialButton(
                onPressed: _imageRendered
                    ? () async {
                        setState(() {
                          cropLoading = true;
                          _cropScreen.isCroppingLoading = true;
                        });
                        await _cropScreen.crop();
                        Navigator.pop(context, _cropScreen.srcImage);
                      }
                    : () {},
                color: _imageRendered || !cropLoading
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                splashColor: Colors.transparent,
                disabledColor:
                    Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                disabledTextColor: Colors.white.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.done),
                    Text(
                      // TODO: i18n
                      'Done',
                      style: TextStyle(fontSize: 9),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
