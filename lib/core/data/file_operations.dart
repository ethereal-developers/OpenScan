import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:openscan/core/cv/capture_pipeline.dart';
import 'package:openscan/core/cv/compress.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/core/cv/native_decode.dart';
import 'package:openscan/core/cv/perspective_crop.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/data/document_naming.dart';
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

  // <=========================== Image Operations ============================>

  /// Image picker opens gallery
  ///
  /// Returns: Picked images [List]
  /// Throws whatever the picker throws — a gallery that refused to open is
  /// something the caller has to tell the user about, and an empty list
  /// looks exactly like a picker the user backed out of.
  Future<List<File>> openGallery() async {
    final pic = await ImagePicker().pickMultiImage();
    return [for (final image in pic) File(image.path)];
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
  /// Returns: Saved image record [ImageOS], carrying both stored paths, or
  /// null when [source] turned out not to be a readable image — see
  /// [writeCapture]. Nothing is written to the database in that case: a
  /// page the app cannot draw is worse than no page, because it fills a
  /// slot in the document and exports as a hole in the PDF.
  Future<ImageOS?> saveCapture({
    required File source,
    required String dirPath,
    Quad? quad,
    bool keepOriginal = false,
    int? index,
    bool prepared = false,
    File? preparedOriginal,
  }) async {
    await _ensureDirectory(dirPath);

    final stamp = DateTime.now().toString();
    final written = await writeCapture(
      source: source,
      dir: dirPath,
      stamp: stamp,
      quad: quad,
      keepOriginal: keepOriginal,
      prepared: prepared,
      preparedOriginal: preparedOriginal,
    );
    if (written == null) return null;

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
  ///
  /// A capture the pipeline could not decode is copied through untouched
  /// rather than dropped — a format only the platform decoder knows, like
  /// HEIC, still makes a perfectly good page — but those bytes have to
  /// clear the platform decoder before they count as one. A gallery pick
  /// that is truncated or corrupt would otherwise sail through as a page
  /// that nothing can draw: it lands in the grid as an empty placeholder,
  /// which reads as an import that silently did nothing.
  ///
  /// Returns null when that check fails, leaving no files behind.
  ///
  /// [prepared] says the capture has already been through this pipeline
  /// somewhere else — the live-scan screen runs it per page, the moment
  /// the shutter fires, so the work is finished before the user frames the
  /// next page — and only has to be moved into the document. [source] is
  /// then the finished page and [preparedOriginal] its uncropped
  /// companion, so [quad] is not applied a second time.
  Future<({String pagePath, String? originalPath})?> writeCapture({
    required File source,
    required String dir,
    required String stamp,
    Quad? quad,
    bool keepOriginal = false,
    bool prepared = false,
    File? preparedOriginal,
  }) async {
    final pagePath = '$dir/$stamp.jpg';
    final originalPath = keepOriginal ? '$dir/orig_$stamp.jpg' : null;

    // Already page-sized, already cropped to its boundary: the only thing
    // left is to move it in.
    if (prepared) {
      return _adoptPrepared(
        page: source,
        original: preparedOriginal,
        pagePath: pagePath,
        originalPath: originalPath,
      );
    }

    // The fast path: let the platform decode the capture, and leave the
    // isolate only the encoding. Falls through to the pure-Dart pipeline
    // below when the platform decoder cannot read these bytes at all.
    final native = await _writeCaptureNatively(
      source: source,
      pagePath: pagePath,
      originalPath: originalPath,
      quad: quad,
    );
    if (native != null) return native;

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

    final wrotePage = result['page'] ?? false;
    final decoded = result['decoded'] ?? false;
    if (!wrotePage || (!decoded && !await _isDisplayable(pagePath))) {
      _deleteIfPresent(pagePath);
      if (originalPath != null) _deleteIfPresent(originalPath);
      return null;
    }

    return (
      pagePath: pagePath,
      // An original that failed to write is simply not recorded, rather
      // than leaving the page pointing at a file that isn't there.
      originalPath: (result['original'] ?? false) ? originalPath : null,
    );
  }

  /// Moves an already-processed page (and its original, if it has one)
  /// into the document, without decoding or re-encoding either: the bytes
  /// are already exactly what storage wants.
  ///
  /// The same displayability guard as the processing path applies — a
  /// staged file that turned out unreadable, or a copy that failed part
  /// way, leaves no page behind rather than an empty slot in the grid.
  Future<({String pagePath, String? originalPath})?> _adoptPrepared({
    required File page,
    required File? original,
    required String pagePath,
    required String? originalPath,
  }) async {
    try {
      await page.copy(pagePath);
    } catch (e) {
      debugPrint("Couldn't move prepared page ${page.path}: $e");
      _deleteIfPresent(pagePath);
      return null;
    }
    if (!await _isDisplayable(pagePath)) {
      _deleteIfPresent(pagePath);
      return null;
    }

    // An original that failed to move is simply not recorded, rather than
    // leaving the page pointing at a file that isn't there.
    String? storedOriginal;
    if (originalPath != null && original != null) {
      try {
        await original.copy(originalPath);
        storedOriginal = originalPath;
      } catch (e) {
        debugPrint("Couldn't move prepared original ${original.path}: $e");
        _deleteIfPresent(originalPath);
      }
    }

    return (pagePath: pagePath, originalPath: storedOriginal);
  }

  /// Stores a capture using the platform's image decoder, which decodes
  /// and downscales in one native step: on a mid-range phone that is ~350ms
  /// against the ~4s `package:image` spends decoding a 12MP capture and
  /// resizing it in pure Dart. Only the JPEG encode stays in an isolate,
  /// since `dart:ui` has no JPEG encoder and `package:image`'s would block
  /// the UI.
  ///
  /// One decode per file written, each at exactly the size that file needs,
  /// rather than one decode reused for both: a native decode is now cheap
  /// enough that decoding twice costs far less than resizing once in Dart,
  /// and it keeps only one page-sized buffer alive at a time.
  ///
  /// Returns null when the platform decoder cannot read the capture — an
  /// unknown format, or bytes that aren't an image — leaving the caller to
  /// fall back to the pure-Dart pipeline, which knows a few formats the
  /// platform doesn't and has its own copy-through last resort.
  Future<({String pagePath, String? originalPath})?> _writeCaptureNatively({
    required File source,
    required String pagePath,
    required String? originalPath,
    required Quad? quad,
  }) async {
    final Uint8List encoded;
    try {
      encoded = await source.readAsBytes();
    } catch (e) {
      debugPrint("Couldn't read ${source.path}: $e");
      return null;
    }

    final page = await _decodeForPage(encoded, quad, label: source.path);
    if (page == null) return null;

    final wrotePage = await compute(encodeStoredPageIsolateEntry, {
      'rgba': page.rgba,
      'width': page.width,
      'height': page.height,
      'dest': pagePath,
      'quality': kStoredPageQuality,
      'maxEdge': kStoredPageMaxEdge,
      'quad': quad,
    });
    if (!wrotePage) {
      _deleteIfPresent(pagePath);
      return null;
    }

    // An original that failed to write is simply not recorded, rather than
    // leaving the page pointing at a file that isn't there. The page is
    // already stored and readable, so this is never a reason to fall back.
    String? storedOriginal;
    if (originalPath != null) {
      final original = await decodeScaled(encoded,
          maxEdge: kStoredOriginalMaxEdge, label: source.path);
      if (original != null &&
          await compute(encodeStoredPageIsolateEntry, {
            'rgba': original.rgba,
            'width': original.width,
            'height': original.height,
            'dest': originalPath,
            'quality': kStoredOriginalQuality,
            'maxEdge': kStoredOriginalMaxEdge,
            'quad': null,
          })) {
        storedOriginal = originalPath;
      } else {
        _deleteIfPresent(originalPath);
      }
    }

    return (pagePath: pagePath, originalPath: storedOriginal);
  }

  /// The capture decoded at the smallest size that still fills a stored
  /// page.
  ///
  /// Without a boundary that is simply the page cap. With one, the warp
  /// only ever reads the quad's region, so decoding the whole capture at
  /// page size would leave the cropped result short of the cap — the decode
  /// is scaled so the quad's own natural size lands there instead, and the
  /// warp then runs about 1:1. Scaling during the decode also means the
  /// engine does the filtering, where the old path point-sampled the warp.
  Future<DecodedPixels?> _decodeForPage(Uint8List encoded, Quad? quad,
      {String? label}) async {
    if (quad == null) {
      return decodeScaled(encoded, maxEdge: kStoredPageMaxEdge, label: label);
    }

    final size = await decodedSize(encoded, label: label);
    if (size == null) return null;

    final natural =
        outputSize(quadInPixelsOf(quad, size.width, size.height));
    final longestOut = max(natural.width, natural.height);
    final longestSrc = max(size.width, size.height);
    if (longestOut <= kStoredPageMaxEdge) {
      return decodeScaled(encoded, maxEdge: longestSrc, label: label);
    }
    return decodeScaled(
      encoded,
      maxEdge: max(1, (longestSrc * kStoredPageMaxEdge / longestOut).round()),
      label: label,
    );
  }

  /// True when the platform's own image decoder can read the file at
  /// [path] — the same decoder behind every `Image.file` in the grid, the
  /// preview and the PDF, so what it refuses is exactly what the user
  /// would never see.
  Future<bool> _isDisplayable(String path) async {
    try {
      final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
      return true;
    } catch (e) {
      debugPrint('Not a readable image: $path ($e)');
      return false;
    }
  }

  void _deleteIfPresent(String path) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  /// Creates the document's folder and its database row if this is the
  /// first page being written into it.
  Future<void> _ensureDirectory(String dirPath) async {
    if (await Directory(dirPath).exists()) return;
    await Directory(dirPath).create();

    final dirName = dirPath.substring(dirPath.lastIndexOf('/') + 1);
    // A folder the app named carries its own created time; one named
    // anything else (a user's rename, an import) simply starts now rather
    // than throwing on a name that was never a date.
    final created = createdFromDocumentName(dirName) ?? DateTime.now();
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
    await Directory(appDocPath).create(recursive: true);
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
      debugPrint('Could not create PDF $fileName: $e');
      return null;
    }
  }

  /// Saves PDF to Internal storage
  ///
  /// [quality] is a JPEG quality (0-100) and [maxEdge] a cap on the long
  /// edge in pixels; every page is re-encoded to both on the way into the
  /// PDF — the same pair the export sheet quotes a size for. The defaults
  /// match what the page is already stored at, so a caller that does not
  /// choose (the library's bulk export) neither loses detail nor inflates
  /// the file re-encoding past it.
  ///
  /// Returns: FileName with Path [String]
  Future<String?> saveToDevice(
      {required String fileName,
      required List<ImageOS> images,
      PdfPageFormat pageFormat = PdfPageFormat.a4,
      int quality = kStoredPageQuality,
      int? maxEdge = kStoredPageMaxEdge}) async {
    final source = await _compressedForPdf(images, quality, maxEdge);
    try {
      return await compute(createPdf, {
        'selectedDirectory': await exportDirectory(),
        'fileName': fileName,
        'images': source.images,
        'pageFormat': pageFormat,
      });
    } finally {
      // finally, not after: a PDF that throws half way has still written
      // every page copy that got it that far.
      await _deleteStaged(source.staged);
    }
  }

  /// Re-encodes every page at [quality], capped at [maxEdge] pixels on its
  /// long edge, into staging, and hands back records pointing at those
  /// copies along with the paths it wrote.
  ///
  /// The caller deletes `staged` when the PDF is written. It is reported
  /// separately rather than inferred from the returned images because the
  /// two are not the same list on the failure path: a run that gives up
  /// half way falls back to the pages themselves — a full-size PDF beats
  /// no PDF — and deleting those would take the user's document with it.
  /// The copies it did manage to write are cleaned up there and then.
  Future<({List<ImageOS> images, List<String> staged})> _compressedForPdf(
      List<ImageOS> images, int quality, int? maxEdge) async {
    // Pages are already stored at exactly this quality/maxEdge, so
    // decoding and re-encoding them would just burn time to reproduce the
    // same bytes: use the stored files as-is.
    if (quality == kStoredPageQuality && maxEdge == kStoredPageMaxEdge) {
      return (images: images, staged: const <String>[]);
    }

    final stagingDir = await _stagingDirectory('pdf');
    // Compressed in parallel rather than one page at a time: the platform
    // decode below only blocks the calling isolate for as long as it takes
    // to kick off (the actual decode runs on the engine's own threads), and
    // each subsequent encode is its own compute() isolate, so starting all
    // of these together lets the work overlap instead of running as N
    // sequential passes. Each future catches its own failure so one bad
    // page doesn't strand the staged files the others already finished
    // writing.
    final results = await Future.wait([
      for (int i = 0; i < images.length; i++)
        _compressOneForPdf(
          images[i],
          quality,
          maxEdge,
          '${stagingDir.path}/$i.jpg',
        ),
    ]);

    if (results.contains(null)) {
      await _deleteStaged([for (final path in results) if (path != null) path]);
      return (images: images, staged: const <String>[]);
    }

    final staged = results.cast<String>();
    return (
      images: [for (final path in staged) ImageOS(imgPath: path)],
      staged: staged,
    );
  }

  /// Compresses one page for [_compressedForPdf], writing to the exact
  /// path [dest].
  ///
  /// Tries the platform decoder first — the same ~10x-faster path
  /// [_writeCaptureNatively] uses for storing a capture — and falls back to
  /// the pure-Dart `package:image` pipeline only when that decoder can't
  /// read the file, or the encode isolate reports a failure. Returns null
  /// when both paths fail.
  Future<String?> _compressOneForPdf(
    ImageOS image,
    int quality,
    int? maxEdge,
    String dest,
  ) async {
    try {
      final bytes = await File(image.imgPath).readAsBytes();
      final decoded = await decodeScaled(
        bytes,
        // No cap at all is `maxEdge: null`; the platform decoder wants an
        // int, so hand it a size nothing scans at.
        maxEdge: maxEdge ?? 1 << 20,
        label: image.imgPath,
      );
      if (decoded != null) {
        final wrote = await compute(encodeStoredPageIsolateEntry, {
          'rgba': decoded.rgba,
          'width': decoded.width,
          'height': decoded.height,
          'dest': dest,
          'quality': quality,
          'maxEdge': maxEdge ?? decoded.width,
          'quad': null,
        });
        if (wrote) return dest;
      }
    } catch (e) {
      debugPrint('Native compression failed for ${image.imgPath}: $e');
    }

    try {
      return await compute(compressImageIsolateEntry, {
        'src': image.imgPath,
        'dest': dest,
        'quality': quality,
        'maxEdge': maxEdge,
      });
    } catch (e) {
      debugPrint('Could not compress ${image.imgPath} for the PDF: $e');
      return null;
    }
  }

  /// Writes a PDF into [shareDirectory] for handing to another app.
  ///
  /// The share path: same [quality] treatment as [saveToDevice], so a
  /// shared PDF and a saved one are the same file. It goes to staging
  /// rather than anywhere the user would look for it, because nobody is
  /// meant to find it again — share_plus takes its own copy, and the next
  /// share clears this one.
  ///
  /// Returns: FileName with Path [String]
  Future<String?> saveForSharing(
      {BuildContext? context,
      String? fileName,
      required List<ImageOS> images,
      PdfPageFormat pageFormat = PdfPageFormat.a4,
      int quality = kStoredPageQuality,
      int? maxEdge = kStoredPageMaxEdge,
      required bool imagesSelected}) async {
    final selectedDirectory = await shareDirectory();
    List<ImageOS> selected = [
      for (final image in images)
        if (image.selected || !imagesSelected) image,
    ];

    final source = await _compressedForPdf(
        selected.isEmpty ? images : selected, quality, maxEdge);
    try {
      return await compute(createPdf, {
        'selectedDirectory': selectedDirectory,
        'fileName': fileName,
        'images': source.images,
        'pageFormat': pageFormat,
      });
    } finally {
      await _deleteStaged(source.staged);
    }
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
    int? maxEdge,
  }) async {
    return await compute(exportImagesIsolateEntry, {
      'sources': [for (final image in images) image.imgPath],
      'dest': directory.path,
      'baseName': baseName,
      'format': format,
      'quality': quality,
      'maxEdge': maxEdge,
    });
  }

  /// Where this app puts files that are not the user's own data: page
  /// copies re-encoded on the way into a PDF, and files staged for a
  /// share.
  ///
  /// Under the cache directory, deliberately. Everything here is
  /// disposable the moment the operation that made it finishes, and the
  /// cache is the one place Android lets the user reclaim without
  /// uninstalling — "Clear cache" in the app's storage settings empties
  /// it, and the system evicts it on its own when the device runs low.
  /// The app documents directory, where shared PDFs used to be staged,
  /// offers neither: a file written there is invisible, permanent, and
  /// removable only by clearing all app data, which also takes the
  /// user's library with it.
  Future<Directory> _stagingDirectory(String purpose) async {
    final dir =
        Directory('${(await getTemporaryDirectory()).path}/staging/$purpose');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// The directory a file being shared is staged in, emptied of whatever
  /// the last share left there.
  ///
  /// A share is a handoff, not a save: share_plus copies what it is given
  /// into its own provider directory before the receiving app ever sees
  /// it, so our copy is finished with as soon as the share sheet opens.
  /// Clearing on the way in rather than on the way out means a share
  /// interrupted by the app being killed does not leave its file behind
  /// for good.
  Future<Directory> shareDirectory() async {
    final dir = await _stagingDirectory('share');
    await _emptyDirectory(dir);
    return dir;
  }

  /// The directory a live-scan session stages its processed pages in,
  /// between the shutter firing and the pages being adopted into a
  /// document.
  ///
  /// Not emptied on the way in, unlike [shareDirectory]: one session
  /// stages page after page here, and the whole staging tree is purged at
  /// startup anyway, so a session killed mid-batch leaves nothing behind
  /// for good.
  Future<Directory> captureDirectory() => _stagingDirectory('capture');

  /// Deletes everything staged by an earlier run.
  ///
  /// Called at startup: staging is only ever needed for the length of one
  /// export or share, so anything still there is the residue of a run
  /// that was killed part way through.
  Future<void> purgeStaging() async {
    try {
      final root = Directory('${(await getTemporaryDirectory()).path}/staging');
      if (await root.exists()) await root.delete(recursive: true);
    } catch (e) {
      // Nothing here is load-bearing; a cache the OS will reclaim anyway
      // is not worth failing a launch over.
      debugPrint('Could not purge staging: $e');
    }
    await _purgeLegacySharedPdfs();
  }

  /// Removes PDFs left in the app documents directory by the versions that
  /// staged shares there.
  ///
  /// Those copies are invisible and permanent — no file manager reaches
  /// them and no "Clear cache" touches them, so an upgrade alone would
  /// leave every share a user had ever made sitting on their phone for
  /// good. Only loose *.pdf files at the top of that directory are
  /// touched, which is exactly what the old share path wrote there; the
  /// database and everything else beside them is left alone.
  Future<void> _purgeLegacySharedPdfs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
          debugPrint('Removing orphaned shared PDF: ${entity.path}');
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('Could not purge old shared PDFs: $e');
    }
  }

  Future<void> _emptyDirectory(Directory dir) async {
    try {
      await for (final entity in dir.list()) {
        await entity.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Could not empty ${dir.path}: $e');
    }
  }

  Future<void> _deleteStaged(List<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('Could not delete staged file $path: $e');
      }
    }
  }

  /// The directory exports land in — PDFs and images alike: a visible
  /// OpenScan folder under Downloads, falling back to app storage where
  /// that is not writable. There is no way to choose another one; a
  /// directory picker is a feature this has never had.
  ///
  /// Downloads rather than Documents because of what happens next. Opening
  /// an export goes through open_filex, which on API 30+ refuses any path
  /// outside the app's own directories unless it matches a hardcoded list
  /// of media folders — /DCIM/, /Pictures/, /Download/ and so on — or the
  /// app holds MANAGE_EXTERNAL_STORAGE, which this app has no business
  /// asking for. /Documents/ is not on that list, so every export landed
  /// somewhere the Open button could not reach. Verified on a device:
  /// Documents gives permissionDenied, Downloads opens.
  Future<Directory> exportDirectory() async {
    Directory openscanDir = Directory("/storage/emulated/0/Download/OpenScan");
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
  final int? maxEdge = params['maxEdge'] as int?;

  final written = <String>[];
  try {
    for (int i = 0; i < sources.length; i++) {
      final decoded = img.decodeImage(await File(sources[i]).readAsBytes());
      if (decoded == null) throw StateError('Could not decode ${sources[i]}');

      final suffix = sources.length == 1 ? '' : '_${i + 1}';
      final path = '$dest/$baseName$suffix.$format';
      // The preset's pixel cap reaches PNG even though its JPEG quality
      // does not: shedding pixels is lossy compression PNG can still do.
      final fitted = fitToMaxEdge(decoded, maxEdge);
      final bytes = format == 'png'
          ? img.encodePng(fitted)
          : img.encodeJpg(fitted, quality: quality);
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
