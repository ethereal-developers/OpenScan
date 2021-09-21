part of 'directory_cubit.dart';

class DirectoryState {
  String dirName;
  String dirPath;
  DateTime created;
  int imageCount;
  String firstImgPath;
  DateTime lastModified;
  String newName;
  List<ImageCubit> images;

  DirectoryState({
    this.dirName,
    this.created,
    this.dirPath,
    this.firstImgPath,
    this.imageCount,
    this.lastModified,
    this.newName,
    this.images,
  });
}
