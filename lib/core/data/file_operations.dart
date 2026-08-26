import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:openscan/core/cv/capture_pipeline.dart';
import 'package:openscan/core/cv/compress.dart';
import 'package:openscan/core/cv/models/quad.dart';
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

  /// Writes one capture into [dirPath] as a page — cropped to [quad] if
  /// there is one, downscaled and re-encoded to page size either way — and
  /// records it in the database.
  ///
  /// When [keepOriginal] is set, what the page would have been uncropped
  /// is written alongside it (prefixed `orig_`) and recorded too, so a
  /// later re-crop can start from the full capture rather than from the
  /// already-cropped page. It costs nothing extra to produce: page and
  /// original come out of the same decode, in the same isolate pass.
  ///
  /// Returns: Saved image record [ImageOS], carrying both stored paths.
  Future<ImageOS> saveCapture({
    required File source,
    required String dirPath,
    Quad? quad,
    bool keepOriginal = false,
    int? index,
  }) async {
    await _ensureDirectory(dirPath);

    final stamp = DateTime.now().toString();
    final written = await writeCapture(
      source: source,
      dir: dirPath,
      stamp: stamp,
      quad: quad,
      keepOriginal: keepOriginal,
    );

    ImageOS saved = ImageOS(
      imgPath: written.pagePath,
      origPath: written.originalPath,
      idx: index,
    );

    // Awaited: the library grid counts a document's pages by querying
    // them, so a caller that refreshes as soon as this returns would
    // otherwise race the insert and show a document one page short.
    await database.createImage(
      image: saved,
      tableName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
    );
    return saved;
  }

  /// The file half of [saveCapture], without the database: writes
  /// `$dir/$stamp.jpg` (and `$dir/orig_$stamp.jpg` when [keepOriginal]) in
  /// one isolate pass. Used directly by the paths that own their own
  /// database bookkeeping, like replacing a page on re-scan.
  Future<({String pagePath, String? originalPath})> writeCapture({
    required File source,
    required String dir,
    required String stamp,
    Quad? quad,
    bool keepOriginal = false,
  }) async {
    final pagePath = '$dir/$stamp.jpg';
    final originalPath = keepOriginal ? '$dir/orig_$stamp.jpg' : null;

    final result = await compute(storeCaptureIsolateEntry, {
      'src': source.path,
      'pageDest': pagePath,
      'pageMaxEdge': kStoredPageMaxEdge,
      'pageQuality': kStoredPageQuality,
      'quad': quad,
      'originalDest': originalPath,
      'originalMaxEdge': kStoredOriginalMaxEdge,
      'originalQuality': kStoredOriginalQuality,
    });

    return (
      pagePath: pagePath,
      // An original that failed to write is simply not recorded, rather
      // than leaving the page pointing at a file that isn't there.
      originalPath: (result['original'] ?? false) ? originalPath : null,
    );
  }

  /// Creates the document's folder and its database row if this is the
  /// first page being written into it.
  Future<void> _ensureDirectory(String dirPath) async {
    if (await Directory(dirPath).exists()) return;
    await Directory(dirPath).create();

    final dirName = dirPath.substring(dirPath.lastIndexOf('/') + 1);
    final created = DateTime.parse(dirName.substring(dirName.indexOf(' ') + 1));
    await database.createDirectory(
      directory: DirectoryOS(
        dirName: dirName,
        dirPath: dirPath,
        imageCount: 0,
        created: created,
        newName: dirName,
        lastModified: created,
        firstImgPath: null,
      ),
    );
  }

  /// Copies [source] into permanent storage the same way a capture is
  /// stored — downscaled to page size and re-encoded — for the paths that
  /// write a page file directly from an image that is already in hand
  /// (the crop screen's result, an original being promoted).
  Future<void> storeNormalized({
    required File source,
    required File destination,
    bool asOriginal = false,
  }) =>
      _copyNormalized(
        source: source,
        destination: destination,
        maxEdge: asOriginal ? kStoredOriginalMaxEdge : kStoredPageMaxEdge,
        quality: asOriginal ? kStoredOriginalQuality : kStoredPageQuality,
      );

  /// Copies [source] to [destination], downscaled and re-encoded on the
  /// way so what lands in storage is a page-sized JPEG rather than a
  /// full-resolution camera or gallery photo.
  ///
  /// Falls back to a plain copy if the image can't be decoded or re-encoded
  /// — an oversized page is worth far more than no page at all.
  Future<void> _copyNormalized({
    required File source,
    required File destination,
    required int maxEdge,
    required int quality,
  }) async {
    try {
      await compute(normalizeImageIsolateEntry, {
        'src': source.path,
        'dest': destination.path,
        'maxEdge': maxEdge,
        'quality': quality,
      });
      if (destination.existsSync() && destination.lengthSync() > 0) return;
    } catch (e) {
      debugPrint("Couldn't normalize ${source.path}: $e");
    }
    await source.copy(destination.path);
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
  /// [quality] is a JPEG quality (0-100) every page is re-encoded at on
  /// the way into the document — the same number the export sheet quotes
  /// a size for.
  ///
  /// Returns: FileName with Path [String]
  Future<String?> saveToDevice(
      {BuildContext? context,
      required String fileName,
      required List<ImageOS> images,
      PdfPageFormat pageFormat = PdfPageFormat.a4,
      int quality = 100}) async {
    Directory? selectedDirectory;
    Directory openscanDir = Directory("/storage/emulated/0/Documents/OpenScan");

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

    // TODO: remove await and display toast
    return await compute(createPdf, {
      'selectedDirectory': selectedDirectory,
      'fileName': fileName,
      'images': await _compressedForPdf(images, quality),
      'pageFormat': pageFormat,
    });
  }

  /// Re-encodes every page at [quality] into the cache directory, and
  /// hands back records pointing at those copies.
  ///
  /// Falls back to the pages themselves if anything goes wrong: a
  /// full-size PDF beats no PDF.
  Future<List<ImageOS>> _compressedForPdf(
      List<ImageOS> images, int quality) async {
    Directory cacheDir = await getTemporaryDirectory();
    List<ImageOS> compressed = [];
    try {
      for (ImageOS image in images) {
        final path = await compute(compressImageIsolateEntry, {
          'src': image.imgPath,
          'dest': cacheDir.path,
          'quality': quality,
        });
        compressed.add(ImageOS(imgPath: path));
      }
      return compressed;
    } catch (e) {
      print(e);
      return images;
    }
  }

  /// Saves PDF to App directory
  ///
  /// The share path: same [quality] treatment as [saveToDevice], so a
  /// shared PDF and a saved one are the same file.
  ///
  /// Returns: FileName with Path [String]
  Future<String?> saveToAppDirectory(
      {BuildContext? context,
      String? fileName,
      required List<ImageOS> images,
      PdfPageFormat pageFormat = PdfPageFormat.a4,
      int quality = 100,
      required bool imagesSelected}) async {
    Directory selectedDirectory = await getApplicationDocumentsDirectory();
    List<ImageOS> selected = [
      for (final image in images)
        if (image.selected || !imagesSelected) image,
    ];

    return await compute(createPdf, {
      'selectedDirectory': selectedDirectory,
      'fileName': fileName,
      'images':
          await _compressedForPdf(selected.isEmpty ? images : selected, quality),
      'pageFormat': pageFormat,
    });
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
