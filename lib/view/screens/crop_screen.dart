import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/view/Widgets/cropper/polygon_builder.dart';
import 'package:openscan/view/extensions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vector_math/vector_math.dart' as vector;

Future<File> imageCropper(BuildContext context, File image) async {
  File? croppedImage;

  // imageFilePath = await FlutterScannerCropper.openCrop(
  //   src: image.path,
  //   dest: cacheDir.path,
  // );
  // File imageFileTemp;
  // imageFileTemp = File(
  //   "${cacheDir.path}/Pictures/${DateTime.now()}.jpg",
  // );
  // image.copySync(imageFileTemp.path);

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
  final GlobalKey imageKey = GlobalKey();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // double? width, height;
  Size imageSizeNative = Size(600.0, 600.0);
  bool hasWidgetLoaded = false;
  bool isLoading = false;
  File? imageFile;
  double aspectRatio = 1;
  bool scaleImage = false;
  double rotationAngle = 0;
  Size? imageSize;
  // Size originalCanvasSize = Size(0, 0);
  late RenderBox imageBox;
  Size? canvasSize;
  double verticalScaleFactor = 1;
  double horizontalScaleFactor = 1;
  late Size screenSize;
  ValueNotifier<dynamic> updatedPoints = ValueNotifier(DragUpdateDetails(
    globalPosition: Offset(0, 0),
    localPosition: Offset(0, 0),
  ));
  ValueNotifier<Offset> tl = ValueNotifier(Offset(0, 0));
  Offset? tr, bl, br = Offset(0, 0);
  bool? cornersDetected;

  MethodChannel channel = new MethodChannel('com.ethereal.openscan/cropper');

  @override
  initState() {
    super.initState();
    imageFile = widget.file;
    // getSize();
    detectDocument();

    /// Waiting for the widget to finish rendering so that we can get
    /// the size of the canvas. This is supposed to return the correct size
    /// of the desired widget. But it doesn't. Which is why the setPolygonPoints()
    /// is called recursively (every 200 milliseconds until the height and
    /// width are not equal to zero).
    /// The reason this is called recursively is to ensure that the dimensions
    /// are obtained even in cases where the build time of widgets is longer.
    // WidgetsBinding.instance!.addPostFrameCallback(
    //   (_) => setPolygonPoints(),
    // );
  }

  getSize() async {
    var decodedImage = await decodeImageFromList(imageFile!.readAsBytesSync());
    imageSize =
        Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
    aspectRatio = imageSize!.width / imageSize!.height;
    getRenderedBoxSize();
    print(
        'Orginal Image=> ${imageSize!.width} / ${imageSize!.height} = $aspectRatio');
  }

  // void rebuildAllChildren(BuildContext context) {
  //   void rebuild(Element el) {
  //     el.markNeedsBuild();
  //     el.visitChildren(rebuild);
  //     print('Rebuilding');
  //     WidgetsBinding.instance!.addPostFrameCallback(
  //       (_) => getRenderedBoxSize(),
  //     );
  //   }
  //   (context as Element).visitChildren(rebuild);
  // }

  /// Gets the size of the canvas
  getRenderedBoxSize() {
    imageBox = imageKey.currentContext!.findRenderObject() as RenderBox;
    canvasSize = imageBox.size;
    print(
        'Renderbox=> $canvasSize=> ${canvasSize!.width / canvasSize!.height}');

    verticalScaleFactor = screenSize.height / imageBox.size.width;
    print('VerticalScaleFactor=> $verticalScaleFactor');

    horizontalScaleFactor = screenSize.width / imageBox.size.height;
    print('HorizontalScaleFactor=> $horizontalScaleFactor');

    setState(() {
      hasWidgetLoaded = true;
    });
  }

  /// Crops the image and returns the image
  void crop() async {
    setState(() {
      isLoading = true;
    });

    Map imageSize = await channel.invokeMethod("getImageSize", {
      "path": imageFile!.path,
    });

    imageSizeNative =
        Size(imageSize['width']!.toDouble(), imageSize['height']!.toDouble());

    print(
        'Android Image size => ${imageSizeNative.width}/${imageSizeNative.height}');

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

  void detectDocument() async {
    await getSize();
    print('0 => ${tl.value}');

    // TODO run detection in separate thread and update UI accordingly
    List pointsData = await channel.invokeMethod("detectDocument", {
      "path": imageFile!.path,
    });

    print('Points => $pointsData');

    if (pointsData.isEmpty) {
      setState(() {
        cornersDetected = false;
      });
    } else {
      cornersDetected = true;

      /// PointsData: [br,tr,tl,bl]: width, height
      tl.value = Offset(
          (pointsData[0][0] / imageSize!.width) * canvasSize!.width,
          (pointsData[0][1] / imageSize!.height) * canvasSize!.height);
      bl = Offset((pointsData[1][0] / imageSize!.width) * canvasSize!.width,
          (pointsData[1][1] / imageSize!.height) * canvasSize!.height);
      br = Offset((pointsData[2][0] / imageSize!.width) * canvasSize!.width,
          (pointsData[2][1] / imageSize!.height) * canvasSize!.height);
      tr = Offset((pointsData[3][0] / imageSize!.width) * canvasSize!.width,
          (pointsData[3][1] / imageSize!.height) * canvasSize!.height);

      updatedPoints.value = DragUpdateDetails(
        globalPosition: Offset(0, 0),
        localPosition: Offset(0, 0),
      );

      setState(() {});

      print(pointsData[0][0]);
      print(imageSize!.width);
      print(canvasSize!.width);

      print('1 => ${tl.value}');

      // points.clear();

      // for (List<dynamic> xy in pointsData) {
      //   points.add(Offset((xy[0] / imageSize.width) * canvasSize.width,
      //       (xy[1] / imageSize.height) * canvasSize.height));
      // }

      // print('Translated Points: $points');

      // updatePolygon(DragUpdateDetails(
      //   globalPosition: Offset(0, 0),
      //   localPosition: Offset(0, 0),
      // ));
    }

    print('2 => ${tl.value}');

    // Map imageSizeMap = await channel.invokeMethod("getImageSize", {
    //   "path": imageFile!.path,
    // });

    // imageSizeNative =
    //     Size(imageSizeMap['width']!.toDouble(), imageSizeMap['height']!.toDouble());

    // double tlX = (tl!.dx / imageBitmapSize.width) * height!;
    // double trX = (tr!.dx / imageBitmapSize.width) * height!;
    // double blX = (bl!.dx / imageBitmapSize.width) * height!;
    // double brX = (br!.dx / imageBitmapSize.width) * height!;

    // double tlY = (tl!.dy / imageBitmapSize.height) * width!;
    // double trY = (tr!.dy / imageBitmapSize.height) * width!;
    // double blY = (bl!.dy / imageBitmapSize.height) * width!;
    // double brY = (br!.dy / imageBitmapSize.height) * width!;

    // tl = Offset(tlX, tlY);
    // bl = Offset(blX, blY);
    // br = Offset(brX, brY);
    // tr = Offset(trX, trY);

    // print('2');
    // print('$tl, $bl, $br, $tr');
    // print('$width, $height');

    // print('${(pointsData[0][0] / width)}');
    // print('imageSize => width $width h $height');
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
            title: Text(
              AppLocalizations.of(context)!.crop_image,
              style: TextStyle().appBarStyle,
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
            // actions: [
            //   IconButton(
            //     onPressed: detectDocument,
            //     icon: Icon(Icons.document_scanner_rounded),
            //   ),
            // ],
          ),
          body: Container(
            padding: EdgeInsets.all(20),
            alignment: Alignment.center,
            child: !isLoading
                ? GestureDetector(
                    onPanDown: (points) => updatedPoints.value = points,
                    onPanUpdate: (points) => updatedPoints.value = points,
                    child: Stack(
                      alignment: Alignment.topLeft,
                      children: <Widget>[
                        Transform.rotate(
                          angle: rotationAngle,
                          child: Transform.scale(
                            scale: scaleImage ? aspectRatio : 1,
                            child: Image(
                              key: imageKey,
                              image: FileImage(imageFile!),
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
                        ),
                        cornersDetected == null
                            ? Positioned.fill(
                                child: Container(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.7),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white),
                                  ),
                                ),
                              )
                            : hasWidgetLoaded
                                ? ValueListenableBuilder<Offset>(
                                    valueListenable: tl,
                                    builder: (BuildContext context, Offset tl,
                                        Widget? child) {
                                      print('3 => $tl');
                                      return ValueListenableBuilder<dynamic>(
                                          valueListenable: updatedPoints,
                                          builder: (BuildContext context,
                                              dynamic updatedPoints,
                                              Widget? child) {
                                            return PolygonBuilder(
                                              canvasSize: canvasSize!,
                                              updatedPoints: updatedPoints,
                                              documentDetected:
                                                  cornersDetected!,
                                              tl: tl,
                                              tr: tr,
                                              bl: bl,
                                              br: br,
                                            );
                                          });
                                    })
                                : Container(),
                      ],
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
                rotationAngle = (rotationAngle - pi / 2) % (2 * pi);
                print('rotationAngle=> ${vector.degrees(rotationAngle)}');

                /// Scaling image before rotation- solves Transform.rotate issue
                scaleImage = rotationAngle % pi == pi / 2;
                print(scaleImage);

                /// Updates canvas size that is passed to PolygonBuilder
                canvasSize = scaleImage
                    ? Size(canvasSize!.height * aspectRatio,
                        canvasSize!.width * aspectRatio)
                    : imageBox.size;
                print(canvasSize);
              });

              // File tempImageFile = File(imageFile!.path
              //         .substring(0, imageFile!.path.lastIndexOf('.')) +
              //     'r.jpg');
              // imageFile!.copySync(tempImageFile.path);
              // await channel.invokeMethod("rotateImage", {
              //   'path': tempImageFile.path,
              //   'degree': -90,
              // });
              // print('Rotated left');
              // setState(() {
              //   // tempImageFile.copySync(imageFile.path);
              //   imageFile = File(tempImageFile.path);
              // });
              // WidgetsBinding.instance!.addPostFrameCallback(
              //   (_) => getImageSize(false),
              // );
              // tempImageFile.deleteSync();
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
                  rotationAngle = (rotationAngle + pi / 2) % (2 * pi);
                  print('rotationAngle=> ${vector.degrees(rotationAngle)}');

                  /// Scaling image before rotation- solves Transform.rotate issue
                  scaleImage = rotationAngle % pi == pi / 2;
                  print(scaleImage);

                  /// Updates canvas size to be passed to PolygonBuilder
                  canvasSize = scaleImage
                      ? Size(canvasSize!.height * aspectRatio,
                          canvasSize!.width * aspectRatio)
                      : imageBox.size;
                  print(canvasSize);
                });

                // File tempImageFile = File(imageFile!.path
                //         .substring(0, imageFile!.path.lastIndexOf('.')) +
                //     'r.jpg');
                // imageFile!.copySync(tempImageFile.path);
                // await channel.invokeMethod("rotateImage", {
                //   'path': tempImageFile.path,
                //   'degree': 90,
                // });
                // print('Rotated right');
                // setState(() {
                //   // tempImageFile.copySync(imageFile.path);
                //   imageFile = File(tempImageFile.path);
                // });
                // WidgetsBinding.instance!.addPostFrameCallback(
                //   (_) => setPolygonPoints(),
                // );
                // rebuildAllChildren(context);
                // tempImageFile.deleteSync();
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
