import 'package:flutter/services.dart';

class NativeAndroidUtil {
  static MethodChannel _channel =
      new MethodChannel('com.ethereal.openscan/cropper');

  static Future getImageSize(String path) async {
    return _channel.invokeMethod("getImageSize", {
      "path": path,
    });
  }

  static Future detectDocument(String path) {
    return _channel.invokeMethod("detectDocument", {
      "path": path,
    });
  }

  static Future compress(String src, String dest, int desiredQuality) async {
    return _channel.invokeMethod('compress', {
      "src": src,
      "dest": dest,
      "desiredQuality": desiredQuality,
    });
  }

  static Future rotate(String imgPath, int degree) async {
    return _channel.invokeMethod('rotateImage', {
      'path': imgPath,
      'degree': degree,
    });
  }

  static Future cropImage(
      {required String srcPath,
      required String destPath,
      required double tlX,
      required double tlY,
      required double trX,
      required double trY,
      required double blX,
      required double blY,
      required double brX,
      required double brY}) async {
    return _channel.invokeMethod('cropImage', {
      "srcPath": srcPath,
      "destPath": destPath,
      "tl_x": "$tlX",
      "tl_y": "$tlY",
      "tr_x": "$trX",
      "tr_y": "$trY",
      "bl_x": "$blX",
      "bl_y": "$blY",
      "br_x": "$brX",
      "br_y": "$brY",
    });
  }
}
