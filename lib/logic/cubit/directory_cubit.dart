import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/data/document_naming.dart';
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
      pendingPages: state.pendingPages,
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

    state.dirName = defaultDocumentName(now);
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

  /// Imports pages from the gallery or from a live-scan session and
  /// stores them in db.
  ///
  /// Resolves with the number of pages this call actually added, so a
  /// caller can tell a cancelled session (0) from a real capture — an
  /// empty new document has nothing worth showing — alongside the number
  /// it had to skip, which is a gallery pick the app cannot read and has
  /// to say so about rather than leave the user staring at a document
  /// that didn't grow.
  Future<({int stored, int skipped})> createImage(
    context, {
    bool fromGallery = false,
    bool liveScan = false,
  }) async {
    List<_PendingCapture> imageList = [];

    if (fromGallery) {
      for (File image in await fileOperations.openGallery()) {
        // Gallery imports aren't cropped on the way in.
        imageList.add(_PendingCapture(file: image));
      }
    } else if (liveScan) {
      List<LiveCapture>? captures = await captureWithLiveScan(context);
      if (captures != null) {
        for (LiveCapture capture in captures) {
          imageList.add(_PendingCapture(file: capture.file, quad: capture.quad));
        }
      }
    }

    // Every captured page shows in the document immediately, as itself,
    // while it is still being written: storing a page means decoding and
    // re-encoding a multi-megapixel photo, and a grid that stays empty
    // until that finishes reads as a scan that didn't work.
    state.pendingPages = [for (final p in imageList) p.file.path];
    if (imageList.isNotEmpty) emitState(state);

    int stored = 0;
    for (_PendingCapture pending in imageList) {
      if (await _storePending(pending)) stored++;
      // Emitted here as well as inside _storePending: the last page's
      // placeholder would otherwise sit there until something else
      // happened to rebuild the grid.
      state.pendingPages = state.pendingPages.sublist(1);
      emitState(state);
    }

    // Run once after every image in this call's imageList has been copied
    // to permanent storage, not per-image inside the loop above: it wipes
    // the whole OS temp/cache directory, which is also where
    // still-unprocessed images in a multi-image imageList (batch live-scan,
    // multi-select gallery import) live until their turn in the loop —
    // deleting it mid-loop silently drops every image after the first.
    await fileOperations.deleteTemporaryImages();
    return (stored: stored, skipped: imageList.length - stored);
  }

  /// Writes one capture into the document as a new last page.
  ///
  /// Returns false when there was nothing to store — the capture is gone
  /// from disk, or it turned out not to be an image the app can draw.
  Future<bool> _storePending(_PendingCapture pending) async {
    File image = pending.file;
    if (!image.existsSync()) return false;

    ImageOS? savedImage = await fileOperations.saveCapture(
      source: image,
      quad: pending.quad,
      keepOriginal: AppSettings.instance.keepOriginal,
      index: state.images!.length + 1,
      dirPath: state.dirPath!,
    );
    if (savedImage == null) {
      debugPrint("Skipped ${image.path}: not an image this app can read");
      return false;
    }
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
    return true;
  }

  /// Re-scans a single page: the capture *replaces* [imageOS] in place —
  /// same position in the document, same database row — rather than being
  /// appended as an extra page. Re-scanning is how you redo a page that
  /// came out badly, so leaving the bad one behind would mean deleting it
  /// by hand after every single re-scan.
  ///
  /// If the session captured more than one page (the camera stays open for
  /// batches), the first replaces [imageOS] and the rest are appended, so
  /// nothing the user actually shot is thrown away.
  Future<void> rescanImage(context, ImageOS imageOS) async {
    final captures = await captureWithLiveScan(context);
    if (captures == null || captures.isEmpty) return;

    final replacement = captures.first;
    if (replacement.file.existsSync()) {
      final String dir =
          imageOS.imgPath.substring(0, imageOS.imgPath.lastIndexOf("/"));

      final written = await fileOperations.writeCapture(
        source: replacement.file,
        dir: dir,
        stamp: DateTime.now().toString(),
        quad: replacement.quad,
        keepOriginal: AppSettings.instance.keepOriginal,
      );

      // A replacement the app cannot draw is not a replacement: the page
      // being re-scanned stays exactly as it was rather than being traded
      // for a blank one. Checked before anything is deleted, since the
      // old page is the only copy left once it goes.
      if (written != null) {
        // Every file the old page owned describes an image that is no longer
        // in the document: drop the page, its uncropped original and its
        // unfiltered copy before pointing the record at the new capture.
        _deleteImageFiles(imageOS);

        imageOS.imgPath = written.pagePath;
        imageOS.origPath = written.originalPath;

        await database.updateImagePath(
          tableName: state.dirName!,
          imgPath: imageOS.imgPath,
          origPath: imageOS.origPath,
          clearFilter: true,
          // The replaced page's original has just been deleted: if this
          // capture kept none of its own, the column has to be emptied
          // rather than left pointing at that dead file.
          clearOriginal: true,
          idx: imageOS.idx,
        );

        // A re-scan is a fresh page, so it picks up the default filter the
        // same way a newly captured one does.
        final defaultFilter = AppSettings.instance.defaultFilter;
        if (defaultFilter != null) {
          await _applyFilter(imageOS, documentFilterByName(defaultFilter));
        }

        state.images![imageOS.idx! - 1] = imageOS;
        if (imageOS.idx == 1) {
          state.firstImgPath = imageOS.imgPath;
        }
        emitState(state);
      }
    }

    for (final capture in captures.skip(1)) {
      await _storePending(
          _PendingCapture(file: capture.file, quad: capture.quad));
    }

    await fileOperations.deleteTemporaryImages();
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
      await fileOperations.storeNormalized(
        source: File(imageOS.filterSourcePath),
        destination: promoted,
        asOriginal: true,
      );
      imageOS.origPath = promoted.path;
    }

    // Creating new imagePath for cropped image. Normalized on the way in,
    // exactly like a fresh capture: the crop screen hands back a
    // full-quality warp, which is an intermediate, not a page.
    File temp = File('$dir/$stamp.jpg');
    await fileOperations.storeNormalized(source: image, destination: temp);
    if (workingCopy.existsSync()) workingCopy.deleteSync();
    File(imageOS.imgPath).deleteSync();
    imageOS.imgPath = temp.path;
    debugPrint('Image Cropped');

    // The crop came off the uncropped original, so any filtered result and
    // the unfiltered copy it was derived from both describe a page that no
    // longer exists. Drop them and let the page start filter-free again.
    _deleteUnfilteredCopy(imageOS);

    await database.updateImagePath(
      tableName: state.dirName!,
      imgPath: imageOS.imgPath,
      origPath: imageOS.origPath,
      clearFilter: true,
      idx: imageOS.idx,
    );
    debugPrint(imageOS.idx.toString());

    state.images![imageOS.idx! - 1] = imageOS;

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
    emitState(state);
  }

  /// Applies [filter] to every page of the document.
  Future<void> applyFilterToAllImages({required Filter filter}) async {
    for (ImageOS imageOS in state.images!) {
      await _applyFilter(imageOS, filter);
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
    await database.deleteImage(
      imgPath: imageToDelete.imgPath,
      tableName: state.dirName!,
    );

    bool directoryDeleted = false;

    try {
      // Delete directory if only 1 image exists
      Directory(state.dirPath!).deleteSync(recursive: false);
      await database.deleteDirectory(dirPath: state.dirPath!);
      Navigator.pop(context);
      directoryDeleted = true;
      debugPrint('Directory deleted');
    } catch (e) {
      state.images!.remove(imageToDelete);
      state.imageCount = state.images!.length;

      // Updating index of images
      for (int i = imageToDelete.idx! - 1; i < state.imageCount; i++) {
        state.images![i].idx = i + 1;
        await database.updateImageIndex(
          imgPath: state.images![i].imgPath,
          newIndex: state.images![i].idx,
          tableName: state.dirName!,
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
    debugPrint('Image count = ${state.imageCount} : ${state.images!.length}');
    List<ImageOS> imagesToDelete = [];

    for (int i = 0; i < state.images!.length; i++) {
      if (state.images![i].selected || deleteAll) {
        debugPrint('Deleting ${state.images![i].toMap()}');
        imagesToDelete.add(state.images![i]);
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
}

/// A capture on its way into storage: the photo, and the boundary it
/// should be cropped to (null for a gallery import, or a shot taken with
/// nothing detected — those are stored whole).
class _PendingCapture {
  final File file;
  final Quad? quad;

  const _PendingCapture({required this.file, this.quad});
}
