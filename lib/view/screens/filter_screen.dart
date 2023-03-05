import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as imageLib;
import 'package:path/path.dart';

import '../../core/image_filter/filters/filters.dart';
import '../../core/image_filter/filters/preset_filters.dart';
import '../../logic/cubit/directory_cubit.dart';
import '../../logic/cubit/filter_cubit.dart';

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
  List<Filter> filters = presetFiltersList;
  Filter _filter = presetFiltersList[0];
  late PageController _pageController;
  late String currentImagePath;
  late String filterImageName;

  bool imageReady = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.pageIndex);
  }

  @override
  Widget build(BuildContext context) {
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
          builder: (context, directoryState) {
            return PageView.builder(
              physics:
                  // enablePageScroll
                  //       ?
                  ClampingScrollPhysics(),
              // : NeverScrollableScrollPhysics(),
              controller: _pageController,
              itemCount: directoryState.imageCount,
              onPageChanged: (value) {
                _imageBytes = null;
              },
              itemBuilder: (context, imageIndex) {
                currentImagePath = directoryState.images![imageIndex].imgPath;
                filterImageName = _filter.name + basename(currentImagePath);
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: BlocConsumer<FilterCubit, FilterState>(
                          listener: (context, state) {
                            print('Filter Cubit: ${state.cachedFilters.keys}');
                          },
                          buildWhen: (previous, current) {
                            if(!imageReady && current.cachedFilters[filterImageName] !=
                                    null) {
                              imageReady = true;
                              return true;
                            }
                            return false;
                          },
                          builder: (context, filterState) {
                            List<int>? filteredImage =
                                filterState.cachedFilters[filterImageName];

                            if (filteredImage != null) {
                              return Image.memory(
                                Uint8List.fromList(filteredImage),
                                fit: BoxFit.contain,
                              );
                            } else {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    Container(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filters.length,
                        itemBuilder: (BuildContext context, int filterIndex) {
                          String imagePath =
                              directoryState.images![imageIndex].imgPath;
                          return InkWell(
                            child: Container(
                              padding: EdgeInsets.all(5.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  FilterThumbnail(
                                    imagePath: imagePath,
                                    filter: filters[filterIndex],
                                  ),
                                  SizedBox(
                                    height: 5.0,
                                  ),
                                  Text(
                                    filters[filterIndex].name,
                                  )
                                ],
                              ),
                            ),
                            onTap: () {
                              if (_filter != filters[filterIndex]) {
                                _filter = filters[filterIndex];
                                filterImageName =
                                    _filter.name + basename(currentImagePath);
                                BlocProvider.of<FilterCubit>(context)
                                    .changeFilter(_filter);
                              }
                            },
                          );
                        },
                      ),
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
}

class FilterThumbnail extends StatelessWidget {
  const FilterThumbnail({
    Key? key,
    required this.imagePath,
    required this.filter,
  }) : super(key: key);

  final String imagePath;
  final Filter filter;

  @override
  Widget build(BuildContext context) {
    String filterName = filter.name + basename(imagePath);
    return BlocConsumer<FilterCubit, FilterState>(
      listener: (context, state) {},
      buildWhen: (previous, current) {
        return previous.cachedFilters[filterName] !=
            current.cachedFilters[filterName];
      },
      builder: (context, filterState) {
        return (filterState.cachedFilters[filterName] == null)
            ? FutureBuilder<List<int>>(
                future: compute(applyFilter, <String, dynamic>{
                  "filter": filter,
                  "image": File(imagePath),
                  "filename": basename(imagePath),
                }),
                builder:
                    (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
                  print('$filterName => ${snapshot.connectionState}');

                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.active:
                    case ConnectionState.waiting:
                      BlocProvider.of<FilterCubit>(context)
                          .cacheImage(filterName, null);

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
                      if (snapshot.hasError && !snapshot.hasData)
                        return Center(child: Text('Error: ${snapshot.error}'));

                      BlocProvider.of<FilterCubit>(context)
                          .cacheImage(filterName, snapshot.data!);

                      return Container(
                        height: 60,
                        width: 60,
                        child: Image.memory(
                          snapshot.data as dynamic,
                        ),
                      );
                  }
                },
              )
            : Container(
                height: 60,
                width: 60,
                child: Image.memory(
                  Uint8List.fromList(filterState.cachedFilters[filterName]!),
                ),
              );
      },
    );
  }
}

late imageLib.Image byteImage;
List<int>? _imageBytes;

///The global applyfilter function
Future<List<int>> applyFilter(Map<String, dynamic> params) async {
  Filter? filter = params["filter"];
  File image = params["image"];
  String filename = params["filename"];

  if (_imageBytes == null) {
    byteImage = imageLib.decodeImage(await image.readAsBytes())!;
    _imageBytes = byteImage.getBytes();
  }

  if (filter != null && filter.name != 'Original') {
    filter.apply(_imageBytes as dynamic, byteImage.width, byteImage.height);
  }

  // imageLib.Image _image =
  //     imageLib.Image.fromBytes(imageBytes.width, imageBytes.height, _bytes);

  _imageBytes = imageLib.encodeNamedImage(byteImage, filename)!;

  // PreviewScreen.previewModel.cachedFilters[
  //     filter?.name == null ? '_' + filename : filter!.name + filename] = _bytes;

  print(
      'Caching image: ${filter?.name == null ? '_' + filename : filter!.name + filename}');

  return _imageBytes!;
}
