import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:openscan/core/cv/compress.dart';
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
    return directory!;
  }

  // <=========================== Image Operations ============================>

  /// Image picker opens camera
  ///
  /// Returns: Picked image [File]
  Future<File?> openCamera() async {
    File? image;
    var picture = await ImagePicker().pickImage(source: ImageSource.camera);
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
  /// [original] is the uncropped capture [image] was produced from. It is
  /// stored next to the page (prefixed `orig_`) and recorded in the
  /// database so a later re-crop can start from the full original rather
  /// than from the already-cropped page. Pass null to keep no original.
  ///
  /// Returns: Saved image record [ImageOS], carrying both stored paths
  Future<ImageOS> saveImage(
      {required File image,
      File? original,
      int? index,
      required String dirPath}) async {
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

    String stamp = DateTime.now().toString();
    File tempPic = File("$dirPath/$stamp.jpg");
    await image.copy(tempPic.path);

    // Always a separate file, even when it's byte-identical to the page
    // (an uncropped gallery import): cropping rewrites the page in place,
    // so an original sharing its path would be destroyed by the first
    // re-crop — the exact thing keeping originals is meant to prevent.
    String? origPath;
    if (original != null && original.existsSync()) {
      origPath = "$dirPath/orig_$stamp.jpg";
      await original.copy(origPath);
    }

    ImageOS saved = ImageOS(
      imgPath: tempPic.path,
      origPath: origPath,
      idx: index,
    );

    database.createImage(
      image: saved,
      tableName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
    );
    if (index == 1) {
      database.updateFirstImagePath(imagePath: tempPic.path, dirPath: dirPath);
    }
    return saved;
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
    // Page size is a user-visible export choice, so it is passed in
    // rather than left to the pdf package's A4 default.
    PdfPageFormat pageFormat = params['pageFormat'] ?? PdfPageFormat.a4;

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
            pageFormat: pageFormat,
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
      PdfPageFormat pageFormat = PdfPageFormat.a4,
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
        path = await compute(compressImageIsolateEntry, {
          'src': image.imgPath,
          'dest': cacheDir.path,
          'quality': desiredQuality,
        });
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
      'pageFormat': pageFormat,
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
      PdfPageFormat pageFormat = PdfPageFormat.a4,
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
      'images': imageFiles.isEmpty
          ? images
          : [for (final file in imageFiles) ImageOS(imgPath: file.path)],
      'pageFormat': pageFormat,
    });

    return fileNameWithPath;
  }

  /// Writes each page out as a standalone image file rather than a PDF.
  ///
  /// Returns the paths written, newest export first cleared of any partial
  /// results — an export that throws half way leaves nothing behind for the
  /// share sheet to pick up.
  Future<List<String>> exportImages({
    required List<ImageOS> images,
    required Directory directory,
    required String baseName,
    required String format,
    required int quality,
  }) async {
    return await compute(exportImagesIsolateEntry, {
      'sources': [for (final image in images) image.imgPath],
      'dest': directory.path,
      'baseName': baseName,
      'format': format,
      'quality': quality,
    });
  }

  /// The directory image exports land in: the same visible OpenScan folder
  /// PDFs use, falling back to app storage where that is not writable.
  Future<Directory> exportDirectory({BuildContext? context}) async {
    Directory openscanDir = Directory("/storage/emulated/0/Documents/OpenScan");
    try {
      if (!openscanDir.existsSync()) openscanDir.createSync(recursive: true);
      return openscanDir;
    } catch (e) {
      debugPrint('Falling back to app storage for export: $e');
      return await getApplicationDocumentsDirectory();
    }
  }
}

/// Entry point designed to be run via `compute()`. Re-encodes each source
/// image into `<dest>/<baseName>_<n>.<format>` and returns the paths.
Future<List<String>> exportImagesIsolateEntry(
    Map<String, dynamic> params) async {
  final List<String> sources = List<String>.from(params['sources'] as List);
  final String dest = params['dest'] as String;
  final String baseName = params['baseName'] as String;
  final String format = params['format'] as String;
  final int quality = params['quality'] as int;

  final written = <String>[];
  try {
    for (int i = 0; i < sources.length; i++) {
      final decoded = img.decodeImage(await File(sources[i]).readAsBytes());
      if (decoded == null) throw StateError('Could not decode ${sources[i]}');

      final suffix = sources.length == 1 ? '' : '_${i + 1}';
      final path = '$dest/$baseName$suffix.$format';
      final bytes = format == 'png'
          ? img.encodePng(decoded)
          // PNG is lossless, so the quality control only reaches JPEG.
          : img.encodeJpg(decoded, quality: quality);
      await File(path).writeAsBytes(bytes, flush: true);
      written.add(path);
    }
  } catch (e) {
    for (final path in written) {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    }
    rethrow;
  }
  return written;
}
