import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/data/native_android_util.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/view/screens/crop/crop_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:openscan/core/services/document_scanner_service.dart';
import 'package:openscan/core/services/image_processing_service.dart';

part 'directory_state.dart';

// Parameters: directoryOS, [imageOS]
// Methods:
//   ImageOS => addImage, deleteImage, updateImagePath, updateImageIndex, [revertReorder]
//   DirectoryOS => updateImageCount, [updateFirstImagePath, deleteDirectory]

/// Stores the image directory info
class DirectoryCubit extends Cubit<DirectoryState> {
  DirectoryCubit({
    String? dirName,
    DateTime? created,
    String? dirPath,
    String? firstImgPath,
    int imageCount = 0,
    DateTime? lastModified,
    String? newName,
    List<ImageOS>? images,
  }) : super(DirectoryState(
          dirName: dirName,
          dirPath: dirPath,
          created: created,
          firstImgPath: firstImgPath,
          imageCount: imageCount,
          lastModified: lastModified,
          newName: newName,
          images: images,
        ));

  DatabaseHelper database = DatabaseHelper();
  FileOperations fileOperations = FileOperations();

  @override
  void onChange(Change<DirectoryState> change) {
    super.onChange(change);
    DirectoryState state = change.nextState;
    debugPrint('Change Notifier => ${state.imageCount}');
  }

  /// Updates the data to reflect in the UI - adhoc
  void emitState(state) {
    emit(DirectoryState(
      dirName: state.dirName,
      created: state.created,
      dirPath: state.dirPath,
      firstImgPath: state.firstImgPath,
      imageCount: state.imageCount,
      lastModified: state.lastModified,
      newName: state.newName,
      images: state.images,
      isLoading: state.isLoading,
    ));
  }

  /// Creates directory while importing images
  void createDirectory() async {
    Directory? appDir = await getExternalStorageDirectory();
    var now = DateTime.now();
    var dirName = 'OpenScan $now';

    emit(DirectoryState(
      dirName: dirName,
      created: now,
      dirPath: '${appDir!.path}/$dirName',
      firstImgPath: '',
      imageCount: 0,
      lastModified: now,
      newName: null,
      images: <ImageOS>[],
    ));
  }

  /// Extracts image data from db and stores it in [images] object list
  Future<void> getImageData() async {
    try {
      emit(
          state.copyWith(images: [])); // Emit empty state first to show loading

      var directoryData = await database.getImageData(state.dirName!);
      debugPrint('From Cubit => $directoryData');

      List<ImageOS> newImages = [];
      for (var image in directoryData) {
        ImageOS tempImage = ImageOS(
          idx: image['idx'],
          imgPath: image['img_path'],
          selected: false,
        );
        debugPrint('${tempImage.imgPath} => ${tempImage.idx}');
        newImages.add(tempImage);
      }

      emit(state.copyWith(
        images: newImages,
        imageCount: newImages.length,
      ));
    } catch (e) {
      debugPrint('Error loading images: $e');
      emit(state.copyWith(
        images: [],
        imageCount: 0,
      ));
    }
  }

  /// Updates image index after reordering
  void updateImageIndex(int oldIndex, int newIndex) {
    final newImages = List<ImageOS>.from(state.images!);
    ImageOS image = newImages.removeAt(oldIndex);
    newImages.insert(newIndex, image);

    int start, end;
    if (newIndex > oldIndex) {
      start = oldIndex;
      end = newIndex;
    } else {
      start = newIndex;
      end = oldIndex;
    }

    for (int index = start; index <= end; index++) {
      newImages[index].idx = index + 1;
      database.updateImageIndex(
        imgPath: newImages[index].imgPath,
        newIndex: index + 1,
        tableName: state.dirName!,
      );
      if (index == 1) {
        database.updateFirstImagePath(
          dirPath: state.dirPath,
          imagePath: newImages[index - 1].imgPath,
        );
        emit(state.copyWith(
          images: newImages,
          firstImgPath: newImages[index - 1].imgPath,
        ));
      }
    }
    emit(state.copyWith(images: newImages));
  }

  /// Reorders images in database
  void reorderImages() {
    final newImages = List<ImageOS>.from(state.images!);
    for (var i = 1; i <= newImages.length; i++) {
      newImages[i - 1].idx = i;
      if (i == 1) {
        database.updateFirstImagePath(
          dirPath: state.dirPath,
          imagePath: newImages[i - 1].imgPath,
        );
        emit(state.copyWith(
          images: newImages,
          firstImgPath: newImages[i - 1].imgPath,
        ));
      }
      database.updateImagePath(
        imgPath: newImages[i - 1].imgPath,
        idx: newImages[i - 1].idx,
        tableName: state.dirName!,
      );
    }
  }

