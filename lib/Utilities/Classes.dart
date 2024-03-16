class DirectoryOS {
  String dirName;
  String dirPath;
  DateTime created;
  int imageCount;
  String? firstImgPath;
  DateTime lastModified;
  String newName;

  DirectoryOS({
    required this.dirName,
    required this.created,
    required this.dirPath,
    required this.imageCount,
    required this.lastModified,
    required this.newName,
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
