import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openscan/core/data/native_android_util.dart';
import 'package:openscan/view/Widgets/cropper/polygon_builder.dart';
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

class _CropImageState extends State<CropImage>
    with SingleTickerProviderStateMixin {
  final GlobalKey imageKey = GlobalKey();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Size imageSizeNative = Size(600.0, 600.0);
  bool hasWidgetLoaded = false;
  bool isLoading = false;
  File? imageFile;
  double aspectRatio = 1;
  bool scaleImage = false;
  Size? imageSize;
  late RenderBox imageBox;
  double verticalScaleFactor = 1;
  double horizontalScaleFactor = 1;
  late Size screenSize;
  Size canvasSize = Size(0, 0);
  Size originalCanvasSize = Size(0, 0);

  /// Notifies polygon builder when image is rotated
  ValueNotifier<double> rotationAngle = ValueNotifier(0);

  /// Notifies polygon builder when points are moved manually
  ValueNotifier<dynamic> updatedPoints = ValueNotifier(DragUpdateDetails(
    globalPosition: Offset(0, 0),
    localPosition: Offset(0, 0),
  ));

  /// Notifies polygon builder when document is detected
  ValueNotifier<Offset> tl = ValueNotifier(Offset(0, 0));
  Offset? tr, bl, br = Offset(0, 0);
  bool? cornersDetected;

  /// Reads image size
  getSize() async {
    var decodedImage = await decodeImageFromList(imageFile!.readAsBytesSync());
    imageSize =
        Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
    aspectRatio = imageSize!.width / imageSize!.height;
    getRenderedBoxSize();
    print(
        'Orginal Image=> ${imageSize!.width} / ${imageSize!.height} = $aspectRatio');
  }

  /// Gets the size of image canvas
  getRenderedBoxSize() {
    imageBox = imageKey.currentContext!.findRenderObject() as RenderBox;
    originalCanvasSize = imageBox.size;
    canvasSize = originalCanvasSize;
    print('Renderbox=> $canvasSize=> ${canvasSize.width / canvasSize.height}');

    verticalScaleFactor = screenSize.height / imageBox.size.width;
    print('VerticalScaleFactor=> $verticalScaleFactor');

    horizontalScaleFactor = screenSize.width / imageBox.size.height;
    print('HorizontalScaleFactor=> $horizontalScaleFactor');

    setState(() {
      hasWidgetLoaded = true;
    });
  }

  /// Crops the image and returns the image
  crop() async {
    setState(() {
      isLoading = true;
    });

    Map imageSize = await NativeAndroidUtil.getImageSize(imageFile!.path);

    imageSizeNative =
        Size(imageSize['width']!.toDouble(), imageSize['height']!.toDouble());

    print(
        'Android Image size => ${imageSizeNative.width}/${imageSizeNative.height}');

    // TODO: Rotate [rotationAngle] and crop image

    // double tlX = (imageBitmapSize.width / width!) * tl!.dx;
    // double trX = (imageBitmapSize.width / width!) * tr!.dx;
    // double blX = (imageBitmapSize.width / width!) * bl!.dx;
    // double brX = (imageBitmapSize.width / width!) * br!.dx;

    // double tlY = (imageBitmapSize.height / height!) * tl!.dy;
    // double trY = (imageBitmapSize.height / height!) * tr!.dy;
    // double blY = (imageBitmapSize.height / height!) * bl!.dy;
    // double brY = (imageBitmapSize.height / height!) * br!.dy;

    // await channel.invokeMethod('cropImage', {
    //   'path': imageFile!.path,
    //   'tl_x': tlX,
    //   'tl_y': tlY,
    //   'tr_x': trX,
    //   'tr_y': trY,
    //   'bl_x': blX,
    //   'bl_y': blY,
    //   'br_x': brX,
    //   'br_y': brY,
    // });

    print('cropper: ${imageFile!.path}');
    Navigator.pop(context, imageFile);
  }

  /// Document points are detected
  detectDocument() async {
    await getSize();

    List pointsData = await NativeAndroidUtil.detectDocument(imageFile!.path);
    print('Points => $pointsData');

    if (pointsData.isEmpty) {
      setState(() {
        cornersDetected = false;
      });
    } else {
      setState(() {
        cornersDetected = true;

        /// PointsData: [br,tr,tl,bl]: (width, height)
        tl.value = Offset(
            (pointsData[0][0] / imageSize!.width) * canvasSize.width,
            (pointsData[0][1] / imageSize!.height) * canvasSize.height);
        tr = Offset((pointsData[1][0] / imageSize!.width) * canvasSize.width,
            (pointsData[1][1] / imageSize!.height) * canvasSize.height);
        br = Offset((pointsData[2][0] / imageSize!.width) * canvasSize.width,
            (pointsData[2][1] / imageSize!.height) * canvasSize.height);
        bl = Offset((pointsData[3][0] / imageSize!.width) * canvasSize.width,
            (pointsData[3][1] / imageSize!.height) * canvasSize.height);

        updatedPoints.value = DragUpdateDetails(
          globalPosition: Offset(0, 0),
          localPosition: Offset(0, 0),
        );
      });
    }
  }

  bool change_height = true;
  late AnimationController _imageAnimation;

  @override
  initState() {
    super.initState();
    imageFile = widget.file;
    detectDocument();
    _imageAnimation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    print('Screen size=> ${screenSize.width} / ${screenSize.height}');
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
            // title: Text(
            //   AppLocalizations.of(context)!.crop_image,
            //   style: TextStyle().appBarStyle,
            // ),
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
          body: Container(
            padding: EdgeInsets.all(10),
            alignment: Alignment.center,
            child: !isLoading
                ? TweenAnimationBuilder(
                    tween:
                        Tween(begin: 1.0, end: scaleImage ? aspectRatio : 1.0),
                    duration: Duration(milliseconds: 100),
                    builder: ((_, double scale, __) {
                      return Transform.rotate(
                        angle: rotationAngle.value,
                        child: Transform.scale(
                          scale: scale,
                          child: PreviewImage(
                            imageKey: imageKey,
                            imageFile: imageFile,
                            cornersDetected: cornersDetected,
                            hasWidgetLoaded: hasWidgetLoaded,
                            tl: tl,
                            updatedPoints: updatedPoints,
                            rotationAngle: rotationAngle,
                            canvasSize: canvasSize,
                            originalCanvasSize: originalCanvasSize,
                            tr: tr,
                            bl: bl,
                            br: br,
                          ),
                        ),
                      );
                    }
                        // child: Transform.rotate(
                        //   angle: rotationAngle.value,
                        //   child: Transform.scale(
                        //     scale: scaleImage ? aspectRatio : 1,
                        //     child: Image(
                        //       key: imageKey,
                        //       image: FileImage(imageFile!),
                        //       loadingBuilder: ((context, child, loadingProgress) {
                        //         if (loadingProgress == null) return child;
                        //         return Center(
                        //           child: CircularProgressIndicator(
                        //             color: Colors.white,
                        //           ),
                        //         );
                        //       }),
                        //       errorBuilder: (context, error, stackTrace) {
                        //         return Center(
                        //           child: Icon(
                        //             Icons.error_rounded,
                        //             color: Colors.red,
                        //             size: 30,
                        //           ),
                        //         );
                        //       },
                        //     ),
                        //   ),
                        ),
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

  @override
  void dispose() {
    _imageAnimation.dispose();
    super.dispose();
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
            color: Theme.of(context).colorScheme.secondary,
            child: Icon(Icons.rotate_left_rounded),
            onPressed: () async {
              setState(() {
                /// Subtracting 90* from image rotation
                rotationAngle.value = (rotationAngle.value - pi / 2) % (2 * pi);
                print('rotationAngle => ${rotationAngle.value}');

                /// Scaling image before rotation- solves Transform.rotate issue
                scaleImage = rotationAngle.value % pi == pi / 2;
                print(scaleImage);

                /// Updates canvas size that is passed to PolygonBuilder
                canvasSize = scaleImage
                    ? Size(canvasSize.height * aspectRatio,
                        canvasSize.width * aspectRatio)
                    : imageBox.size;
                print(canvasSize);
              });
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: MaterialButton(
              child: Icon(Icons.rotate_right_rounded),
              color: Theme.of(context).colorScheme.secondary,
              onPressed: () async {
                setState(() {
                  /// Adding 90* to image rotation
                  rotationAngle.value =
                      (rotationAngle.value + pi / 2) % (2 * pi);
                  print(
                      'rotationAngle => ${vector.degrees(rotationAngle.value)}');

                  /// Scaling image before rotation- solves Transform.rotate issue
                  scaleImage = rotationAngle.value % pi == pi / 2;
                  print(scaleImage);

                  /// Updates canvas size to be passed to PolygonBuilder
                  canvasSize = scaleImage
                      ? Size(canvasSize.height * aspectRatio,
                          canvasSize.width * aspectRatio)
                      : imageBox.size;
                  print(canvasSize);
                });
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4.0,
            ),
            child: Container(
              child: MaterialButton(
                onPressed: () => crop(),
                color: hasWidgetLoaded || !isLoading
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                disabledColor:
                    Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                disabledTextColor: Colors.white.withOpacity(0.5),
                child: Text(
                  AppLocalizations.of(context)!.next,
                  style: TextStyle(
                    color: hasWidgetLoaded || !isLoading
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class PreviewImage extends StatelessWidget {
  const PreviewImage({
    Key? key,
    required this.imageKey,
    required this.imageFile,
    required this.cornersDetected,
    required this.hasWidgetLoaded,
    required this.tl,
    required this.updatedPoints,
    required this.rotationAngle,
    required this.canvasSize,
    required this.originalCanvasSize,
    required this.tr,
    required this.bl,
    required this.br,
  }) : super(key: key);

  final GlobalKey<State<StatefulWidget>> imageKey;
  final File? imageFile;
  final bool? cornersDetected;
  final bool hasWidgetLoaded;
  final ValueNotifier<Offset> tl;
  final ValueNotifier updatedPoints;
  final ValueNotifier<double> rotationAngle;
  final Size canvasSize;
  final Size originalCanvasSize;
  final Offset? tr;
  final Offset? bl;
  final Offset? br;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (points) => updatedPoints.value = points,
      onPanUpdate: (points) => updatedPoints.value = points,
      child: Container(
        color: Colors.amber,
        padding: EdgeInsets.all(15),
        child: Stack(
          children: [
            Image(
              key: imageKey,
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
            cornersDetected != null
                ? hasWidgetLoaded
                    ? Positioned.fill(
                        child: ValueListenableBuilder(
                            valueListenable: updatedPoints,
                            builder: (context, _updatedPoints, child) {
                              return PolygonBuilder(
                                canvasSize: canvasSize,
                                originalCanvasSize: originalCanvasSize,
                                updatedPoints: _updatedPoints,
                                rotationAngle: 0,
                                documentDetected: cornersDetected!,
                                tl: tl.value,
                                tr: tr,
                                bl: bl,
                                br: br,
                              );
                            }),
                      )
                    : Container()
                : Positioned.fill(
                    child: Container(
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
