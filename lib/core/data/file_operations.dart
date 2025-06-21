import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/data/native_android_util.dart';
import 'package:openscan/core/models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class FileOperations {
  final String appName = 'OpenScan';
  DatabaseHelper database = DatabaseHelper();

  /// Generates a clean, filesystem-safe folder name
  /// 
  /// Returns: Clean folder name [String]
  String generateCleanFolderName(DateTime dateTime) {
    // Format: OpenScan_YYYY-MM-DD_HH-MM-SS
    String year = dateTime.year.toString();
    String month = dateTime.month.toString().padLeft(2, '0');
    String day = dateTime.day.toString().padLeft(2, '0');
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String second = dateTime.second.toString().padLeft(2, '0');
    
    return 'OpenScan ${year}-${month}-${day}_${hour}-${minute}-${second}';
  }

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

  /// Selects directory wrt OS
  ///
  /// Returns: selected directory [Directory]
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

    // TODO: Pick custom directory
    // Directory newDirectory = await DirectoryPicker.pick(
    //     allowFolderCreation: true,
    //     context: context,
    //     rootDirectory: directory,
    //     shape: RoundedRectangleBorder(
    //         borderRadius: BorderRadius.all(Radius.circular(10))));

    return directory!;
  }

  // <=========================== Image Operations ============================>

  /// Image picker opens camera
  ///
  /// Returns: Picked image [File]
  Future<File?> openCamera() async {
    File? image;
    XFile? picture = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picture != null) {
      image = File(picture.path);
    }
    return image;
  }

  /// Image picker opens gallery
  ///
  /// Returns: Picked images [List]
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
    return imageFiles;
  }

  /// Saves image in directory and database
  ///
  /// Returns: Saved image [File]
  Future<File> saveImage(
      {required File image, int? index, required String dirPath}) async {
    // Create directory if it doesn't exist on filesystem
    if (!await Directory(dirPath).exists()) {
      new Directory(dirPath).create();
    }
    
    // Check if directory entry exists in database and create if it doesn't
    var masterData = await database.getMasterData();
    bool directoryExistsInDB = masterData.any((dir) => dir['dir_path'] == dirPath);
    
    if (!directoryExistsInDB) {
      // Extract the clean folder name from the path
      String folderName = dirPath.substring(dirPath.lastIndexOf('/') + 1);
      DateTime now = DateTime.now();
      
      await database.createDirectory(
        directory: DirectoryOS(
          dirName: folderName,
          dirPath: dirPath,
          imageCount: 0,
          created: now,
          newName: folderName,
          lastModified: now,
          firstImgPath: null,
        ),
      );
    }

    File tempPic = File("$dirPath/${DateTime.now().millisecondsSinceEpoch}.jpg");
    image.copySync(tempPic.path);
    image.deleteSync();
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

  /// Delete the temporary files created by the image_picker package
  Future<void> deleteTemporaryImages() async {
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

  // <============================ PDF Operations =============================>

  /// Generates PDF and saves it in directory
  ///
  /// Returns: Status of PDF saved [bool]
  Future<String?> createPdf(Map<String, dynamic> params) async {
    Directory selectedDirectory = params['selectedDirectory'];
    List<ImageOS> images = params['images'];
    String fileName = params['fileName'];

    try {
      String fileNameWithPath = "${selectedDirectory.path}/$fileName.pdf";
      final output = File(fileNameWithPath);
      final doc = pw.Document();
      for (int i = 0; i < images.length; i++) {
        final image = pw.MemoryImage(
          File(images[i].imgPath).readAsBytesSync(),
        );

        doc.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image),
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

  /// Saves PDF to Internal storage
  ///
  /// Returns: FileName with Path [String]
  Future<String?> saveToDevice(
      {BuildContext? context,
      required String fileName,
      required List<ImageOS> images,
      int? quality}) async {
    String? fileNameWithPath;
    Directory? selectedDirectory;
    Directory openscanDir = Directory("/storage/emulated/0/Documents/OpenScan");
    int desiredQuality = 100;
    List<ImageOS> tempImages = [];
    String path;

    try {
      if (!openscanDir.existsSync()) {
        openscanDir.createSync();
        openscanDir.createSync();
      }
      selectedDirectory = openscanDir;
    } catch (e) {
      print(e);
      selectedDirectory = await pickDirectory(context, selectedDirectory);
    }

    if (quality == 1) {
      desiredQuality = 60;
    } else if (quality == 2) {
      desiredQuality = 80;
    } else {
      desiredQuality = 100;
    }

    Directory cacheDir = await getTemporaryDirectory();

    try {
      for (ImageOS image in images) {
        path = await NativeAndroidUtil.compress(
            image.imgPath, cacheDir.path, desiredQuality);
        tempImages.add(ImageOS(imgPath: path));
      }
      images = tempImages;
    } catch (e) {
      print(e);
    }

    // TODO: remove await and display toast
    fileNameWithPath = await compute(createPdf, {
      'selectedDirectory': selectedDirectory,
      'fileName': fileName,
      'images': images,
    });

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

    // TODO: Export selected images
    for (ImageOS image in images) {
      if (image.selected || !imagesSelected) {
        imageFiles.add(File(image.imgPath));
      }
    }

    fileNameWithPath = await compute(createPdf, {
      'selectedDirectory': selectedDirectory,
      'fileName': fileName,
      'images': images,
    });

    return fileNameWithPath;
  }

  /// Shares PDF file using system share dialog
  ///
  /// Returns: Future<void>
  Future<void> sharePdf({
    required BuildContext context,
    required String fileName,
    required List<ImageOS> images,
    int? quality,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.secondary,
            ),
          ),
        );
      },
    );

    try {
      String? fileNameWithPath = await saveToAppDirectory(
        context: context,
        fileName: fileName,
        images: images,
        imagesSelected: false,
      );

      // Hide loading dialog
      Navigator.pop(context);

      if (fileNameWithPath != null) {
        await Share.shareXFiles(
          [XFile(fileNameWithPath)],
          subject: 'OpenScan Document',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share PDF'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
