import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:openscan/Utilities/classes.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/Utilities/database_helper.dart';
import 'package:openscan/Utilities/file_operations.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/presentation/Widgets/deleteDialog.dart';
import 'package:openscan/presentation/Widgets/viewDocument/customBottomSheet.dart';
import 'package:openscan/presentation/Widgets/viewDocument/popupMenuButton.dart';
import 'package:openscan/presentation/Widgets/FAB.dart';
import 'package:openscan/presentation/Widgets/viewDocument/Image_Card.dart';
import 'package:openscan/presentation/Widgets/viewDocument/qualitySelector.dart';
import 'package:openscan/presentation/screens/crop_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:share_extend/share_extend.dart';

bool enableSelect = false;
bool enableReorder = false;
List<bool> selectedImageIndex = [];

class ViewDocument extends StatefulWidget {
  static String route = "ViewDocument";
  final DirectoryOS directoryOS;
  final bool quickScan;
  final bool fromGallery;

  ViewDocument({
    this.quickScan = false,
    this.directoryOS,
    this.fromGallery = false,
  });

  @override
  _ViewDocumentState createState() => _ViewDocumentState();
}

/// Parameters: @required directoryOS, [imageOS]
/// Methods:
///   ImageOS => addImage, deleteImage, updateImagePath, updateImageIndex, revertReorder
///   DirectoryOS => updateFirstImagePath, updateImageCount, deleteDirectory

