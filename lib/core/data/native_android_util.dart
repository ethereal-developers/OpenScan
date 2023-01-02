import 'package:flutter/services.dart';

class NativeAndroidUtil {
  static MethodChannel _channel =
      new MethodChannel('com.ethereal.openscan/cropper');

  static Future<Map> getImageSize(String path) {
    return _channel.invokeMethod("getImageSize", {
      "path": path,
    }) as Future<Map>;
  }

  static Future<List> detectDocument(String path) {
    return _channel.invokeMethod("detectDocument", {
      "path": path,
    }) as Future<List>;
  }

  static Future<String> compress(String src, String dest, int desiredQuality) {
    return _channel.invokeMethod('compress', {
      "src": src,
      "dest": dest,
      "desiredQuality": desiredQuality,
    }) as Future<String>;
  }
}
