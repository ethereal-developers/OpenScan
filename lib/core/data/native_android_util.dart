import 'package:flutter/services.dart';

class NativeAndroidUtil {
  static MethodChannel _channel =
      const MethodChannel('com.ethereal.openscan/cropper');
  static bool _isInitialized = false;

  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        await _channel.invokeMethod('ping');
        _isInitialized = true;
      } catch (e) {
        print('Error initializing platform channel: $e');
      }
    }
  }

  static String _GET_IMAGE_SIZE = "getImageSize";
  static String _DETECT_DOCUMENT = "detectDocument";
  static String _COMPRESS = "compress";
  static String _ROTATE_IMAGE = "rotateImage";
  static String _CROP_IMAGE = "cropImage";
  static String _FIX_ROTATION = "fixRotation";
  static String _ENHANCE_DOCUMENT = "enhanceDocument";
  static String _POST_SCAN_IMAGE_PROCESSING = "postScanImageProcessing";

  static Future getImageSize(String path) async {
    await _ensureInitialized();
    return _channel.invokeMethod(_GET_IMAGE_SIZE, {
      "path": path,
    });
  }

  static Future detectDocument(String path) async {
    await _ensureInitialized();
    print('NativeAndroidUtil.detectDocument called with path: $path');
    try {
      print('Invoking native method through channel');
      final result = await _channel.invokeMethod(_DETECT_DOCUMENT, {
        "path": path,
      });
      print('Native method returned result: $result');
      if (result == null) {
        print('Native method returned null result');
        return [];
      }
      return result;
    } catch (e, stackTrace) {
      print('Error calling native detectDocument: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future compress(String src, String dest, int desiredQuality) async {
    await _ensureInitialized();
    return _channel.invokeMethod(_COMPRESS, {
      "src": src,
      "dest": dest,
      "desiredQuality": desiredQuality,
    });
  }

  static Future rotate(String imgPath, int degree) async {
    await _ensureInitialized();
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
    await _ensureInitialized();
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

  static Future fixRotation(
      {required String srcPath, required String destPath}) async {
    await _ensureInitialized();
    return _channel.invokeMethod(_FIX_ROTATION, {
      "srcPath": srcPath,
      "destPath": destPath,
    });
  }

  static Future<String> enhanceDocument(
      String imagePath, String filterType) async {
    await _ensureInitialized();
    try {
      final result = await _channel.invokeMethod(_ENHANCE_DOCUMENT, {
        "imagePath": imagePath,
        "filterType": filterType,
      });
      return result;
    } catch (e) {
      print('Error enhancing document: $e');
      rethrow;
    }
  }

  static Future<String> postScanImageProcessing(String src, String dest) async {
    await _ensureInitialized();
    try {
      final result = await _channel.invokeMethod(_POST_SCAN_IMAGE_PROCESSING, {
        "src": src,
        "dest": dest,
      });
      return result;
    } catch (e) {
      print('Error post-scan image processing: $e');
      rethrow;
    }
  }
}
