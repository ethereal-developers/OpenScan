import 'package:bloc/bloc.dart';
import 'package:openscan/Utilities/Classes.dart';
import 'package:openscan/Utilities/database_helper.dart';

part 'directory_state.dart';

class DirectoryCubit extends Cubit<DirectoryState> {
  DirectoryCubit({
    dirName,
    created,
    dirPath,
    firstImgPath,
    imageCount,
    lastModified,
    newName,
  }) : super(DirectoryState(
          dirName: dirName,
          dirPath: dirPath,
          created: created,
          firstImgPath: firstImgPath,
          imageCount: imageCount,
          lastModified: lastModified,
          newName: newName,
        ));

  getImageData() async {
    DatabaseHelper database = DatabaseHelper();

    var directoryData = await database.getDirectoryData(state.dirName);
    print('From Cubit => $directoryData');
    for (var image in directoryData) {
      var i = image['idx'];

      ImageOS tempImageOS = ImageOS(
        idx: i,
        imgPath: image['img_path'],
      );
      state.images.add(
        tempImageOS,
      );

      emit(state);

      // // Updating first image path after delete
      // if (updateFirstImage) {
      //   database.updateFirstImagePath(
      //       imagePath: image['img_path'], dirPath: widget.directoryOS.dirPath);
      //   updateFirstImage = false;
      // }

      // Updating index of images after delete
      // if (updateIndex) {
      //   i = index;
      //   database.updateImageIndex(
      //     image: ImageOS(
      //       idx: i,
      //       imgPath: image['img_path'],
      //     ),
      //     tableName: widget.directoryOS.dirName,
      //   );
      // }

      // initDirectoryImages.add(
      //   tempImageOS,
      // );

      // imageCards.add(
      //   ImageCard(
      //     imageOS: tempImageOS,
      //     directoryOS: widget.directoryOS,
      //     fileEditCallback: () {
      //       fileEditCallback(imageOS: tempImageOS);
      //     },
      //     selectCallback: () {
      //       selectionCallback(imageOS: tempImageOS);
      //     },
      //     imageViewerCallback: () {
      //       imageViewerCallback(imageOS: tempImageOS);
      //     },
      //   ),
      // );

      // imageFilesPath.add(image['img_path']);
      // selectedImageIndex.add(false);
      // index += 1;
    }
  }
}
