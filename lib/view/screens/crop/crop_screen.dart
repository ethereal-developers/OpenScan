import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openscan/view/Widgets/cropper/polygon_painter.dart';
import 'package:openscan/view/screens/crop/crop_screen_state.dart';
import 'package:vector_math/vector_math.dart' as vector;

Future<File> imageCropper(BuildContext context, File image) async {
  File? croppedImage;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CropImage(
        file: image,
      ),
    ),
  ).then((value) => croppedImage = value);
  return croppedImage ?? image;
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

  @override
  initState() {
    super.initState();
    _cropScreen.imageFile = widget.file;
    _cropScreen.detectDocument();
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
    print(
        'Screen size=> ${_cropScreen.screenSize.width} / ${_cropScreen.screenSize.height}');
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
            actions: [
              MaterialButton(
                child: Icon(Icons.document_scanner_rounded),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: () {
                  setState(() {
                    _cropScreen.setPoints();
                  });
                },
              )
            ],
          ),
          body: Container(
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
                          child: CanvasImage(
                            cropScreenState: _cropScreen,
                            imageFile: _cropScreen.imageFile,
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
                Icon(Icons.rotate_left_rounded),
                Text(
                  'Rotate Left',
                  style: TextStyle(fontSize: 9),
                )
              ],
            ),
            onPressed: () async {
              setState(() {
                /// Subtracting 90* from image rotation
                _cropScreen.rotationAngle =
                    (_cropScreen.rotationAngle - pi / 2) % (2 * pi);
                print('rotationAngle => ${_cropScreen.rotationAngle}');

                /// Scaling image before rotation- solves Transform.rotate issue
                _cropScreen.scaleImage =
                    _cropScreen.rotationAngle % pi == pi / 2;
                print(_cropScreen.scaleImage);

                /// Updates canvas size that is passed to PolygonBuilder
                _cropScreen.canvasSize = _cropScreen.scaleImage
                    ? Size(
                        _cropScreen.canvasSize.height * _cropScreen.aspectRatio,
                        _cropScreen.canvasSize.width * _cropScreen.aspectRatio)
                    : _cropScreen.imageBox.size;
                print(_cropScreen.canvasSize);
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
                Icon(Icons.rotate_right_rounded),
                Text(
                  'Rotate Right',
                  style: TextStyle(fontSize: 9),
                )
              ],
            ),
            onPressed: () async {
              setState(() {
                /// Adding 90* to image rotation
                _cropScreen.rotationAngle =
                    (_cropScreen.rotationAngle + pi / 2) % (2 * pi);
                print(
                    'rotationAngle => ${vector.degrees(_cropScreen.rotationAngle)}');

                /// Scaling image before rotation- solves Transform.rotate issue
                _cropScreen.scaleImage =
                    _cropScreen.rotationAngle % pi == pi / 2;
                print(_cropScreen.scaleImage);

                /// Updates canvas size to be passed to PolygonBuilder
                _cropScreen.canvasSize = _cropScreen.scaleImage
                    ? Size(
                        _cropScreen.canvasSize.height * _cropScreen.aspectRatio,
                        _cropScreen.canvasSize.width * _cropScreen.aspectRatio)
                    : _cropScreen.imageBox.size;
                print(_cropScreen.canvasSize);
              });
            },
          ),
          ValueListenableBuilder(
            valueListenable: _cropScreen.imageRendered,
            builder: (context, bool _imageRendered, _) {
              return MaterialButton(
                onPressed: _imageRendered ? () {
                  setState(() {
                    cropLoading = true;
                  });
                  _cropScreen.crop();
                  setState(() {
                    cropLoading = false;
                  });
                  Navigator.pop(context, _cropScreen.imageFile);
                } : () {},
                color: _imageRendered || !cropLoading
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                splashColor: Colors.transparent,
                disabledColor:
                    Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                disabledTextColor: Colors.white.withOpacity(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.next,
                      style: TextStyle(
                        color: _imageRendered || !cropLoading
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        fontSize: 18,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _imageRendered || !cropLoading
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
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

class CanvasImage extends StatelessWidget {
  const CanvasImage({
    Key? key,
    required this.cropScreenState,
    required this.imageFile,
  }) : super(key: key);

  final CropScreenState cropScreenState;
  final File? imageFile;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (updateDetails) {
        cropScreenState.updatedPoint.value = updateDetails;
        cropScreenState.updatePolygon();
      },
      onPanStart: (startDetails) {
        print('Start Point: $startDetails');
        cropScreenState.calculateAllSlopes();
        cropScreenState.getMovingPoint(startDetails);
      },
      child: Container(
        // color: Colors.amber,
        // padding: EdgeInsets.all(10),
        child: Stack(
          children: [
            Image(
              key: cropScreenState.imageKey,
              image: FileImage(imageFile!),
              loadingBuilder: ((context, child, loadingProgress) {
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
            ValueListenableBuilder(
              valueListenable: cropScreenState.detectionCompleted,
              builder: (context, _documentDetected, _) {
                if(cropScreenState.detectionCompleted.value) {
                  /// This snippet is crucial, but idk how it works
                  cropScreenState.getRenderedBoxSize();
                  cropScreenState.setPoints();
                }
                return cropScreenState.detectionCompleted.value
                    ? cropScreenState.imageRendered.value
                        ? Positioned.fill(
                            child: ValueListenableBuilder(
                                valueListenable: cropScreenState.updatedPoint,
                                builder: (context, _updatedPoint, _) {
                                  return CustomPaint(
                                    painter: PolygonPainter(
                                      tl: cropScreenState.tl,
                                      tr: cropScreenState.tr,
                                      bl: cropScreenState.bl,
                                      br: cropScreenState.br,
                                      t: cropScreenState.t,
                                      l: cropScreenState.l,
                                      b: cropScreenState.b,
                                      r: cropScreenState.r,
                                    ),
                                  );
                                }),
                          )
                        : Container()
                    : Positioned.fill(
                        child: Container(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.7),
                          child: Center(
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
