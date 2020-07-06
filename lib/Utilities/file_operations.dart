import 'dart:io';

import 'package:directory_picker/directory_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FileOperations {
  String appName = 'OpenScan';
  static bool pdfStatus;

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

  Future<void> saveImage({File image, int i, dirName}) async {
    if (await Directory(dirName).exists() != true) {
      new Directory(dirName).create();
    }

    File tempPic = File("$dirName/ ${DateTime.now()} $i .jpg");
    image.copy(tempPic.path);
  }

  // SAVE TO DEVICE
  Future<Directory> pickDirectory(
      BuildContext context, selectedDirectory) async {
    Directory directory = selectedDirectory;
    if (Platform.isAndroid) {
      directory = Directory("/storage/emulated/0/");
    } else {
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
      {BuildContext context, String fileName, dynamic images}) async {
    Directory selectedDirectory;
    Directory openscanDir = Directory("/storage/emulated/0/OpenScan/PDF");
    try {
      if (!openscanDir.existsSync()) {
        openscanDir.createSync();
      }
      selectedDirectory = openscanDir;
    } catch (e) {
      selectedDirectory = await pickDirectory(context, selectedDirectory);
    }
    List<Map<String, dynamic>> foo = [];
    if (images.runtimeType == foo.runtimeType) {
      var tempImages = [];
      for (var image in images) {
        tempImages.add(image["file"]);
      }
      images = tempImages;
    }
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

    List<Map<String, dynamic>> foo = [];
    if (images.runtimeType == foo.runtimeType) {
      var tempImages = [];
      for (var image in images) {
        tempImages.add(image["file"]);
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
