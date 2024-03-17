class DirectoryOS {
  String? dirName;
  String? dirPath;
  DateTime? created;
  int? imageCount;
  String? firstImgPath;
  DateTime? lastModified;
  String? newName;

  DirectoryOS({
    this.dirName,
    this.created,
    this.dirPath,
    this.imageCount,
    this.lastModified,
    this.newName,
    this.firstImgPath,
  });
}

class ImageOS {
  int idx;
  String imgPath;

  ImageOS({
    required this.idx,
    required this.imgPath,
  });
}
