import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:openscan/core/data/native_android_util.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/models.dart';

class ImageProcessingResult {
  final bool success;
  final String? imagePath;
  final String? error;

  ImageProcessingResult({
    required this.success,
    this.imagePath,
    this.error,
  });
}

class ImageProcessingService {
  static Future<ImageProcessingResult> processImageInIsolate(
      ImageProcessMessage message) async {
    final receivePort = ReceivePort();
    final rootIsolateToken = RootIsolateToken.instance;
    if (rootIsolateToken == null) {
      return ImageProcessingResult(
        success: false,
        error: 'Failed to get root isolate token',
      );
    }

    final isolate = await Isolate.spawn(
      _processImage,
      [message, receivePort.sendPort, rootIsolateToken],
    );

    final result = await receivePort.first as ImageProcessingResult;
    receivePort.close();
    isolate.kill();
    return result;
  }

  static Future<void> _processImage(List<dynamic> args) async {
    final message = args[0] as ImageProcessMessage;
    final sendPort = args[1] as SendPort;
    final rootIsolateToken = args[2] as RootIsolateToken;

    try {
      // Initialize background isolate messenger
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

      if (!message.image.existsSync()) {
        sendPort.send(ImageProcessingResult(
          success: false,
          error: 'Source image does not exist',
        ));
        return;
      }

      Directory cacheDir = await getTemporaryDirectory();

      // Compress image
      String compressedPath = await NativeAndroidUtil.compress(
        message.image.path,
        cacheDir.path,
        70,
      );

      File compressedImage = File(compressedPath);
      if (!compressedImage.existsSync()) {
        sendPort.send(ImageProcessingResult(
          success: false,
          error: 'Failed to compress image',
        ));
        return;
      }

      if (message.image.existsSync()) {
        message.image.deleteSync();
      }

      // Fix rotation
      String exifFixedPath = await NativeAndroidUtil.fixRotation(
        srcPath: compressedImage.path,
        destPath: cacheDir.path,
      );

      File exifFixedImage = File(exifFixedPath);
      if (!exifFixedImage.existsSync()) {
        sendPort.send(ImageProcessingResult(
          success: false,
          error: 'Failed to fix image rotation',
        ));
        return;
      }

      if (compressedImage.existsSync()) {
        compressedImage.deleteSync();
      }

      // Save final image
      final fileOperations = FileOperations();
      File savedImage = await fileOperations.saveImage(
        image: exifFixedImage,
        index: message.index,
        dirPath: message.dirPath,
      );

      if (!savedImage.existsSync()) {
        sendPort.send(ImageProcessingResult(
          success: false,
          error: 'Failed to save final image',
        ));
        return;
      }

      sendPort.send(ImageProcessingResult(
        success: true,
        imagePath: savedImage.path,
      ));
    } catch (e, stackTrace) {
      print('Error processing image in isolate: $e');
      print('Stack trace: $stackTrace');
      sendPort.send(ImageProcessingResult(
        success: false,
        error: e.toString(),
      ));
    }
  }
}
