class DirectoryOS {
  String dirName;
  String dirPath;
  DateTime created;
  int imageCount;
  String? firstImgPath;
  DateTime? lastModified;
  String? newName;

  DirectoryOS({
    required this.dirName,
    required this.created,
    required this.dirPath,
    this.firstImgPath,
    this.imageCount = 0,
    this.lastModified,
    this.newName,
  });
}

class ImageOS {
  int? idx;
  String imgPath;

  /// Path to the uncropped capture [imgPath] was produced from, kept so a
  /// re-crop starts from the full original instead of re-cropping an
  /// already-cropped image. Null for images stored before originals were
  /// retained — callers fall back to [imgPath] in that case.
  String? origPath;
  bool selected;

  ImageOS({
    this.idx,
    required this.imgPath,
    this.origPath,
    this.selected = false,
  });

  /// The image a crop should start from: the original when one was kept.
  String get cropSourcePath => origPath ?? imgPath;

  Map toMap() {
    return {
      'idx': idx,
      'imgPath': imgPath,
      'origPath': origPath,
      'selected': selected,
    };
  }
}
