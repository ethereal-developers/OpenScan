import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/view/screens/crop_screen.dart';
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
    print('Change Notifier => ${state.imageCount}');
  }

  /// Updates the data to reflect in the UI - ad hoc
  emitState(state) {
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
  createDirectory() async {
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
  getImageData() async {
    state.images = [];
    var directoryData = await database.getImageData(state.dirName!);
    print('From Cubit => $directoryData');
    for (var image in directoryData) {
      ImageOS tempImage = ImageOS(
        idx: image['idx'],
        imgPath: image['img_path'],
        selected: false,
      );
      print('${tempImage.imgPath} => ${tempImage.idx}');
      state.images!.add(
        tempImage,
      );
    }
    state.imageCount = state.images!.length;
    emitState(state);
  }

  /// Updates image index after reordering
  updateImageIndex(int oldIndex, int newIndex) {
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
    }
    emitState(state);
  }

  /// Updates image paths
  confirmReorderImages() {
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

  /// Imports image from gallery and camera and stores it in db
  createImage(
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
        imageList = [await imageCropper(context, image)];
      }
    }

    for (File image in imageList) {
      if (image.existsSync()) {
        File savedImage = await fileOperations.saveImage(
          image: image,
          index: state.images!.length + 1,
          dirPath: state.dirPath!,
        );
        print('Saved ${savedImage.path}');

        ImageOS tempImage = ImageOS(
          idx: state.imageCount + 1,
          imgPath: savedImage.path,
        );
        print(tempImage.idx);
        state.images!.add(tempImage);
        state.imageCount = state.images!.length;

        emitState(state);

        await fileOperations.deleteTemporaryFiles();
        if (quickScan) {
          return createImage(context, quickScan: quickScan);
        }
      }
    }
  }

  /// Calls image cropper
  cropImage(context, ImageOS imageOS) async {
    File image = await imageCropper(
      context,
      File(imageOS.imgPath!),
    );

    // Creating new imagePath for cropped image
    File temp = File(
        imageOS.imgPath!.substring(0, imageOS.imgPath!.lastIndexOf("/")) +
            '/' +
            DateTime.now().toString() +
            '.jpg');
    image.copySync(temp.path);
    File(imageOS.imgPath!).deleteSync();
    imageOS.imgPath = temp.path;
    print('Image Cropped');

    database.updateImagePath(
      tableName: state.dirName!,
      imgPath: imageOS.imgPath,
      idx: imageOS.idx,
    );
    print(imageOS.idx);

    state.images![imageOS.idx! - 1] = imageOS;

    if (imageOS.idx == 1) {
      database.updateFirstImagePath(
        imagePath: imageOS.imgPath,
        dirPath: state.dirPath,
      );
    }
    print('Image paths updated');
    emitState(state);
  }

  /// Deletes image and updates db
  deleteImage(context, {required ImageOS imageToDelete}) async {
    // Deleting image from database
    File(imageToDelete.imgPath!).deleteSync();
    database.deleteImage(
      imgPath: imageToDelete.imgPath,
      tableName: state.dirName!,
    );

    try {
      // Delete directory if only 1 image exists
      Directory(state.dirPath!).deleteSync(recursive: false);
      database.deleteDirectory(dirPath: state.dirPath!);
      Navigator.pop(context);
      print('Directory deleted');
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
  }

  /// Deletes selected images, if [deleteAll]=false
  /// 
  /// Deletes all images in directory, if [deleteAll]=true
  deleteSelectedImages(context, {deleteAll = false}) {
    bool firstImageDeleted = false;
    for (int i = 0; i < state.imageCount; i++) {
      if (state.images![i].selected || deleteAll) {
        // Deleting image from storage
        File(state.images![i].imgPath!).deleteSync();

        // Deleting image from db
        database.deleteImage(
          imgPath: state.images![i].imgPath,
          tableName: state.dirName!,
        );
        firstImageDeleted = state.images![i].idx == 1;

        // Removing image from cubit
        bool res = state.images!.remove(state.images![i]);
        print(res ? 'Image: \@\#\!\$\&' : 'Image: Uh oh!!!');
        // state.images!.removeAt(image.idx! - 1);
        state.imageCount = state.images!.length;
      }
    }

    try {
      // Delete directory if 1 image exists
      Directory(state.dirPath!).deleteSync(recursive: false);
      database.deleteDirectory(dirPath: state.dirPath!);
      Navigator.pop(context);
      print('Directory: \@\#\!\$\&');
    } catch (e) {
      print('Directory: What a save!');

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
    // removeSelection();
    // Navigator.pop(context);
  }

  /// Selects image in directory
  selectImage(ImageOS imageOS) {
    state.images![imageOS.idx! - 1].selected =
        !state.images![imageOS.idx! - 1].selected;
    emitState(state);
  }

  /// Selects all images in directory/
  selectAllImages() {
    for (ImageOS image in state.images!) {
      image.selected = true;
    }
    emitState(state);
  }

  /// Deselects images in directory
  resetSelection() {
    for (ImageOS image in state.images!) {
      image.selected = false;
    }
    emitState(state);
  }

  /// Rename the directory name
  renameDocument(String newName) {
    state.newName = newName;
    emitState(state);
  }
}
