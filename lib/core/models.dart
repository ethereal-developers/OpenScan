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
  bool selected;

  ImageOS({
    this.idx,
    required this.imgPath,
    this.selected = false,
  });
}

class DocumentPoints {
  bool hasData;
  List<double>? points;

  DocumentPoints({required this.hasData, this.points});

  factory DocumentPoints.toDocumentPoints(data) {
    return DocumentPoints(
      hasData: data['hasPoints'],
      //TODO: Fill canvas if no points detected
      points:  data['hasPoints'] ? data['points']: data['points'],
    );
  }
}
