class DirectoryOS {
  String dirName;
  String dirPath;
  DateTime created;
  int imageCount;
  String firstImgPath;
  DateTime lastModified;
  String newName;

  DirectoryOS({
    this.dirName,
    this.created,
    this.dirPath,
    this.firstImgPath,
    this.imageCount,
    this.lastModified,
    this.newName,
  });
}

class ImageOS {
  int idx;
  String imgPath;
  int shouldCompress;

  ImageOS({
    this.idx,
    this.imgPath,
    this.shouldCompress,
  });
}
