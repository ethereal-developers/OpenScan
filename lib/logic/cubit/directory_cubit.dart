import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/presentation/screens/crop_screen.dart';
import 'package:path_provider/path_provider.dart';

part 'directory_state.dart';

/// Parameters: directoryOS, [imageOS]
/// Methods:
///   ImageOS => addImage, deleteImage, updateImagePath, updateImageIndex, [revertReorder]
///   DirectoryOS => updateImageCount, [updateFirstImagePath, deleteDirectory]

class DirectoryCubit extends Cubit<DirectoryState> {
  DirectoryCubit({
    dirName,
    created,
    dirPath,
    firstImgPath,
    imageCount,
    lastModified,
    newName,
    images,
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
  void onChange(Change change) {
    super.onChange(change);
    DirectoryState state = change.nextState;
    print('Change Notifier => ${state.imageCount}');
  }

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

  createDirectory() async {
    Directory appDir = await getExternalStorageDirectory();
    var now = DateTime.now();

    state.dirName = 'OpenScan $now';
    state.created = now;
    state.dirPath = '${appDir.path}/${state.dirName}';
    state.firstImgPath = '';
    state.imageCount = 0;
    state.lastModified = now;
    state.newName = null;
    state.images = <ImageOS>[];

    emitState(state);
  }

  getImageData() async {
    state.images = [];
    var directoryData = await database.getDirectoryData(state.dirName);
    print('From Cubit => $directoryData');
    for (var image in directoryData) {
      var i = image['idx'];

      ImageOS tempImageOS = ImageOS(
        idx: i,
        imgPath: image['img_path'],
      );
      state.images.add(
        tempImageOS,
      );

      emitState(state);

      // initDirectoryImages.add(
      //   tempImageOS,
      // );

      // imageCards.add(
      //   ImageCard(
      //     imageOS: tempImageOS,
      //     directoryOS: widget.directoryOS,
      //     fileEditCallback: () {
      //       fileEditCallback(imageOS: tempImageOS);
      //     },
      //     selectCallback: () {
      //       selectionCallback(imageOS: tempImageOS);
      //     },
      //     imageViewerCallback: () {
      //       imageViewerCallback(imageOS: tempImageOS);
      //     },
      //   ),
      // );

      // imageFilesPath.add(image['img_path']);
      // selectedImageIndex.add(false);
      // index += 1;
    }
  }

  onReorderImages(int oldIndex, int newIndex) {
    ImageOS image1 = state.images.removeAt(oldIndex);
    state.images.insert(newIndex, image1);
    emitState(state);
  }

  confirmReorderImages() {
    for (var i = 1; i <= state.images.length; i++) {
      state.images[i - 1].idx = i;
      if (i == 1) {
        database.updateFirstImagePath(
          dirPath: state.dirPath,
          imagePath: state.images[i - 1].imgPath,
        );
        state.firstImgPath = state.images[i - 1].imgPath;
      }
      database.updateImagePath(
        image: state.images[i - 1],
        tableName: state.dirName,
      );
      emitState(state);
    }
  }

  createImage(
    context, {
    bool quickScan = false,
    bool fromGallery = false,
  }) async {
    List<File> imageList = [];

    if (fromGallery) {
      imageList = await fileOperations.openGallery();
    } else {
      File image = await fileOperations.openCamera();
      if (image != null) {
        imageList = [await imageCropper(context, image)];
      }
    }

    for (File image in imageList) {
      if (image.existsSync()) {
        await fileOperations.saveImage(
          image: image,
          index: state.images.length + 1,
          dirPath: state.dirPath,
        );

        ImageOS imageOS = ImageOS(
          idx: state.imageCount + 1,
          imgPath: image.path,
        );
        state.images.add(imageOS);
        state.imageCount = state.images.length;

        // print('Image Saved');
        emitState(state);

        await fileOperations.deleteTemporaryFiles();
        if (quickScan) {
          return createImage(context, quickScan: quickScan);
        }
      }
    }
  }

  cropImage(context, {ImageOS imageOS}) async {
    File image = await imageCropper(
      context,
      File(imageOS.imgPath),
    );

    // Creating new imagePath for cropped image
    if (image != null) {
      File temp = File(
          imageOS.imgPath.substring(0, imageOS.imgPath.lastIndexOf("/")) +
              '/' +
              DateTime.now().toString() +
              '.jpg');
      image.copySync(temp.path);
      File(imageOS.imgPath).deleteSync();
      imageOS.imgPath = temp.path;
    }

    database.updateImagePath(
      tableName: state.dirName,
      image: imageOS,
    );

    state.images[imageOS.idx - 1] = imageOS;

    if (imageOS.idx == 1) {
      database.updateFirstImagePath(
        imagePath: imageOS.imgPath,
        dirPath: state.dirPath,
      );
    }

    emitState(state);
  }

  deleteImage(context, {ImageOS imageToDelete}) async {
    // Deleting image from database
    File(imageToDelete.imgPath).deleteSync();
    database.deleteImage(
      imgPath: imageToDelete.imgPath,
      tableName: state.dirName,
    );

    try {
      // Delete directory if 1 image exists
      Directory(state.dirPath).deleteSync(recursive: false);
      database.deleteDirectory(dirPath: state.dirPath);
      Navigator.pop(context);
      print('Directory deleted');
    } catch (e) {
      state.images.removeAt(imageToDelete.idx - 1);
      state.imageCount = state.images.length;

      // Updating index of images
      for (int i = imageToDelete.idx - 1; i < state.imageCount; i++) {
        state.images[i].idx = i + 1;
        database.updateImageIndex(
          image: state.images[i],
          tableName: state.dirName,
        );
      }

      // Updating first image path
      if (imageToDelete.idx == 1) {
        database.updateFirstImagePath(
          imagePath: state.images[0].imgPath,
          dirPath: state.dirPath,
        );
      }
    }

    emitState(state);
  }

  deleteMultipleImages() {
    bool isFirstImage = false;
    // for (var i = 0; i < directoryImages.length; i++) {
    //   if (selectedImageIndex[i]) {
    //     // print('${directoryImages[i].idx}: ${directoryImages[i].imgPath}');
    //     if (directoryImages[i].imgPath == state.firstImgPath) {
    //       isFirstImage = true;
    //     }

    //     File(directoryImages[i].imgPath).deleteSync();
    //     database.deleteImage(
    //       imgPath: directoryImages[i].imgPath,
    //       tableName: state.dirName,
    //     );
    //   }
    // }
    database.updateImageCount(
      tableName: state.dirName,
    );
    try {
      Directory(state.dirPath).deleteSync(recursive: false);
      database.deleteDirectory(dirPath: state.dirPath);
    } catch (e) {
      print('Directory cant be deleted as it contains other files');
    }
    // removeSelection();
    // Navigator.pop(context);
  }
}
