import 'package:openscan/core/services/document_scanner_service.dart';
import 'dart:io';

class DirectoryOS {
  String dirName;
  String dirPath;
  DateTime created;
  int imageCount;
  String? firstImgPath;
  DateTime? lastModified;
  String? newName;
  int? size;

  DirectoryOS({
    required this.dirName,
    required this.created,
    required this.dirPath,
    this.firstImgPath,
    this.imageCount = 0,
    this.lastModified,
    this.newName,
    this.size,
  });
}

class ImageOS {
  int? idx;
  String imgPath;
  bool selected;
  DocumentFilterType? filterType;

  ImageOS({
    this.idx,
    required this.imgPath,
    this.selected = false,
    this.filterType,
  });

  Map toMap() {
    return {
      'idx': idx,
      'imgPath': imgPath,
      'selected': selected,
      'filterType': filterType?.value,
    };
  }

  ImageOS copyWith({
    int? idx,
    String? imgPath,
    bool? selected,
    DocumentFilterType? filterType,
  }) {
    return ImageOS(
      idx: idx ?? this.idx,
      imgPath: imgPath ?? this.imgPath,
      selected: selected ?? this.selected,
      filterType: filterType ?? this.filterType,
    );
  }
}

class DocumentPoints {
  bool hasData;
  List<double>? points;

  DocumentPoints({required this.hasData, this.points});

  factory DocumentPoints.toDocumentPoints(data) {
    return DocumentPoints(
      hasData: data['hasPoints'],
      //TODO: Fill canvas if no points detected
      points: data['hasPoints'] ? data['points'] : data['points'],
    );
  }
}

class ImageProcessMessage {
  final File image;
  final String dirPath;
  final int index;

  ImageProcessMessage({
    required this.image,
    required this.dirPath,
    required this.index,
  });
}
