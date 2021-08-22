import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/presentation/screens/crop_screen.dart';
import 'package:path_provider/path_provider.dart';

part 'directory_state.dart';

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

      emit(state);

      // // Updating first image path after delete
      // if (updateFirstImage) {
      //   database.updateFirstImagePath(
      //       imagePath: image['img_path'], dirPath: widget.directoryOS.dirPath);
      //   updateFirstImage = false;
      // }

      // Updating index of images after delete
      // if (updateIndex) {
      //   i = index;
      //   database.updateImageIndex(
      //     image: ImageOS(
      //       idx: i,
      //       imgPath: image['img_path'],
      //     ),
      //     tableName: widget.directoryOS.dirName,
      //   );
      // }

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
    emit(state);
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
      emit(state);
    }
  }

  createImage(
    context, {
    bool quickScan,
    bool fromGallery = false,
  }) async {
    File image;
    List<File> galleryImages;

    if (fromGallery) {
      galleryImages = await fileOperations.openGallery();
    } else {
      image = await fileOperations.openCamera();
    }

    Directory cacheDir = await getTemporaryDirectory();
    if (image != null || galleryImages != null) {
      if (!quickScan && !fromGallery) {
        image = await imageCropper(context, image);
      }

      if (fromGallery) {
        for (File galleryImage in galleryImages) {
          if (galleryImage.existsSync()) {
            await fileOperations.saveImage(
              image: galleryImage,
              index: state.images.length + 1,
              dirPath: state.dirPath,
            );
          }
          state.images.length++;
        }
      } else {
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
        emit(state);

        await fileOperations.deleteTemporaryFiles();
        if (quickScan) {
          // emit(state);
          // getImageData();
          return createImage(context, quickScan: quickScan);
        }
      }
    }
  }

  cropImage(context, {imageOS}) async {
    File image = await imageCropper(
      context,
      File(imageOS.imgPath),
    );

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
    if (imageOS.idx == 1) {
      database.updateFirstImagePath(
        imagePath: imageOS.imgPath,
        dirPath: state.dirPath,
      );
    }
    emit(state);
  }
}
