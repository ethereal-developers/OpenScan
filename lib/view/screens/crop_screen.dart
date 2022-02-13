import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/view/Widgets/cropper/polygon_painter.dart';
import 'package:openscan/view/extensions.dart';

imageCropper(BuildContext context, File image) async {
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
  final GlobalKey key = GlobalKey();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  double? width, height;
  double? prevWidth, prevHeight = 0;
  Size imageBitmapSize = Size(600.0, 600.0);
  bool hasWidgetLoaded = false;
  Offset? tl, tr, bl, br, t, l, b, r;
  bool isLoading = false;
  File? imageFile;
  int crossoverThreshold = 5;
  int crossoverAdjust = 6;

  MethodChannel channel = new MethodChannel('com.ethereal.openscan/cropper');

  @override
  void initState() {
    super.initState();
    imageFile = widget.file;

    /// Waiting for the widget to finish rendering so that we can get
    /// the size of the canvas. This is supposed to return the correct size
    /// of the desired widget. But it doesn't. Which is why the getImageSize()
    /// is called recursively (every 200 milliseconds until the height and
    /// width are not equal to zero).
    ///
    /// The reason this is called recursively is to ensure that the dimensions
    /// are obtained even in cases where the build time of widgets is longer.
    WidgetsBinding.instance!.addPostFrameCallback(
      (_) => getImageSize(false),
    );
  }

  void rebuildAllChildren(BuildContext context) {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
      print('Rebuilding');
      WidgetsBinding.instance!.addPostFrameCallback(
        (_) => getImageSize(false),
      );
    }

    (context as Element).visitChildren(rebuild);
  }

  void getImageSize(isRenderBoxValuesCorrect) async {
    setState(() {
      isLoading = true;
    });
    RenderBox imageBox = key.currentContext!.findRenderObject() as RenderBox;
    width = imageBox.size.width;
    height = imageBox.size.height;

    // TODO: Doesn't work for square images
    if ((width == 0 && height == 0) ||
        (width == prevWidth && height == prevHeight)) {
      Timer(Duration(milliseconds: 100), () => getImageSize(false));
    } else {
      isRenderBoxValuesCorrect = true;
      prevHeight = height;
      prevWidth = width;
    }

    t = Offset(width! / 2, 0);
    b = Offset(width! / 2, height!);
    l = Offset(0, height! / 2);
    r = Offset(width!, height! / 2);
    tl = Offset(0, 0);
    tr = Offset(width!, 0);
    bl = Offset(0, height!);
    br = Offset(width!, height!);

    setState(() {
      isLoading = false;
      hasWidgetLoaded = true;
    });

    if (isRenderBoxValuesCorrect) return;
  }

  checkPolygon(Offset p1, Offset q1, Offset p2, Offset q2) {
    bool onSegment(Offset p, Offset q, Offset r) {
      if (q.dx <= max(p.dx, r.dx) &&
          q.dx >= min(p.dx, r.dx) &&
          q.dy <= max(p.dy, r.dy) &&
          q.dy >= min(p.dy, r.dy)) return true;
      return false;
    }

    int orientation(Offset p, Offset q, Offset r) {
      double val =
          (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);
      if (val == 0) return 0;
      return (val > 0) ? 1 : 2;
    }

    int o1 = orientation(p1, q1, p2);
    int o2 = orientation(p1, q1, q2);
    int o3 = orientation(p2, q2, p1);
    int o4 = orientation(p2, q2, q1);

    if (o1 != o2 && o3 != o4) return true;

    if (o1 == 0 && onSegment(p1, p2, q1)) return true;
    if (o2 == 0 && onSegment(p1, q2, q1)) return true;
    if (o3 == 0 && onSegment(p2, p1, q2)) return true;
    if (o4 == 0 && onSegment(p2, q1, q2)) return true;
    return false;
  }

  void updatePolygon(points) {
    double x1 = points.localPosition.dx;
    double y1 = points.localPosition.dy;
    double x2 = tl!.dx;
    double y2 = tl!.dy;
    double x3 = tr!.dx;
    double y3 = tr!.dy;
    double x4 = bl!.dx;
    double y4 = bl!.dy;
    double x5 = br!.dx;
    double y5 = br!.dy;
    double x6 = t!.dx;
    double y6 = t!.dy;
    double x7 = b!.dx;
    double y7 = b!.dy;
    double x8 = l!.dx;
    double y8 = l!.dy;
    double x9 = r!.dx;
    double y9 = r!.dy;

    if (sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height! &&
        x1 < width! &&
        x1 >= 0) {
      setState(() {
        bool isConvexPolygon = checkPolygon(
            Offset(tl!.dx - crossoverThreshold, tl!.dy + crossoverThreshold),
            br!,
            tr!,
            bl!);
        if (tl!.dx < tr!.dx - crossoverThreshold) {
          if (!isConvexPolygon) {
            tl = Offset(tl!.dx - crossoverAdjust, tl!.dy - crossoverAdjust);
          } else {
            tl = points.localPosition;
          }
        } else {
          tl = Offset(tr!.dx - crossoverAdjust, tl!.dy);
        }
        if (tl!.dy + crossoverThreshold > bl!.dy) {
          tl = Offset(tl!.dx, bl!.dy - crossoverAdjust);
        }
        t = Offset((tr!.dx + tl!.dx) / 2, (tr!.dy + tl!.dy) / 2);
        l = Offset((tl!.dx + bl!.dx) / 2, (tl!.dy + bl!.dy) / 2);
      });
    } else if (sqrt(pow((x3 - x1), 2) + pow((y3 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height! &&
        x1 < width! &&
        x1 >= 0) {
      setState(() {
        bool isConvexPolygon = checkPolygon(
            tl!,
            br!,
            Offset(tr!.dx - crossoverThreshold, tr!.dy - crossoverThreshold),
            bl!);
        if (tr!.dx > tl!.dx + crossoverThreshold) {
          if (!isConvexPolygon) {
            tr = Offset(tr!.dx + crossoverAdjust, tr!.dy - crossoverAdjust);
          } else {
            tr = points.localPosition;
          }
        } else {
          tr = Offset(tr!.dx + crossoverAdjust, tr!.dy);
        }
        if (tr!.dy + crossoverThreshold > br!.dy) {
          tr = Offset(tr!.dx, br!.dy - crossoverAdjust);
        }
        t = Offset((tr!.dx + tl!.dx) / 2, (tr!.dy + tl!.dy) / 2);
        r = Offset((tr!.dx + br!.dx) / 2, (tr!.dy + br!.dy) / 2);
      });
    } else if (sqrt(pow((x4 - x1), 2) + pow((y4 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height! &&
        x1 < width! &&
        x1 >= 0) {
      setState(() {
        bool isConvexPolygon = checkPolygon(tl!, br!, tr!,
            Offset(bl!.dx + crossoverThreshold, bl!.dy - crossoverThreshold));
        if (bl!.dx < br!.dx - crossoverThreshold) {
          if (!isConvexPolygon) {
            bl = Offset(bl!.dx - crossoverAdjust, bl!.dy + crossoverAdjust);
          } else {
            bl = points.localPosition;
          }
        } else {
          bl = Offset(br!.dx - crossoverAdjust, bl!.dy);
        }
        if (bl!.dy - crossoverThreshold < tl!.dy) {
          bl = Offset(bl!.dx, tl!.dy + crossoverAdjust);
        }
        l = Offset((tl!.dx + bl!.dx) / 2, (tl!.dy + bl!.dy) / 2);
        b = Offset((br!.dx + bl!.dx) / 2, (br!.dy + bl!.dy) / 2);
      });
    } else if (sqrt(pow((x5 - x1), 2) + pow((y5 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height! &&
        x1 < width! &&
        x1 >= 0) {
      setState(() {
        bool isConvexPolygon = checkPolygon(
            tl!,
            Offset(br!.dx - crossoverThreshold, br!.dy - crossoverThreshold),
            tr!,
            bl!);
        if (br!.dx > bl!.dx + crossoverThreshold) {
          if (!isConvexPolygon) {
            br = Offset(br!.dx + crossoverAdjust, br!.dy + crossoverAdjust);
          } else {
            br = points.localPosition;
          }
        } else {
          br = Offset(br!.dx + crossoverAdjust, br!.dy);
        }
        if (br!.dy - crossoverThreshold < tr!.dy) {
          br = Offset(br!.dx, tr!.dy + crossoverAdjust);
        }
        b = Offset((br!.dx + bl!.dx) / 2, (br!.dy + bl!.dy) / 2);
        r = Offset((tr!.dx + br!.dx) / 2, (tr!.dy + br!.dy) / 2);
      });
    } else if (sqrt(pow((x6 - x1), 2) + pow((y6 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height! &&
        x1 < width! &&
        x1 >= 0) {
      setState(() {
        if (t!.dy + crossoverThreshold < b!.dy) {
          t = Offset(t!.dx, points.localPosition.dy);
        } else {
          t = Offset(t!.dx, t!.dy - crossoverAdjust);
        }
        double displacement = t!.dy - y6;
        if (tl!.dy + displacement > 0) {
          tl = Offset(tl!.dx, tl!.dy + displacement);
        }
        if (tr!.dy + displacement > 0) {
          tr = Offset(tr!.dx, tr!.dy + displacement);
        }
        l = Offset((tl!.dx + bl!.dx) / 2, (tl!.dy + bl!.dy) / 2);
        r = Offset((tr!.dx + br!.dx) / 2, (tr!.dy + br!.dy) / 2);
      });
    } else if (sqrt(pow((x7 - x1), 2) + pow((y7 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height! &&
        x1 < width! &&
        x1 >= 0) {
      setState(() {
        if (t!.dy < b!.dy - crossoverThreshold) {
          b = Offset(b!.dx, points.localPosition.dy);
        } else {
          b = Offset(b!.dx, b!.dy + crossoverAdjust);
        }
        double displacement = y7 - b!.dy;
        if (bl!.dy - displacement < height!) {
          bl = Offset(bl!.dx, bl!.dy - displacement);
        }
        if (br!.dy - displacement < height!) {
          br = Offset(br!.dx, br!.dy - displacement);
        }
        l = Offset((tl!.dx + bl!.dx) / 2, (tl!.dy + bl!.dy) / 2);
        r = Offset((tr!.dx + br!.dx) / 2, (tr!.dy + br!.dy) / 2);
      });
    } else if (sqrt(pow((x8 - x1), 2) + pow((y8 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height! &&
        x1 < width! &&
        x1 >= 0) {
      setState(() {
        if (l!.dx < r!.dx - crossoverThreshold) {
          l = Offset(points.localPosition.dx, l!.dy);
        } else {
          l = Offset(l!.dx, l!.dy - crossoverAdjust);
        }
        double displacement = l!.dx - x8;
        if (tl!.dx + displacement > 0) {
          tl = Offset(tl!.dx + displacement, tl!.dy);
        }
        if (bl!.dx + displacement > 0) {
          bl = Offset(bl!.dx + displacement, bl!.dy);
        }
        t = Offset((tr!.dx + tl!.dx) / 2, (tr!.dy + tl!.dy) / 2);
        b = Offset((br!.dx + bl!.dx) / 2, (br!.dy + bl!.dy) / 2);
      });
    } else if (sqrt(pow((x9 - x1), 2) + pow((y9 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height! &&
        x1 < width! &&
        x1 >= 0) {
      setState(() {
        if (l!.dx < r!.dx - crossoverThreshold) {
          r = Offset(points.localPosition.dx, r!.dy);
        } else {
          r = Offset(r!.dx, r!.dy + crossoverAdjust);
        }
        double displacement = x9 - r!.dx;
        if (tr!.dx - displacement < width!) {
          tr = Offset(tr!.dx - displacement, tr!.dy);
        }
        if (br!.dx - displacement < width!) {
          br = Offset(br!.dx - displacement, br!.dy);
        }
        t = Offset((tr!.dx + tl!.dx) / 2, (tr!.dy + tl!.dy) / 2);
        b = Offset((br!.dx + bl!.dx) / 2, (br!.dy + bl!.dy) / 2);
      });
    }

    setState(() {
      if (tl!.dx < 0) tl = Offset(0, tl!.dy);
      if (tl!.dy < 0) tl = Offset(tl!.dx, 0);
      if (tr!.dx > width!) tr = Offset(width!, tr!.dy);
      if (tr!.dy < 0) tr = Offset(tr!.dx, 0);
      if (bl!.dx < 0) bl = Offset(0, bl!.dy);
      if (bl!.dy > height!) bl = Offset(bl!.dx, height!);
      if (br!.dx > width!) br = Offset(width!, br!.dy);
      if (br!.dy > height!) br = Offset(br!.dx, height!);
    });
  }

  void crop() async {
    setState(() {
      isLoading = true;
    });

    var pointsData = await channel.invokeMethod("detectDocument", {
      "path": imageFile!.path,
    });

    print('Points => $pointsData');

    List imageSize = await channel.invokeMethod("getImageSize", {
      "path": imageFile!.path,
    });

    imageSize = [imageSize[0].toDouble(), imageSize[1].toDouble()];
    imageBitmapSize = Size(imageSize[0], imageSize[1]);

    double tlX = (imageBitmapSize.width / width!) * tl!.dx;
    double trX = (imageBitmapSize.width / width!) * tr!.dx;
    double blX = (imageBitmapSize.width / width!) * bl!.dx;
    double brX = (imageBitmapSize.width / width!) * br!.dx;

    double tlY = (imageBitmapSize.height / height!) * tl!.dy;
    double trY = (imageBitmapSize.height / height!) * tr!.dy;
    double blY = (imageBitmapSize.height / height!) * bl!.dy;
    double brY = (imageBitmapSize.height / height!) * br!.dy;
    await channel.invokeMethod('cropImage', {
      'path': imageFile!.path,
      'tl_x': tlX,
      'tl_y': tlY,
      'tr_x': trX,
      'tr_y': trY,
      'bl_x': blX,
      'bl_y': blY,
      'br_x': brX,
      'br_y': brY,
    });

    print('cropper: ${imageFile!.path}');
    Navigator.pop(context, imageFile);
  }

  @override
  Widget build(BuildContext context) {
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
              'Crop Image',
              style: TextStyle().appBarStyle,
            ),
            centerTitle: true,
            elevation: 0.0,
            backgroundColor: Theme.of(context).primaryColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                Navigator.pop(context, null);
              },
            ),
          ),
          body: Container(
            padding: EdgeInsets.all(20),
            alignment: Alignment.center,
            child: !isLoading
                ? GestureDetector(
                    onPanDown: (points) => updatePolygon(points),
                    onPanUpdate: (points) => updatePolygon(points),
                    child: Stack(
                      children: <Widget>[
                        Container(
                          color: Theme.of(context).primaryColor,
                          child: CustomPaint(
                            child: Image.file(
                              imageFile!,
                              key: key,
                            ),
                          ),
                        ),
                        hasWidgetLoaded
                            ? Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width - 20,
                                ),
                                child: CustomPaint(
                                  painter: PolygonPainter(
                                    tl: tl,
                                    tr: tr,
                                    bl: bl,
                                    br: br,
                                    t: t,
                                    l: l,
                                    b: b,
                                    r: r,
                                  ),
                                ),
                              )
                            : Container()
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
            child: Text('Rotate left'),
            onPressed: () async {
              File tempImageFile = File(imageFile!.path
                      .substring(0, imageFile!.path.lastIndexOf('.')) +
                  'r.jpg');
              imageFile!.copySync(tempImageFile.path);
              await channel.invokeMethod("rotateImage", {
                'path': tempImageFile.path,
                'degree': -90,
              });
              print('Rotated left');
              setState(() {
                // tempImageFile.copySync(imageFile.path);
                imageFile = File(tempImageFile.path);
              });
              WidgetsBinding.instance!.addPostFrameCallback(
                (_) => getImageSize(false),
              );
              // tempImageFile.deleteSync();
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: MaterialButton(
              child: Text('Rotate right'),
              color: Theme.of(context).colorScheme.secondary,
              onPressed: () async {
                File tempImageFile = File(imageFile!.path
                        .substring(0, imageFile!.path.lastIndexOf('.')) +
                    'r.jpg');
                imageFile!.copySync(tempImageFile.path);
                await channel.invokeMethod("rotateImage", {
                  'path': tempImageFile.path,
                  'degree': 90,
                });
                print('Rotated right');
                setState(() {
                  // tempImageFile.copySync(imageFile.path);
                  imageFile = File(tempImageFile.path);
                });
                WidgetsBinding.instance!.addPostFrameCallback(
                  (_) => getImageSize(false),
                );
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
                  "Continue",
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