  getImageSize(String name, File image) async {
    final bytes = (await image.readAsBytes()).lengthInBytes;
    final kb = bytes / 1024;
    debugPrint('$name size --> $kb');
  }

  /// Imports image from gallery and camera and stores it in db
  void createImage(
    context, {
    bool quickScan = false,
    bool fromGallery = false,
  }) async {
    List<File> imageList = [];

    if (fromGallery) {
      imageList = await (fileOperations.openGallery());
    } else {
      File? image = await fileOperations.openCamera();
      if (image != null) {
        File? croppedImage = await imageCropper(
          context,
          image,
        );
        if (croppedImage != null) {
          imageList = [croppedImage];
        }
      }
    }

    if (imageList.isEmpty) return;

    // Set loading state to true
    emit(state.copyWith(isLoading: true));

    // Pre-calculate all indices before processing
    final startIndex = state.images!.length + 1;
    final indices = List.generate(
      imageList.length,
      (index) => startIndex + index,
    );

    // Process images in batches of 5
    List<ImageOS?> processedImages = [];
    List<String> errors = [];
    const batchSize = 3;

    try {
      for (int i = 0; i < imageList.length; i += batchSize) {
        final end = (i + batchSize < imageList.length)
            ? i + batchSize
            : imageList.length;
        final batch = imageList.sublist(i, end);

        // Process current batch of images
        final batchFutures = batch.asMap().entries.map((entry) {
          final message = ImageProcessMessage(
            image: entry.value,
            dirPath: state.dirPath!,
            index: indices[i + entry.key],
            quickScan: quickScan,
            fromGallery: fromGallery,
          );

          return ImageProcessingService.processImageInIsolate(message)
              .then((result) {
            if (result.success && result.imagePath != null) {
              return ImageOS(
                idx: indices[i + entry.key],
                imgPath: result.imagePath!,
                selected: false,
              );
            } else {
              errors.add(result.error ?? 'Unknown error processing image');
              return null;
            }
          });
        });

        // Wait for current batch to complete
        final batchResults = await Future.wait(batchFutures);
        processedImages.addAll(batchResults);

        // Update state after each batch
        final validImages = batchResults.whereType<ImageOS>().toList()
          ..sort((a, b) => a.idx!.compareTo(b.idx!));

        emit(state.copyWith(
          images: List<ImageOS>.from(state.images!)..addAll(validImages),
          imageCount: state.images!.length + validImages.length,
          firstImgPath: state.images!.isEmpty && validImages.isNotEmpty
              ? validImages[0].imgPath
              : state.firstImgPath,
          isLoading: true,
        ));
      }

      // Just update loading state to false
      emit(state.copyWith(isLoading: false));

      // Show error message if any images failed to process
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to process ${errors.length} images: ${errors.join(", ")}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Clean up temporary files
      await fileOperations.deleteTemporaryImages();

      // If quick scan, start another scan
      if (quickScan) {
        return createImage(context, quickScan: quickScan);
      }
    } catch (e) {
      debugPrint('Error processing images: $e');
      emit(state.copyWith(isLoading: false));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Calls image cropper
  void cropImage(context, ImageOS imageOS) async {
    File original = File(imageOS.imgPath);
    debugPrint("originalllll ${imageOS.imgPath}");

    File? result = await imageCropper(
      context,
      original,
    );
    debugPrint("cropresultttt ${result?.path}");

    if (result != null && result.existsSync()) {
      original.deleteSync();
      result.copySync(original.path);
    }
    imageOS.imgPath = original.path;
    debugPrint('Image Cropped');

    database.updateImagePath(
      tableName: state.dirName!,
      imgPath: imageOS.imgPath,
      idx: imageOS.idx,
    );
    debugPrint(imageOS.idx.toString());

    state.images![imageOS.idx! - 1] = imageOS;

    if (imageOS.idx == 1) {
      database.updateFirstImagePath(
        imagePath: imageOS.imgPath,
        dirPath: state.dirPath,
      );
    }
    debugPrint('Image paths updated');
    emitState(state);
  }

  /// Deletes image and updates db
  ///
  /// Returns True if directory deleted, else False
  Future<bool> deleteImage(context, {required ImageOS imageToDelete}) async {
    // Deleting image from database
    File(imageToDelete.imgPath).deleteSync();
    database.deleteImage(
      imgPath: imageToDelete.imgPath,
      tableName: state.dirName!,
    );

    bool directoryDeleted = false;

    try {
      // Delete directory if only 1 image exists
      Directory(state.dirPath!).deleteSync(recursive: false);
      database.deleteDirectory(dirPath: state.dirPath!);
      Navigator.pop(context);
      directoryDeleted = true;
      debugPrint('Directory deleted');
    } catch (e) {
      final newImages = List<ImageOS>.from(state.images!);
      newImages.remove(imageToDelete);
      final newImageCount = newImages.length;
      database.updateImageCount(tableName: state.dirName!);

      // Updating index of images
      for (int i = imageToDelete.idx! - 1; i < newImageCount; i++) {
        newImages[i].idx = i + 1;
        database.updateImageIndex(
          imgPath: newImages[i].imgPath,
          newIndex: newImages[i].idx,
          tableName: state.dirName!,
        );
      }

      // Updating first image path
      if (imageToDelete.idx == 1) {
        database.updateFirstImagePath(
          imagePath: newImages[0].imgPath,
          dirPath: state.dirPath,
        );
      }
      emit(state.copyWith(
        images: newImages,
        imageCount: newImageCount,
      ));
    }
    return directoryDeleted;
  }

  /// Deletes selected images, if [deleteAll]=false
  ///
  /// Deletes all images in directory, if [deleteAll]=true
  ///
  /// Returns: True if directory is deleted, else False
  bool deleteSelectedImages(context, {deleteAll = false}) {
    bool firstImageDeleted = false;
    debugPrint('Image count = ${state.imageCount} : ${state.images!.length}');
    List<ImageOS> imagesToDelete = [];

    for (int i = 0; i < state.images!.length; i++) {
      if (state.images![i].selected || deleteAll) {
        debugPrint('Deleting ${state.images![i].toMap()}');
        imagesToDelete.add(state.images![i]);
        firstImageDeleted = (state.images![i].idx == 1 || firstImageDeleted);
      }
    }

    for (ImageOS image in imagesToDelete) {
      // Deleting image from storage
      File(image.imgPath).deleteSync();

      // Deleting image from db
      database.deleteImage(
        imgPath: image.imgPath,
        tableName: state.dirName!,
      );

      // Removing image from cubit
      bool res = state.images!.remove(image);
      debugPrint(res ? 'Image: Ahhh!' : 'Image: I\'m Alive');
    }

    final newImages = state.images!;
    final newImageCount = newImages.length;

    try {
      // Delete directory if 1 image exists
      Directory(state.dirPath!).deleteSync(recursive: false);
      database.deleteDirectory(dirPath: state.dirPath!);
      debugPrint('Directory: Ahhh!');
      return true;
    } catch (e) {
      debugPrint('Directory: What a save!');

      // Update first image path
      if (firstImageDeleted) {
        database.updateFirstImagePath(
          imagePath: newImages[0].imgPath,
          dirPath: state.dirPath,
        );
      }

      database.updateImageCount(tableName: state.dirName!);

      // Updating image index in cubit and db
      for (int i = 0; i < newImageCount; i++) {
        newImages[i].idx = i + 1;
        database.updateImageIndex(
          imgPath: newImages[i].imgPath,
          newIndex: newImages[i].idx,
          tableName: state.dirName!,
        );
      }
      emit(state.copyWith(
        images: newImages,
        imageCount: newImageCount,
      ));
    }
    return false;
  }

  /// Selects image in directory
  void selectImage(ImageOS imageOS) {
    debugPrint(imageOS.toMap().toString());
    state.images![imageOS.idx! - 1].selected =
        !state.images![imageOS.idx! - 1].selected;
    emitState(state);
  }

  /// Selects all images in directory
  void selectAllImages() {
    for (ImageOS image in state.images!) {
      image.selected = true;
    }
    emitState(state);
  }

  /// Deselects images in directory
  void resetSelection() {
    for (ImageOS image in state.images!) {
      image.selected = false;
    }
    emitState(state);
  }

  /// Rename the directory name
  void renameDocument(String newName) {
    emit(state.copyWith(newName: newName));
  }

  /// Updates the filter for a specific image
  void updateImageFilter(
      String imagePath, DocumentFilterType filterType) async {
    // Find the image in the state
    final imageIndex =
        state.images!.indexWhere((img) => img.imgPath == imagePath);
    if (imageIndex != -1) {
      try {
        // Get the filtered image path
        final documentScanner = DocumentScannerService();
        final enhancedPath =
            await documentScanner.enhanceDocument(imagePath, filterType.value);

        // Delete the original file
        await File(imagePath).delete();

        // Copy the filtered image to the original path
        await File(enhancedPath).copy(imagePath);

        // Update the filter type for the image
        state.images![imageIndex].filterType = filterType;
        emitState(state);
      } catch (e) {
        debugPrint('Error updating image filter: $e');
      }
    }
  }
}
