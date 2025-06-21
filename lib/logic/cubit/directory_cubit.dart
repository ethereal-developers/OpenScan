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

part 'directory_state.dart';

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

  Future<ImageOS?> processImage(File image, String dirPath, int index) async {
    try {
      if (!image.existsSync()) {
        debugPrint('Source image does not exist');
        return null;
      }

      Directory cacheDir = await getTemporaryDirectory();

      String processedPath = await NativeAndroidUtil.postScanImageProcessing(
        image.path,
        cacheDir.path,
      );

      File processedImage = File(processedPath);
      if (!processedImage.existsSync()) {
        debugPrint('Failed to process image');
        return null;
      }

      // Save final image
      File savedImage = await fileOperations.saveImage(
        image: processedImage,
        index: index,
        dirPath: dirPath,
      );

      if (!savedImage.existsSync()) {
        debugPrint('Failed to save final image');
        return null;
      }

      return ImageOS(
        idx: index,
        imgPath: savedImage.path,
        selected: false,
      );
    } catch (e, stackTrace) {
      debugPrint('Error processing image: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

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
    var dirName = fileOperations.generateCleanFolderName(now);

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

  /// Imports image from gallery
  void importImagesFromGallery(context) async {
    List<File> imageList = await fileOperations.openGallery();
    List<String> errors = [];
    List<ImageOS> allValidImages = [];

    if (imageList.isEmpty) return;
    emit(state.copyWith(isLoading: true));

    try {
      final startIndex = state.images?.length ?? 1;

      // Process images sequentially
      for (var i = 0; i < imageList.length; i++) {
        final processedImage =
            await processImage(imageList[i], state.dirPath!, startIndex + i);

        if (processedImage != null) {
          allValidImages.add(processedImage);
        } else {
          errors.add('Failed to process image ${i + 1}');
        }
      }

      // Sort valid images by index
      allValidImages.sort((a, b) => a.idx!.compareTo(b.idx!));

      // update first image path
      if (allValidImages.isNotEmpty) {
        database.updateFirstImagePath(
          dirPath: state.dirPath!,
          imagePath: allValidImages[0].imgPath,
        );
      }

      // Update state once with all processed images
      emit(state.copyWith(
        images: List<ImageOS>.from(state.images!)..addAll(allValidImages),
        imageCount: state.images!.length + allValidImages.length,
        firstImgPath: allValidImages.isNotEmpty
            ? allValidImages[0].imgPath
            : state.firstImgPath,
        isLoading: false, // Set to false since we're done processing
      ));

      // Clean up batch files immediately
      await fileOperations.deleteTemporaryImages();

      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to process ${errors.length} images: ${errors.join(", ")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing images: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Creates image from camera
  void createImage(
    context, {
    bool quickScan = false,
  }) async {
    File? croppedImage;
    File? image;
    File? compressedImage;
    
    try {
      // Camera capture
      image = await fileOperations.openCamera();
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera capture was cancelled or failed'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Cropping
      croppedImage = await imageCropper(
        context,
        image,
      );
      if (croppedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image cropping was cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Set loading state to true
      emit(state.copyWith(isLoading: true));

      // Verify cropped image
      if (!croppedImage.existsSync()) {
        throw Exception('The cropped image could not be found. Please try again.');
      }

      // Compression
      Directory cacheDir = await getTemporaryDirectory();
      String compressedPath = await NativeAndroidUtil.compress(
        croppedImage.path,
        cacheDir.path,
        70,
      );

      compressedImage = File(compressedPath);
      if (!compressedImage.existsSync()) {
        throw Exception('Failed to compress the image. Please try again.');
      }

      // Save final image
      await fileOperations.saveImage(
        image: compressedImage,
        index: state.images!.length + 1,
        dirPath: state.dirPath!,
      );

      // Refresh image data to update state
      await getImageData();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // If quick scan, start another scan
      if (quickScan) {
        // Add a small delay to allow the user to see the success message
        await Future.delayed(const Duration(milliseconds: 500));
        return createImage(context, quickScan: quickScan);
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Try Again',
            onPressed: () => createImage(context, quickScan: quickScan),
          ),
        ),
      );
    } finally {
      // Clean up temporary files
      await fileOperations.deleteTemporaryImages();
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Calls image cropper
  void cropImage(context, ImageOS imageOS) async {
    File original = File(imageOS.imgPath);
    debugPrint("Original image path: ${imageOS.imgPath}");

    File? result = await imageCropper(
      context,
      original,
    );
    debugPrint("Cropped image path: ${result?.path}");

    if (result != null && result.existsSync()) {
      try {
        // Delete original and copy cropped image
        original.deleteSync();
        result.copySync(original.path);

        // Evict the old image from the cache to force a reload
        await FileImage(original).evict();

        // Update database
        await database.updateImagePath(
          tableName: state.dirName!,
          imgPath: imageOS.imgPath,
          idx: imageOS.idx,
        );

        // Update first image path if needed
        if (imageOS.idx == 1) {
          await database.updateFirstImagePath(
            imagePath: imageOS.imgPath,
            dirPath: state.dirPath,
          );
        }

        // Create new state with updated image
        final updatedImages = List<ImageOS>.from(state.images!);
        updatedImages[imageOS.idx! - 1] = imageOS;

        emit(state.copyWith(
          images: updatedImages,
          firstImgPath: imageOS.idx == 1 ? imageOS.imgPath : state.firstImgPath,
        ));

        debugPrint('Image cropped and state updated successfully');
      } catch (e) {
        debugPrint('Error during image cropping: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to crop image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  /// Enables selection mode
  void enableSelection() {
    emit(state.copyWith(isSelectionEnabled: true));
  }

  /// Disables selection mode
  void disableSelection() {
    emit(state.copyWith(isSelectionEnabled: false));
  }

  /// Resets selection state
  void resetSelection() {
    final newImages = state.images?.map((image) {
      image.selected = false;
      return image;
    }).toList();
    emit(state.copyWith(
      images: newImages,
      isSelectionEnabled: false,
    ));
  }

  /// Selects all images
  void selectAllImages() {
    final newImages = state.images?.map((image) {
      image.selected = true;
      return image;
    }).toList();
    emit(state.copyWith(images: newImages));
  }

  /// Selects a single image
  void selectImage(ImageOS image) {
    final newImages = state.images?.map((img) {
      if (img.idx == image.idx) {
        img.selected = !img.selected;
      }
      return img;
    }).toList();
    emit(state.copyWith(images: newImages));
  }

  /// Gets the count of selected images
  int getSelectedCount() {
    return state.images?.where((image) => image.selected).length ?? 0;
  }

  /// Gets the list of selected images
  List<ImageOS> getSelectedImages() {
    return state.images?.where((image) => image.selected).toList() ?? [];
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
