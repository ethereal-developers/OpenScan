import 'dart:io';

import 'package:directory_picker/directory_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scanner_cropper/flutter_scanner_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openscan/Utilities/Classes.dart';
import 'package:openscan/Utilities/DatabaseHelper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FileOperations {
  String appName = 'OpenScan';
  static bool pdfStatus;
  DatabaseHelper database = DatabaseHelper();

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

  // CREATE PDF
  Future<bool> createPdf({selectedDirectory, fileName, images}) async {
    try {
      final output = File("${selectedDirectory.path}/$fileName.pdf");

      int i = 0;

      final doc = pw.Document();

      for (i = 0; i < images.length; i++) {
        final image = PdfImage.file(
          doc.document,
          bytes: images[i].readAsBytesSync(),
        );

        doc.addPage(pw.Page(build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image),
          ); // Center
        }));
      }

      output.writeAsBytesSync(doc.save());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ADD IMAGES
  Future<File> openCamera() async {
    File image;
    final _picker = ImagePicker();
    var picture = await _picker.getImage(source: ImageSource.camera);
    if (picture != null) {
      final requiredPicture = File(picture.path);
      image = requiredPicture;
    }
    return image;
  }

  Future<File> openGallery() async {
    File image;
    final _picker = ImagePicker();
    var picture = await _picker.getImage(source: ImageSource.gallery);
    if (picture != null) {
      final requiredPicture = File(picture.path);
      image = requiredPicture;
    }
    return image;
  }

  Future<void> saveImage(
      {File image, int index, String dirPath, int shouldCompress}) async {
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

    /// Removed Index in image path
    File tempPic = File("$dirPath/${DateTime.now()}.jpg");
    image.copy(tempPic.path);
    database.createImage(
      image: ImageOS(
        imgPath: tempPic.path,
        idx: index,
        shouldCompress: shouldCompress,
      ),
      tableName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
    );
    if (index == 1) {
      database.updateFirstImagePath(imagePath: tempPic.path, dirPath: dirPath);
    }
  }

  // SAVE TO DEVICE
  Future<Directory> pickDirectory(
      BuildContext context, selectedDirectory) async {
    Directory directory = selectedDirectory;
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

    Directory newDirectory = await DirectoryPicker.pick(
        allowFolderCreation: true,
        context: context,
        rootDirectory: directory,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))));

    return newDirectory;
  }

  Future<String> saveToDevice(
      {BuildContext context,
      String fileName,
      dynamic images,
      int quality}) async {
    Directory selectedDirectory;
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

    var tempImages = [];
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
      path = await FlutterScannerCropper.compressImage(
        src: image.imgPath,
        dest: cacheDir.path,
        desiredQuality: desiredQuality,
      );
      tempImages.add(File(path));
    }
    images = tempImages;

    fileName = fileName.replaceAll('-', '');
    fileName = fileName.replaceAll('.', '');
    fileName = fileName.replaceAll(':', '');

    pdfStatus = await createPdf(
      selectedDirectory: selectedDirectory,
      fileName: fileName,
      images: images,
    );
    return (pdfStatus) ? selectedDirectory.path : null;
  }

  Future<bool> saveToAppDirectory(
      {BuildContext context, String fileName, dynamic images}) async {
    Directory selectedDirectory = await getApplicationDocumentsDirectory();
    List<ImageOS> foo = [];
    if (images.runtimeType == foo.runtimeType) {
      var tempImages = [];
      for (ImageOS image in images) {
        tempImages.add(File(image.imgPath));
      }
      images = tempImages;
    }
    pdfStatus = await createPdf(
      selectedDirectory: selectedDirectory,
      fileName: fileName,
      images: images,
    );
    return pdfStatus;
  }

  Future<void> deleteTemporaryFiles() async {
    // Delete the temporary files created by the image_picker package
    Directory appDocDir = await getExternalStorageDirectory();
    String appDocPath = "${appDocDir.path}/Pictures/";
    Directory del = Directory(appDocPath);
    if (await del.exists()) {
      del.deleteSync(recursive: true);
    }
    new Directory(appDocPath).create();
  }
}
