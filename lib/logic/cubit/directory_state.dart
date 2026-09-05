part of 'directory_cubit.dart';

class DirectoryState {
  String? dirName;
  String? dirPath;
  DateTime? created;
  int imageCount;
  String? firstImgPath;
  DateTime? lastModified;
  String? newName;
  List<ImageOS>? images;

  /// Captures that have been taken but not yet written into the document,
  /// as paths to the photos themselves. The grid shows one placeholder per
  /// entry so a finished scan is visible immediately, rather than after
  /// every page has been decoded and re-encoded.
  List<String> pendingPages;

  DirectoryState({
    this.dirName,
    this.created,
    this.dirPath,
    this.firstImgPath,
    this.imageCount = 0,
    this.lastModified,
    this.newName,
    this.images,
    this.pendingPages = const [],
  });
}