class _ViewDocumentState extends State<ViewDocument>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  TransformationController _controller = TransformationController();
  DatabaseHelper database = DatabaseHelper();
  List<String> imageFilesPath = [];
  List<Widget> imageCards = [];
  String imageFilePath;
  FileOperations fileOperations = FileOperations();
  String dirPath;
  String fileName = '';
  List<Map<String, dynamic>> directoryData;
  List<ImageOS> directoryImages = [];
  List<ImageOS> initDirectoryImages = [];
  bool enableSelectionIcons = false;
  bool resetReorder = false;
  ImageOS displayImage;
  int imageQuality = 3;
  TapDownDetails _doubleTapDetails;
  File croppedImage;
  bool showImage = false;

  void getDirectoryData({
    bool updateFirstImage = false,
    bool updateIndex = false,
  }) async {
    directoryImages = [];
    initDirectoryImages = [];
    imageFilesPath = [];
    selectedImageIndex = [];
    int index = 1;

    BlocListener<DirectoryCubit, DirectoryState>(
        listener: (context, state) async {
      print('hello');
      directoryData = await database.getDirectoryData(state.dirName);
      print('Directory table[${widget.directoryOS.dirName}] => $directoryData');
    });

    directoryData = await database.getDirectoryData(widget.directoryOS.dirName);
    // print('Directory table[${widget.directoryOS.dirName}] => $directoryData');
    for (var image in directoryData) {
      // Updating first image path after delete
      if (updateFirstImage) {
        database.updateFirstImagePath(
            imagePath: image['img_path'], dirPath: widget.directoryOS.dirPath);
        updateFirstImage = false;
      }
      var i = image['idx'];

      // Updating index of images after delete
      if (updateIndex) {
        i = index;
        database.updateImageIndex(
          image: ImageOS(
            idx: i,
            imgPath: image['img_path'],
          ),
          tableName: widget.directoryOS.dirName,
        );
      }

      ImageOS tempImageOS = ImageOS(
        idx: i,
        imgPath: image['img_path'],
      );
      directoryImages.add(
        tempImageOS,
      );
      initDirectoryImages.add(
        tempImageOS,
      );

      imageCards.add(
        ImageCard(
          imageOS: tempImageOS,
          directoryOS: widget.directoryOS,
          fileEditCallback: () {
            fileEditCallback(imageOS: tempImageOS);
          },
          selectCallback: () {
            selectionCallback(imageOS: tempImageOS);
          },
          imageViewerCallback: () {
            imageViewerCallback(imageOS: tempImageOS);
          },
        ),
      );

      imageFilesPath.add(image['img_path']);
      selectedImageIndex.add(false);
      index += 1;
    }
    setState(() {});
  }

  Future<void> createDirectoryPath() async {
    Directory appDir = await getExternalStorageDirectory();
    dirPath = "${appDir.path}/OpenScan ${DateTime.now()}";
    fileName = dirPath.substring(dirPath.lastIndexOf("/") + 1);
    widget.directoryOS.dirPath = dirPath;
    widget.directoryOS.dirName = fileName;
    // print('New Directory => ${widget.directoryOS.dirName}');
  }

  Future<dynamic> createImage({
    bool quickScan,
    bool fromGallery = false,
  }) async {
    File image;
    List<File> galleryImages;
    if (fromGallery) {
      galleryImages = await fileOperations.openGallery();
    } else {
      image = await fileOperations.openCamera();
    }
    Directory cacheDir = await getTemporaryDirectory();
    if (image != null || galleryImages != null) {
      if (!quickScan && !fromGallery) {
        // imageFilePath = await FlutterScannerCropper.openCrop(
        //   src: image.path,
        //   dest: cacheDir.path,
        // );
        // File imageFileTemp;
        // imageFileTemp = File(
        //   "${cacheDir.path}/Pictures/${DateTime.now()}.jpg",
        // );
        // image.copySync(imageFileTemp.path);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropImage(
              file: image,
            ),
          ),
        ).then((value) => croppedImage = value);
        // imageFilePath = image.path;
      }

      if (fromGallery) {
        for (File galleryImage in galleryImages) {
          if (galleryImage.existsSync()) {
            await fileOperations.saveImage(
              image: galleryImage,
              index: directoryImages.length + 1,
              dirPath: dirPath,
            );
          }
          directoryImages.length++;
        }
        setState(() {});
      } else {
        File imageFile = File(croppedImage.path ?? image.path);
        await fileOperations.saveImage(
          image: imageFile,
          index: directoryImages.length + 1,
          dirPath: dirPath,
        );

        await fileOperations.deleteTemporaryFiles();
        if (quickScan) {
          getDirectoryData();
          return createImage(quickScan: quickScan);
        }
        setState(() {});
        imageFilePath = null;
      }
      getDirectoryData();
    }
  }

  selectionCallback({ImageOS imageOS}) {
    if (selectedImageIndex.contains(true)) {
      setState(() {
        enableSelectionIcons = true;
      });
    } else {
      setState(() {
        enableSelectionIcons = false;
      });
    }
  }

  void fileEditCallback({ImageOS imageOS}) {
    bool isFirstImage = false;
    if (imageOS.imgPath == widget.directoryOS.firstImgPath) {
      isFirstImage = true;
    }
    getDirectoryData(
      updateFirstImage: isFirstImage,
      updateIndex: true,
    );
  }

  imageViewerCallback({ImageOS imageOS}) {
    setState(() {
      displayImage = imageOS;
      showImage = true;
    });
  }

  void handleClick(String value) {
    switch (value) {
      case 'Reorder':
        setState(() {
          enableReorder = true;
        });
        break;
      case 'Select':
        setState(() {
          enableSelect = true;
        });
        break;
      case 'Export':
        showModalBottomSheet(
          context: context,
          builder: _buildBottomSheet,
        );
        break;
    }
  }

  removeSelection() {
    setState(() {
      selectedImageIndex = selectedImageIndex.map((e) => false).toList();
      enableSelect = false;
    });
  }

  deleteMultipleImages() {
    bool isFirstImage = false;
    for (var i = 0; i < directoryImages.length; i++) {
      if (selectedImageIndex[i]) {
        // print('${directoryImages[i].idx}: ${directoryImages[i].imgPath}');
        if (directoryImages[i].imgPath == widget.directoryOS.firstImgPath) {
          isFirstImage = true;
        }

        File(directoryImages[i].imgPath).deleteSync();
        database.deleteImage(
          imgPath: directoryImages[i].imgPath,
          tableName: widget.directoryOS.dirName,
        );
      }
    }
    database.updateImageCount(
      tableName: widget.directoryOS.dirName,
    );
    try {
      Directory(widget.directoryOS.dirPath).deleteSync(recursive: false);
      database.deleteDirectory(dirPath: widget.directoryOS.dirPath);
    } catch (e) {
      getDirectoryData(
        updateFirstImage: isFirstImage,
        updateIndex: true,
      );
    }
    removeSelection();
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    if (widget.directoryOS.dirPath != null) {
      dirPath = widget.directoryOS.dirPath;
      fileName = widget.directoryOS.newName;
      getDirectoryData();
    } else {
      createDirectoryPath();
      if (widget.fromGallery) {
        createImage(
          quickScan: false,
          fromGallery: true,
        );
      } else {
        createImage(quickScan: widget.quickScan);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // print('hellllo');

    // BlocConsumer<DirectoryCubit, DirectoryState>(
    //   listener: (context, state) async {
    //     print('hello');
    //     directoryData = await database.getDirectoryData(state.dirName);
    //     print(
    //         'Directory table[${widget.directoryOS.dirName}] => $directoryData');
    //   },
    //   builder: (context, state) {
    //     return Container();
    //   },
    // );

    return SafeArea(
      child: WillPopScope(
        onWillPop: () {
          if (enableSelect || enableReorder || showImage) {
            setState(() {
              enableSelect = false;
              removeSelection();
              enableReorder = false;
              showImage = false;
            });
          } else {
            Navigator.pop(context);
          }
          return;
        },
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: primaryColor,
              key: scaffoldKey,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: primaryColor,
                leading: (enableSelect || enableReorder)
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 30,
                        ),
                        onPressed: (enableSelect)
                            ? () {
                                removeSelection();
                              }
                            : () {
                                setState(() {
                                  // Reverting reorder
                                  directoryImages = [];
                                  for (var image in initDirectoryImages) {
                                    directoryImages.add(image);
                                  }
                                  enableReorder = false;
                                });
                              },
                      )
                    : IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                title: Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                actions: (enableReorder)
                    ? [
                        GestureDetector(
                          onTap: () {
                            for (var i = 1; i <= directoryImages.length; i++) {
                              directoryImages[i - 1].idx = i;
                              if (i == 1) {
                                database.updateFirstImagePath(
                                  dirPath: widget.directoryOS.dirPath,
                                  imagePath: directoryImages[i - 1].imgPath,
                                );
                                widget.directoryOS.firstImgPath =
                                    directoryImages[i - 1].imgPath;
                              }
                              database.updateImagePath(
                                image: directoryImages[i - 1],
                                tableName: widget.directoryOS.dirName,
                              );
                              // print('$i: ${directoryImages[i - 1].imgPath}');
                            }
                            setState(() {
                              enableReorder = false;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.only(right: 25),
                            alignment: Alignment.center,
                            child: Text(
                              'Done',
                              style: TextStyle(color: secondaryColor),
                            ),
                          ),
                        ),
                      ]
                    : [
                        (enableSelect)
                            ? IconButton(
                                icon: Icon(
                                  Icons.share,
                                  color: (enableSelectionIcons)
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                                onPressed: (enableSelectionIcons)
                                    ? () {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: _buildBottomSheet,
                                        );
                                      }
                                    : () {},
                              )
                            : IconButton(
                                icon: Icon(Icons.picture_as_pdf),
                                onPressed: () async {
                                  await fileOperations.saveToAppDirectory(
                                    context: context,
                                    fileName: fileName,
                                    images: directoryImages,
                                  );
                                  Directory storedDirectory =
                                      await getApplicationDocumentsDirectory();
                                  final result = await OpenFile.open(
                                      '${storedDirectory.path}/$fileName.pdf');
                                  setState(() {
                                    String _openResult =
                                        "type=${result.type}  message=${result.message}";
                                    // print(_openResult);
                                  });
                                },
                              ),
                        (enableSelect)
                            ? IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: (enableSelectionIcons)
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                onPressed: (enableSelectionIcons)
                                    ? () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return DeleteDialog(
                                              deleteOnPressed:
                                                  deleteMultipleImages,
                                              cancelOnPressed: () =>
                                                  Navigator.pop(context),
                                            );
                                          },
                                        );
                                      }
                                    : () {},
                              )
                            : CustomPopupMenuButton(
                                onSelected: handleClick,
                                itemList: ['Select', 'Reorder', 'Export'],
                              ),
                      ],
              ),
              body: RefreshIndicator(
                backgroundColor: primaryColor,
                color: secondaryColor,
                onRefresh: () async {
                  getDirectoryData();
                },
                child: Padding(
                  padding: EdgeInsets.all(size.width * 0.01),
                  child: Theme(
                    data: Theme.of(context).copyWith(accentColor: primaryColor),
                    child: ListView(
                      children: [
                        ReorderableWrap(
                          spacing: 10,
                          runSpacing: 10,
                          minMainAxisCount: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: directoryImages.map((image) {
                            return ImageCard(
                              imageOS: image,
                              directoryOS: widget.directoryOS,
                              fileEditCallback: () {
                                fileEditCallback(imageOS: image);
                              },
                              selectCallback: () {
                                selectionCallback(imageOS: image);
                              },
                              imageViewerCallback: () {
                                imageViewerCallback(imageOS: image);
                              },
                            );
                          }).toList(),
                          onReorder: (int oldIndex, int newIndex) {
                            Widget image = imageCards.removeAt(oldIndex);
                            imageCards.insert(newIndex, image);
                            ImageOS image1 = directoryImages.removeAt(oldIndex);
                            directoryImages.insert(newIndex, image1);
                            setState(() {});
                          },
                          onNoReorder: (int index) {
                            debugPrint(
                                '${DateTime.now().toString().substring(5, 22)} reorder cancelled. index:$index');
                          },
                          onReorderStarted: (int index) {
                            debugPrint(
                                '${DateTime.now().toString().substring(5, 22)} reorder started: index:$index');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              floatingActionButton: FAB(
                normalScanOnPressed: () {
                  createImage(quickScan: false);
                },
                quickScanOnPressed: () {
                  createImage(quickScan: true);
                },
                galleryOnPressed: () {
                  createImage(quickScan: false, fromGallery: true);
                },
              ),
            ),
            (showImage)
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        showImage = false;
                      });
                    },
                    child: Container(
                      width: size.width,
                      height: size.height,
                      padding: EdgeInsets.all(20),
                      color: primaryColor.withOpacity(0.8),
                      child: GestureDetector(
                        onDoubleTapDown: (details) {
                          _doubleTapDetails = details;
                        },
                        onDoubleTap: () {
                          if (_controller.value != Matrix4.identity()) {
                            _controller.value = Matrix4.identity();
                          } else {
                            final position = _doubleTapDetails.localPosition;
                            _controller.value = Matrix4.identity()
                              ..translate(-position.dx, -position.dy)
                              ..scale(2.0);
                          }
                        },
                        child: InteractiveViewer(
                          transformationController: _controller,
                          maxScale: 10,
                          child: GestureDetector(
                            child: Image.file(
                              File(displayImage.imgPath),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    FileOperations fileOperations = FileOperations();
    String selectedFileName;

    updateSelectedFileName() {
      int selectedCount = 0;
      for (bool i in selectedImageIndex) {
        selectedCount += (i) ? 1 : 0;
      }
      selectedFileName = fileName + ' $selectedCount';
    }

    return CustomBottomSheet(
      fileName: fileName,
      qualitySelection: () {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) {
            return QualitySelector(
              imageQuality: imageQuality,
              qualitySelected: (quality) {
                imageQuality = quality;
                print('Selected Image Quality: $imageQuality');
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  builder: _buildBottomSheet,
                );
              },
            );
          },
        );
      },
      sharePdf: () async {
        if (enableSelect) {
          updateSelectedFileName();
        }
        List<ImageOS> selectedImages = [];
        for (var image in directoryImages) {
          if (selectedImageIndex.elementAt(image.idx - 1)) {
            selectedImages.add(image);
          }
        }
        await fileOperations.saveToAppDirectory(
          context: context,
          fileName: (enableSelect) ? selectedFileName : fileName,
          images: (enableSelect) ? selectedImages : directoryImages,
        );
        Directory storedDirectory = await getApplicationDocumentsDirectory();
        ShareExtend.share(
            '${storedDirectory.path}/${(enableSelect) ? selectedFileName : fileName}.pdf',
            'file');
        Navigator.pop(context);
      },
      saveToDevice: () async {
        if (enableSelect) {
          updateSelectedFileName();
        }
        List<ImageOS> selectedImages = [];
        for (var image in directoryImages) {
          if (selectedImageIndex.elementAt(image.idx - 1)) {
            selectedImages.add(image);
          }
        }
        String savedDirectory;
        savedDirectory = await fileOperations.saveToDevice(
          context: context,
          fileName: (enableSelect) ? selectedFileName : fileName,
          images: (enableSelect) ? selectedImages : directoryImages,
          quality: imageQuality,
        );
        Navigator.pop(context);
        String displayText;
        (savedDirectory != null)
            ? displayText = "PDF Saved at\n$savedDirectory"
            : displayText = "Failed to generate pdf. Try Again.";

        Fluttertoast.showToast(msg: displayText);
      },
      shareImages: () {
        List<String> selectedImagesPath = [];
        for (var image in directoryImages) {
          if (selectedImageIndex.elementAt(image.idx - 1)) {
            selectedImagesPath.add(image.imgPath);
          }
        }
        ShareExtend.shareMultiple(
            (enableSelect) ? selectedImagesPath : imageFilesPath, 'file');
        Navigator.pop(context);
      },
    );
  }
}
