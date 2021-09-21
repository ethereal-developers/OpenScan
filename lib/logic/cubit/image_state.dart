part of 'image_cubit.dart';

class ImageState extends DirectoryState {
  int idx;
  String imgPath;
  bool selected;

  ImageState({
    this.idx,
    this.imgPath,
    this.selected = false,
  });
}
