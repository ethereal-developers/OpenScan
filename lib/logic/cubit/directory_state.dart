part of 'directory_cubit.dart';

class DirectoryState {
  final String? dirName;
  final DateTime? created;
  final String? dirPath;
  final String? firstImgPath;
  final int imageCount;
  final DateTime? lastModified;
  final String? newName;
  final List<ImageOS>? images;
  final bool isLoading;

  DirectoryState({
    this.dirName,
    this.created,
    this.dirPath,
    this.firstImgPath,
    this.imageCount = 0,
    this.lastModified,
    this.newName,
    this.images,
    this.isLoading = false,
  });

  DirectoryState copyWith({
    String? dirName,
    DateTime? created,
    String? dirPath,
    String? firstImgPath,
    int? imageCount,
    DateTime? lastModified,
    String? newName,
    List<ImageOS>? images,
    bool? isLoading,
  }) {
    return DirectoryState(
      dirName: dirName ?? this.dirName,
      created: created ?? this.created,
      dirPath: dirPath ?? this.dirPath,
      firstImgPath: firstImgPath ?? this.firstImgPath,
      imageCount: imageCount ?? this.imageCount,
      lastModified: lastModified ?? this.lastModified,
      newName: newName ?? this.newName,
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
