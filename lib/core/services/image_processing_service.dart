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
  final int index;

  ImageProcessingResult({
    required this.success,
    this.imagePath,
    this.error,
    required this.index,
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
        index: message.index,
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
          index: message.index,
        ));
        return;
      }

      Directory cacheDir = await getTemporaryDirectory();

      String processedPath = await NativeAndroidUtil.postScanImageProcessing(
        message.image.path,
        cacheDir.path,
      );

      File processedImage = File(processedPath);
      if (!processedImage.existsSync()) {
        sendPort.send(ImageProcessingResult(
          success: false,
          error: 'Failed to process image',
          index: message.index,
        ));
        return;
      }

      // Save final image
      final fileOperations = FileOperations();
      File savedImage = await fileOperations.saveImage(
        image: processedImage,
        index: message.index,
        dirPath: message.dirPath,
      );

      if (!savedImage.existsSync()) {
        sendPort.send(ImageProcessingResult(
          success: false,
          error: 'Failed to save final image',
          index: message.index,
        ));
        return;
      }

      sendPort.send(ImageProcessingResult(
        success: true,
        imagePath: savedImage.path,
        index: message.index,
      ));
    } catch (e, stackTrace) {
      print('Error processing image in isolate: $e');
      print('Stack trace: $stackTrace');
      sendPort.send(ImageProcessingResult(
        success: false,
        error: e.toString(),
        index: message.index,
      ));
    }
  }
}
