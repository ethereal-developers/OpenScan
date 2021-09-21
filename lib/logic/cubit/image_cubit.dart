import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/presentation/screens/crop_screen.dart';

part 'image_state.dart';

class ImageCubit extends Cubit<ImageState> {
  ImageCubit({
    idx,
    imgPath,
    selected,
  }) : super(ImageState(
          idx: idx,
          imgPath: imgPath,
          selected: selected,
        ));

  emitState() {
    emit(ImageState(
      idx: state.idx,
      imgPath: state.imgPath,
      selected: state.selected,
    ));
  }

  cropImage(context) async {
    File image = await imageCropper(
      context,
      File(state.imgPath),
    );

    // Creating new imagePath for cropped image
    if (image != null) {
      File temp = File(
          state.imgPath.substring(0, state.imgPath.lastIndexOf("/")) +
              '/' +
              DateTime.now().toString() +
              '.jpg');
      image.copySync(temp.path);
      File(state.imgPath).deleteSync();
      state.imgPath = temp.path;
    }
    print('Image Cropped');

    BlocProvider.of<DirectoryCubit>(context).cropImage();

    emitState();
  }
}
