import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:openscan/core/cv/models/detection_result.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/core/cv/perspective_crop.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/image_filter/apply_filter.dart';
import 'package:openscan/core/image_filter/filters/document_filters.dart';
import 'package:openscan/core/image_filter/filters/filters.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/core/settings/app_settings.dart';
import 'package:openscan/view/screens/crop/crop_screen.dart';
import 'package:openscan/view/screens/live_scan/live_scan_screen.dart';
import 'package:path_provider/path_provider.dart';

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
    ));
  }

  /// Creates directory while importing images
  void createDirectory() async {
    Directory? appDir = await getExternalStorageDirectory();
    var now = DateTime.now();

    state.dirName = 'OpenScan $now';
    state.created = now;
    state.dirPath = '${appDir!.path}/${state.dirName}';
    state.firstImgPath = '';
    state.imageCount = 0;
    state.lastModified = now;
    state.newName = null;
    state.images = <ImageOS>[];
    emitState(state);
  }

  /// Extracts image data from db and stores it in [images] object list
  void getImageData() async {
    state.images = [];
    var directoryData = await database.getImageData(state.dirName!);
    debugPrint('From Cubit => $directoryData');
    for (var image in directoryData) {
      ImageOS tempImage = ImageOS(
        idx: image['idx'],
        imgPath: image['img_path'],
        origPath: image['orig_img_path'],
        unfilteredPath: image['unfiltered_img_path'],
        filterName: image['filter_name'],
        selected: false,
      );
      debugPrint('${tempImage.imgPath} => ${tempImage.idx}');
      state.images!.add(
        tempImage,
      );
    }
    state.imageCount = state.images!.length;
    emitState(state);
  }

  /// Updates image index after reordering
  void updateImageIndex(int oldIndex, int newIndex) {
    ImageOS image = state.images!.removeAt(oldIndex);
    state.images!.insert(newIndex, image);

    int start, end;
    if (newIndex > oldIndex) {
      start = oldIndex;
      end = newIndex;
    } else {
      start = newIndex;
      end = oldIndex;
    }

    for (int index = start; index <= end; index++) {
      state.images![index].idx = index + 1;
      database.updateImageIndex(
        imgPath: state.images![index].imgPath,
        newIndex: index + 1,
        tableName: state.dirName!,
      );
      if (index == 1) {
        database.updateFirstImagePath(
          dirPath: state.dirPath,
          imagePath: state.images![index - 1].imgPath,
        );
        state.firstImgPath = state.images![index - 1].imgPath;
      }
    }
    emitState(state);
  }

  /// Reorders images in database
  void reorderImages() {
    for (var i = 1; i <= state.images!.length; i++) {
      state.images![i - 1].idx = i;
      if (i == 1) {
        database.updateFirstImagePath(
          dirPath: state.dirPath,
          imagePath: state.images![i - 1].imgPath,
        );
        state.firstImgPath = state.images![i - 1].imgPath;
      }
      database.updateImagePath(
        imgPath: state.images![i - 1].imgPath,
        idx: state.images![i - 1].idx,
        tableName: state.dirName!,
      );
      emitState(state);
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
    bool liveScan = false,
  }) async {
    // Each entry pairs the page to store with the uncropped capture it
    // came from, so the original outlives the crop (see
    // [FileOperations.saveImage]).
    List<_PendingImage> imageList = [];

    if (fromGallery) {
      for (File image in await fileOperations.openGallery()) {
        // Gallery imports aren't cropped on the way in, so the import is
        // both the page and its own original.
        imageList.add(_PendingImage(image: image, original: image));
      }
    } else if (liveScan) {
      List<LiveCapture>? captures = await captureWithLiveScan(context);
      if (captures != null) {
        for (LiveCapture capture in captures) {
          debugPrint('Live capture: autoMode=${capture.autoMode} '
              'quad=${capture.quad != null} -> '
              '${capture.canAutoCrop ? "auto-crop" : "crop screen"}');
          if (capture.canAutoCrop) {
            // Auto mode: crop straight to the edges the user already
            // agreed with on the live preview and go on to the document,
            // instead of reopening the crop screen for every page.
            final original = await _copyAsideOriginal(capture.file);
            final result = await _cropToLiveQuad(capture.file, capture.quad!);
            imageList.add(_PendingImage(
              // A failed warp leaves the capture untouched on disk, so the
              // page falls back to the uncropped photo rather than being
              // dropped.
              image: capture.file,
              original: result is CropSuccess ? original : capture.file,
            ));
          } else {
            final original = await _copyAsideOriginal(capture.file);
            final cropped = await imageCropper(context, capture.file);
            imageList.add(_PendingImage(
              image: cropped ?? capture.file,
              original: cropped == null ? capture.file : original,
            ));
          }
        }
      }
    } else {
      File? image = await fileOperations.openCamera();
      if (image != null) {
        final original = await _copyAsideOriginal(image);
        final cropped = await imageCropper(context, image);
        imageList.add(_PendingImage(
          image: cropped ?? image,
          original: cropped == null ? image : original,
        ));
      }
    }

    for (_PendingImage pending in imageList) {
      File image = pending.image;
      if (image.existsSync()) {
        ImageOS savedImage = await fileOperations.saveImage(
          image: image,
          original: pending.original,
          index: state.images!.length + 1,
          dirPath: state.dirPath!,
        );
        debugPrint('Saved ${savedImage.imgPath}');

        ImageOS tempImage = ImageOS(
          idx: state.imageCount + 1,
          imgPath: savedImage.imgPath,
          origPath: savedImage.origPath,
        );

        // A default filter is only useful if new pages actually arrive
        // carrying it; applying it here (rather than at export time) keeps
        // the page on disk and the thumbnail in the grid in agreement.
        final defaultFilter = AppSettings.instance.defaultFilter;
        if (defaultFilter != null) {
          await _applyFilter(tempImage, documentFilterByName(defaultFilter));
        }
        debugPrint(tempImage.idx.toString());
        state.images!.add(tempImage);
        state.imageCount = state.images!.length;

        if (state.imageCount == 1) {
          state.firstImgPath = savedImage.imgPath;
        }

        emitState(state);
      }
    }

    // Run once after every image in this call's imageList has been copied
    // to permanent storage, not per-image inside the loop above: it wipes
    // the whole OS temp/cache directory, which is also where
    // still-unprocessed images in a multi-image imageList (batch live-scan,
    // multi-select gallery import) live until their turn in the loop —
    // deleting it mid-loop silently drops every image after the first.
    await fileOperations.deleteTemporaryImages();
    if (quickScan) {
      return createImage(context, quickScan: quickScan);
    }
  }

  /// Calls image cropper
  ///
  /// Re-crops from the stored original when there is one, so repeated
  /// crops always work off the full capture instead of eating into an
  /// already-cropped page. The crop screen writes in place, so it's handed
  /// a throwaway copy — the original itself is never touched.
  void cropImage(context, ImageOS imageOS) async {
    Directory cacheDir = await getTemporaryDirectory();
    File workingCopy = File(
        '${cacheDir.path}/recrop_${DateTime.now().millisecondsSinceEpoch}.jpg');
    File(imageOS.cropSourcePath).copySync(workingCopy.path);

    File? image = await imageCropper(context, workingCopy);
    if (image == null) {
      // Backed out of the crop screen — leave the stored page as it is.
      if (workingCopy.existsSync()) workingCopy.deleteSync();
      return;
    }

    String dir = imageOS.imgPath.substring(0, imageOS.imgPath.lastIndexOf("/"));
    String stamp = DateTime.now().toString();

    // A page with no original on record (stored before originals were
    // kept) is about to be cropped down — promote the current, still
    // uncropped file to being its original first, so the next crop starts
    // from there instead of from this crop's result.
    if (imageOS.origPath == null) {
      File promoted = File('$dir/orig_$stamp.jpg');
      // Promote the *unfiltered* version, so a page that was filtered
      // before it was ever cropped doesn't end up with the filter baked
      // into its permanent original.
      File(imageOS.filterSourcePath).copySync(promoted.path);
      imageOS.origPath = promoted.path;
    }

    // Creating new imagePath for cropped image
    File temp = File('$dir/$stamp.jpg');
    image.copySync(temp.path);
    if (workingCopy.existsSync()) workingCopy.deleteSync();
    File(imageOS.imgPath).deleteSync();
    imageOS.imgPath = temp.path;
    debugPrint('Image Cropped');

    // The crop came off the uncropped original, so any filtered result and
    // the unfiltered copy it was derived from both describe a page that no
    // longer exists. Drop them and let the page start filter-free again.
    _deleteUnfilteredCopy(imageOS);

    database.updateImagePath(
      tableName: state.dirName!,
      imgPath: imageOS.imgPath,
      origPath: imageOS.origPath,
      clearFilter: true,
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

  /// Applies [filter] to a single page, writing the result to disk and
  /// recording it, so the choice survives leaving the screen.
  Future<void> applyFilterToImage({
    required ImageOS imageOS,
    required Filter filter,
  }) async {
    await _applyFilter(imageOS, filter);
    state.images![imageOS.idx! - 1] = imageOS;
    if (imageOS.idx == 1) {
      database.updateFirstImagePath(
        imagePath: imageOS.imgPath,
        dirPath: state.dirPath,
      );
    }
    emitState(state);
  }

  /// Applies [filter] to every page of the document.
  Future<void> applyFilterToAllImages({required Filter filter}) async {
    for (ImageOS imageOS in state.images!) {
      await _applyFilter(imageOS, filter);
    }
    if (state.images!.isNotEmpty) {
      database.updateFirstImagePath(
        imagePath: state.images!.first.imgPath,
        dirPath: state.dirPath,
      );
    }
    emitState(state);
  }

  /// Re-derives a page from its unfiltered source under [filter].
  ///
  /// Filtering is non-destructive: the first filter applied to a page
  /// promotes the current file to being that page's unfiltered copy (the
  /// same trick [saveCroppedImage] uses to keep an uncropped original), and
  /// every later filter is computed from that copy rather than from the
  /// previous filtered result, so switching modes never compounds.
  Future<void> _applyFilter(ImageOS imageOS, Filter filter) async {
    final bool isOriginal = filter.name == defaultDocumentFilter.name;
    if ((imageOS.filterName ?? defaultDocumentFilter.name) == filter.name) {
      return;
    }

    String dir = imageOS.imgPath.substring(0, imageOS.imgPath.lastIndexOf("/"));
    String stamp = DateTime.now().microsecondsSinceEpoch.toString();
    String previousPath = imageOS.imgPath;

    bool justPromoted = false;
    if (imageOS.unfilteredPath == null) {
      // Nothing filtered yet and nothing asked for — nothing to do.
      if (isOriginal) return;
      File promoted = File('$dir/unfilt_$stamp.jpg');
      File(imageOS.imgPath).copySync(promoted.path);
      imageOS.unfilteredPath = promoted.path;
      justPromoted = true;
    }
    String sourcePath = imageOS.unfilteredPath!;

    if (isOriginal) {
      // Back to no filter: the unfiltered copy simply becomes the page
      // again, rather than being re-encoded into a fresh file.
      if (previousPath != sourcePath) {
        File previous = File(previousPath);
        if (previous.existsSync()) previous.deleteSync();
      }
      imageOS.imgPath = sourcePath;
      imageOS.unfilteredPath = null;
      imageOS.filterName = null;
    } else {
      try {
        String filteredPath = await compute(applyFilterIsolateEntry, {
          'filter': filter.name,
          'src': sourcePath,
          'dest': '$dir/$stamp.jpg',
        }) as String;
        if (previousPath != sourcePath) {
          File previous = File(previousPath);
          if (previous.existsSync()) previous.deleteSync();
        }
        imageOS.imgPath = filteredPath;
        imageOS.filterName = filter.name;
      } catch (e) {
        // Leave the page exactly as it was — a filter that could not be
        // computed is worth far less than the page it would have replaced.
        debugPrint('Could not apply ${filter.name} to $sourcePath: $e');
        if (justPromoted) {
          File promoted = File(sourcePath);
          if (promoted.existsSync()) promoted.deleteSync();
          imageOS.unfilteredPath = null;
        }
        return;
      }
    }

    await database.updateImagePath(
      tableName: state.dirName!,
      imgPath: imageOS.imgPath,
      unfilteredPath: imageOS.unfilteredPath,
      filterName: imageOS.filterName,
      clearFilter: isOriginal,
      idx: imageOS.idx,
    );
  }

  /// Deletes image and updates db
  ///
  /// Returns True if directory deleted, else False
  Future<bool> deleteImage(context, {required ImageOS imageToDelete}) async {
    // Deleting image from database
    _deleteImageFiles(imageToDelete);
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
      state.images!.remove(imageToDelete);
      state.imageCount = state.images!.length;
      database.updateImageCount(tableName: state.dirName!);

      // Updating index of images
      for (int i = imageToDelete.idx! - 1; i < state.imageCount; i++) {
        state.images![i].idx = i + 1;
        database.updateImageIndex(
          imgPath: state.images![i].imgPath,
          newIndex: state.images![i].idx,
          tableName: state.dirName!,
        );
      }

      // Updating first image path
      if (imageToDelete.idx == 1) {
        database.updateFirstImagePath(
          imagePath: state.images![0].imgPath,
          dirPath: state.dirPath,
        );
      }
    }
    emitState(state);
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

    for(ImageOS image in imagesToDelete){
      // Deleting image from storage
      _deleteImageFiles(image);

      // Deleting image from db
      database.deleteImage(
        imgPath: image.imgPath,
        tableName: state.dirName!,
      );

      // Removing image from cubit
      bool res = state.images!.remove(image);
      debugPrint(res ? 'Image: Ahhh!' : 'Image: I\'m Alive');
    }

    state.imageCount = state.images!.length;

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
          imagePath: state.images![0].imgPath,
          dirPath: state.dirPath,
        );
      }

      database.updateImageCount(tableName: state.dirName!);

      // Updating image index in cubit and db
      for (int i = 0; i < state.imageCount; i++) {
        state.images![i].idx = i + 1;
        database.updateImageIndex(
          imgPath: state.images![i].imgPath,
          newIndex: state.images![i].idx,
          tableName: state.dirName!,
        );
      }
      emitState(state);
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
    state.newName = newName;
    emitState(state);
  }

  /// Removes both files a page owns on disk: the page itself and, when one
  /// was kept, its uncropped original. Both have to go — the callers that
  /// delete a page then try `Directory.deleteSync(recursive: false)` to
  /// clean up an emptied document, which fails on any file left behind.
  void _deleteImageFiles(ImageOS image) {
    File(image.imgPath).deleteSync();
    final origPath = image.origPath;
    if (origPath != null && origPath != image.imgPath) {
      File orig = File(origPath);
      if (orig.existsSync()) orig.deleteSync();
    }
    _deleteUnfilteredCopy(image);
  }

  /// Removes the unfiltered copy a filtered page keeps alongside it, and
  /// forgets the filter. Safe to call on an unfiltered page.
  void _deleteUnfilteredCopy(ImageOS image) {
    final unfilteredPath = image.unfilteredPath;
    if (unfilteredPath != null && unfilteredPath != image.imgPath) {
      File unfiltered = File(unfilteredPath);
      if (unfiltered.existsSync()) unfiltered.deleteSync();
    }
    image.unfilteredPath = null;
    image.filterName = null;
  }

  /// Copies a capture aside before it gets cropped in place, so the
  /// uncropped version survives to be stored alongside the page.
  ///
  /// Returns null (and the caller stores no original) if the copy fails —
  /// losing the original is worth far less than losing the page.
  Future<File?> _copyAsideOriginal(File capture) async {
    // Opting out of keeping originals halves the storage a document costs,
    // at the price of re-crops working off the already-cropped page.
    if (!AppSettings.instance.keepOriginal) return null;
    try {
      Directory cacheDir = await getTemporaryDirectory();
      File copy = File(
          '${cacheDir.path}/orig_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await capture.copy(copy.path);
      return copy;
    } catch (e) {
      debugPrint("Couldn't keep original of ${capture.path}: $e");
      return null;
    }
  }

  /// Warps a live-scan capture to the quad that was on the preview when it
  /// was taken, writing the result over [capture] (the uncropped version
  /// has already been copied aside by [_copyAsideOriginal]).
  Future<CropResult> _cropToLiveQuad(File capture, Quad quad) async {
    try {
      final result = await compute(cropImageNormalizedIsolateEntry, {
        'path': capture.path,
        'quad': quad,
      }).timeout(const Duration(seconds: 15));
      if (result is CropFailure) {
        debugPrint('Live-scan auto-crop failed: ${result.message}');
      }
      return result;
    } catch (e) {
      debugPrint('Live-scan auto-crop error: $e');
      return CropFailure(e.toString());
    }
  }
}

/// A capture on its way into storage: the page to save, paired with the
/// uncropped image it came from (null when no original was kept).
class _PendingImage {
  final File image;
  final File? original;

  const _PendingImage({required this.image, this.original});
}
