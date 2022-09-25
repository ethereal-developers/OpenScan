import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FileOperations {
  final String appName = 'OpenScan';
  DatabaseHelper database = DatabaseHelper();

  /// Gets app directory path
  ///
  /// Returns: Directory path [String]
  Future<String> getAppPath() async {
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$appName/');

    if (await _appDocDirFolder.exists()) {
      return _appDocDirFolder.path;
    } else {
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
  }

  /// Generates PDF and saves it in directory
  ///
  /// Returns: Status of PDF saved [bool]
  Future<String?> createPdf(
      {required selectedDirectory, fileName, required List<ImageOS> images}) async {
    try {
      String fileNameWithPath = "${selectedDirectory.path}/$fileName.pdf";
      final output = File(fileNameWithPath);

      int i = 0;

      final doc = pw.Document();
      // TODO: Fix pdfImage

      for (i = 0; i < images.length; i++) {
        // final image = PdfImage.file(
        //   doc.document,
        //   bytes: images[i].readAsBytesSync(),
        // );

        doc.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                  // child: pw.Image.provider(image),
                  // child: pw.Image(image),
                  );
            },
            margin: pw.EdgeInsets.all(5.0),
          ),
        );
      }

      Uint8List dataToSave = await doc.save();
      output.writeAsBytesSync(dataToSave.toList());
      return fileNameWithPath;
    } catch (e) {
      return null;
    }
  }

  // ADD IMAGES
  Future<File?> openCamera() async {
    File? image;
    var picture = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picture != null) {
      image = File(picture.path);
    }
    return image;
  }

  Future<List<File>> openGallery() async {
    List<XFile>? pic;
    try {
      pic = await ImagePicker().pickMultiImage();
    } catch (e) {
      print(e);
    }

    List<File> imageFiles = [];

    if (pic != null) {
      for (XFile image in pic) {
        imageFiles.add(File(image.path));
      }
    }
    print(imageFiles);
    return imageFiles;
  }

  Future<File> saveImage(
      {required File image, int? index, required String dirPath}) async {
    if (!await Directory(dirPath).exists()) {
      new Directory(dirPath).create();
      await database.createDirectory(
        directory: DirectoryOS(
          dirName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
          dirPath: dirPath,
          imageCount: 0,
          created: DateTime.parse(dirPath
              .substring(dirPath.lastIndexOf('/') + 1)
              .substring(
                  dirPath.substring(dirPath.lastIndexOf('/') + 1).indexOf(' ') +
                      1)),
          newName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
          lastModified: DateTime.parse(dirPath
              .substring(dirPath.lastIndexOf('/') + 1)
              .substring(
                  dirPath.substring(dirPath.lastIndexOf('/') + 1).indexOf(' ') +
                      1)),
          firstImgPath: null,
        ),
      );
    }

    // TODO: Refactor index in image path

    /// Removed Index in image path
    File tempPic = File("$dirPath/${DateTime.now()}.jpg");
    image.copy(tempPic.path);
    database.createImage(
      image: ImageOS(
        imgPath: tempPic.path,
        idx: index,
      ),
      tableName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
    );
    if (index == 1) {
      database.updateFirstImagePath(imagePath: tempPic.path, dirPath: dirPath);
    }
    return tempPic;
  }

  // SAVE TO DEVICE
  Future<Directory> pickDirectory(
      BuildContext? context, selectedDirectory) async {
    Directory? directory = selectedDirectory;
    try {
      if (Platform.isAndroid) {
        directory = Directory("/storage/emulated/0/");
      } else {
        directory = await getExternalStorageDirectory();
      }
    } catch (e) {
      print(e);
      directory = await getExternalStorageDirectory();
    }

    // Directory newDirectory = await DirectoryPicker.pick(
    //     allowFolderCreation: true,
    //     context: context,
    //     rootDirectory: directory,
    //     shape: RoundedRectangleBorder(
    //         borderRadius: BorderRadius.all(Radius.circular(10))));

    return directory!;
  }

  /// Saves PDF to Device Internal
  ///
  /// Returns: FileName with Path [String]
  Future<String?> saveToDevice(
      {BuildContext? context,
      required String fileName,
      required List<ImageOS> images,
      int? quality}) async {
    String? fileNameWithPath;
    Directory? selectedDirectory;
    Directory openscanDir = Directory("/storage/emulated/0/OpenScan");
    Directory openscanPdfDir = Directory("/storage/emulated/0/OpenScan/PDF");
    int desiredQuality = 100;

    try {
      if (!openscanDir.existsSync()) {
        openscanDir.createSync();
        openscanPdfDir.createSync();
      }
      selectedDirectory = openscanPdfDir;
    } catch (e) {
      print(e);
      selectedDirectory = await pickDirectory(context, selectedDirectory);
    }

    List<ImageOS> tempImages = [];
    String path;

    if (quality == 1) {
      desiredQuality = 60;
    } else if (quality == 2) {
      desiredQuality = 80;
    } else {
      desiredQuality = 100;
    }

    print(desiredQuality);

    Directory cacheDir = await getTemporaryDirectory();
    for (ImageOS image in images) {
      // path = await FlutterScannerCropper.compressImage(
      //   src: image.imgPath,
      //   dest: cacheDir.path,
      //   desiredQuality: desiredQuality,
      // );
      // tempImages.add(File(path));
      tempImages.add(image);
    }
    images = tempImages;

    fileNameWithPath = await createPdf(
      selectedDirectory: selectedDirectory,
      fileName: fileName,
      images: images,
    ).toString();
    return fileNameWithPath;
  }

  /// Saves PDF to App directory
  ///
  /// Returns: FileName with Path [String]
  Future<String?> saveToAppDirectory(
      {BuildContext? context,
      String? fileName,
      required List<ImageOS> images,
      required bool imagesSelected}) async {
    String? fileNameWithPath;
    Directory selectedDirectory = await getApplicationDocumentsDirectory();
    List<File> imageFiles = [];

    for (ImageOS image in images) {
      if (image.selected || !imagesSelected) {
        imageFiles.add(File(image.imgPath!));
      }
    }

    fileNameWithPath = await createPdf(
      selectedDirectory: selectedDirectory,
      fileName: fileName,
      images: images,
    );
    return fileNameWithPath;
  }

  /// Delete the temporary files created by the image_picker package
  Future<void> deleteTemporaryFiles() async {
    Directory? appDocDir = await getExternalStorageDirectory();
    Directory cacheDir = await getTemporaryDirectory();
    String appDocPath = "${appDocDir!.path}/Pictures/";
    Directory del = Directory(appDocPath);
    if (del.existsSync()) {
      del.deleteSync(recursive: true);
    }
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
    new Directory(appDocPath).create();
  }
}
