import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';

part 'image_state.dart';

class ImageCubit extends Cubit<ImageState> {
  ImageCubit() : super(ImageState());
}
