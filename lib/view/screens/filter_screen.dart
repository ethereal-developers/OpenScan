import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as imageLib;
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/view/screens/preview_screen.dart';
import 'package:path/path.dart';

import '../../core/image_filter/filters/filters.dart';
import '../../core/image_filter/filters/preset_filters.dart';
import '../../logic/cubit/directory_cubit.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({
    Key? key,
    required this.pageIndex,
  }) : super(key: key);

  final int pageIndex;

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  Filter? _filter;
  // late bool loading;
  // late int _currentPageIndex;
  List<Filter> filters = presetFiltersList;
  late PageController _pageController;

  Future<Uint8List?> getBytes(File image) async {
    String cacheName = 'Original' + basename(image.path);
    if (PreviewScreen.previewModel.cachedFilters.containsKey(cacheName)) {
      return null;
    }
    return await image.readAsBytes();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.pageIndex);
    // loading = false;
    _filter = filters[0];
    // _currentPageIndex =
    //     PreviewScreen.previewModel.pageController!.page!.toInt();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(PreviewScreen.previewModel.cachedFilters.keys);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.5),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            padding: EdgeInsets.fromLTRB(15, 8, 0, 8),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        body: BlocConsumer<DirectoryCubit, DirectoryState>(
          listener: (context, state) {},
          builder: (context, state) {
            return PageView.builder(
              physics:
                  // enablePageScroll //TODO: Add double tap zoom - maybe
                  //       ?
                  ClampingScrollPhysics(),
              // : NeverScrollableScrollPhysics(),
              controller: _pageController,
              itemCount: state.imageCount,
              itemBuilder: (context, index) {
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.0),
                        child: _buildFilteredImage(
                          _filter,
                          File(state.images![index].imgPath),
                          basename(state.images![index].imgPath),
                        ),
                      ),
                    ),
                    Container(
                      height: 100,
                      child:
                          _buildBottomBar(File(state.images![index].imgPath)),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilteredImage(Filter? filter, File image, String? filename) {
    if (PreviewScreen.previewModel.cachedFilters[filter?.name == null
            ? '_' + filename!
            : filter!.name + filename!] ==
        null) {
      return FutureBuilder<List<int>>(
        future: compute(applyFilter, <String, dynamic>{
          "filter": filter,
          "image": image,
          "filename": filename,
        }),
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          print('Image => ${snapshot.connectionState}');
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            case ConnectionState.done:
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              // PreviewScreen.previewModel.cachedFilters[filter?.name == null
              //     ? '_' + filename
              // : filter!.name + filename] = snapshot.data;

              return Image.memory(
                snapshot.data as dynamic,
                fit: BoxFit.contain,
              );
          }
          // unreachable
        },
      );
    } else {
      print(
          'Showing image: ${filter?.name == null ? '_' + filename : filter!.name + filename}');
      return Image.memory(
        PreviewScreen.previewModel.cachedFilters[filter?.name == null
            ? '_' + filename
            : filter!.name + filename] as dynamic,
        fit: BoxFit.contain,
      );
    }
  }

  Widget _buildBottomBar(File imageFile) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: filters.length,
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          child: Container(
            padding: EdgeInsets.all(5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _buildFilterThumbnail(
                  filters[index],
                  imageFile,
                  basename(imageFile.path),
                ),
                SizedBox(
                  height: 5.0,
                ),
                Text(
                  filters[index].name,
                )
              ],
            ),
          ),
          onTap: () {
            if (_filter != filters[index]) {
              setState(() {
                _filter = filters[index];
              });
            }
          },
        );
      },
    );
  }

  _buildFilterThumbnail(Filter filter, File image, String? filename) {
    print('Filename: $filename');
    if (PreviewScreen.previewModel.cachedFilters[filter.name + filename!] ==
        null) {
      print('Image not cached: ${filter.name + filename}');
      return FutureBuilder<List<int>>(
        future: compute(applyFilter, <String, dynamic>{
          "filter": filter,
          "image": image,
          "filename": filename,
        }),
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          print('Thumbnail => ${snapshot.connectionState}');
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.active:
            case ConnectionState.waiting:
              return CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              );
            case ConnectionState.done:
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              // PreviewScreen.previewModel.cachedFilters[filter.name + filename] =
              //     snapshot.data;
              return FilterThumbnail(
                image: Image.memory(
                  snapshot.data as dynamic,
                ),
              );
          }
          // unreachable
        },
      );
    } else {
      print('Cached image: ${filter.name + filename}');
      return FilterThumbnail(
        image: Image.memory(
          PreviewScreen.previewModel.cachedFilters[filter.name + filename]
              as dynamic,
        ),
      );
    }
  }

  // Future<String> get _localPath async {
  //   final directory = await getApplicationDocumentsDirectory();

  //   return directory.path;
  // }

  // Future<File> get _localFile async {
  //   final path = await _localPath;
  //   return File('$path/filtered_${_filter?.name ?? "_"}_$filename');
  // }

  // Future<File> saveFilteredImage() async {
  //   var imageFile = await _localFile;
  //   await imageFile.writeAsBytes(PreviewScreen.previewModel.cachedFilters[_filter?.name ?? "_"]!);
  //   return imageFile;
  // }
}

class FilterThumbnail extends StatelessWidget {
  const FilterThumbnail({
    Key? key,
    required this.image,
  }) : super(key: key);

  final Widget image;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 60,
      child: image,
    );
  }
}

///The global applyfilter function
Future<List<int>> applyFilter(Map<String, dynamic> params) async {
  Filter? filter = params["filter"];
  File image = params["image"];
  String filename = params["filename"];

  imageLib.Image byteImage = imageLib.decodeImage(await image.readAsBytes())!;
  List<int> _bytes = byteImage.getBytes();
  if (filter != null) {
    filter.apply(_bytes as dynamic, byteImage.width, byteImage.height);
  }
  // imageLib.Image _image =
  //     imageLib.Image.fromBytes(imageBytes.width, imageBytes.height, _bytes);
  _bytes = imageLib.encodeNamedImage(byteImage, filename)!;

  PreviewScreen.previewModel.cachedFilters[
      filter?.name == null ? '_' + filename : filter!.name + filename] = _bytes;

  print(
      'Storing image: ${filter?.name == null ? '_' + filename : filter!.name + filename}');

  return _bytes;
}

///The global buildThumbnail function
// FutureOr<List<int>> buildThumbnail(Map<String, dynamic> params) {
//   int? width = params["width"];
//   params["image"] = imageLib.copyResize(params["image"], width: width);
//   return applyFilter(params);
// }
