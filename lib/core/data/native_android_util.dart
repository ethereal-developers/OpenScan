import 'package:flutter/services.dart';

class NativeAndroidUtil {
  static MethodChannel _channel =
      new MethodChannel('com.ethereal.openscan/cropper');

  static String _GET_IMAGE_SIZE = "getImageSize";
  static String _DETECT_DOCUMENT = "detectDocument";
  static String _COMPRESS = "compress";
  static String _ROTATE_IMAGE = "rotateImage";
  static String _CROP_IMAGE = "cropImage";
  static String _FIX_ROTATION = "fixRotation";

  static Future getImageSize(String path) async {
    return _channel.invokeMethod(_GET_IMAGE_SIZE, {
      "path": path,
    });
  }

  static Future detectDocument(String path) {
    return _channel.invokeMethod(_DETECT_DOCUMENT, {
      "path": path,
    });
  }

  static Future compress(String src, String dest, int desiredQuality) async {
    return _channel.invokeMethod(_COMPRESS, {
      "src": src,
      "dest": dest,
      "desiredQuality": desiredQuality,
    });
  }

  static Future rotate(String imgPath, int degree) async {
    return _channel.invokeMethod(_ROTATE_IMAGE, {
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
    return _channel.invokeMethod(_CROP_IMAGE, {
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

  static Future fixRotation({required String srcPath, required String destPath}) {
    return _channel.invokeMethod(_FIX_ROTATION, {
      "srcPath": srcPath,
      "destPath": destPath,
    });
  }
}
