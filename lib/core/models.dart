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
  String? imgPath;
  bool selected;

  ImageOS({
    this.idx,
    this.imgPath,
    this.selected = false,
  });
}
