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

  /// Path to the cropped-but-unfiltered image [imgPath] was produced from,
  /// kept so a filter can be changed or undone without compounding onto an
  /// already-filtered result. Null while the page carries no filter, in
  /// which case [imgPath] *is* the unfiltered image.
  ///
  /// Deliberately distinct from [origPath]: that one is the *uncropped*
  /// capture, so filtering from it would silently throw the crop away.
  String? unfilteredPath;

  /// [Filter.name] of the filter currently applied, or null for none.
  /// Stored rather than derived so the picker can open on the page's
  /// current mode.
  String? filterName;

  bool selected;

  ImageOS({
    this.idx,
    required this.imgPath,
    this.origPath,
    this.unfilteredPath,
    this.filterName,
    this.selected = false,
  });

  /// The image a crop should start from: the uncropped original when one
  /// was kept, otherwise the unfiltered version — cropping a filtered
  /// result would bake that filter into the new page permanently.
  String get cropSourcePath => origPath ?? unfilteredPath ?? imgPath;

  /// The image a filter should be computed from: the unfiltered version
  /// when one was kept, otherwise the page itself (nothing applied yet).
  String get filterSourcePath => unfilteredPath ?? imgPath;

  Map toMap() {
    return {
      'idx': idx,
      'imgPath': imgPath,
      'origPath': origPath,
      'unfilteredPath': unfilteredPath,
      'filterName': filterName,
      'selected': selected,
    };
  }
}
