import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_scanner_cropper/flutter_scanner_cropper.dart';
import 'package:open_file/open_file.dart';
import 'package:openscan/Utilities/Classes.dart';
import 'package:openscan/Utilities/DatabaseHelper.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/Utilities/file_operations.dart';
import 'package:openscan/Widgets/Image_Card.dart';
import 'package:openscan/screens/home_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:share_extend/share_extend.dart';

class ViewDocument extends StatefulWidget {
  static String route = "ViewDocument";
  final DirectoryOS directoryOS;
  final bool quickScan;

  ViewDocument({this.quickScan = false, this.directoryOS});

  @override
  _ViewDocumentState createState() => _ViewDocumentState();
}

class _ViewDocumentState extends State<ViewDocument> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DatabaseHelper database = DatabaseHelper();
  List<String> imageFilesPath = [];
  List<Widget> imageCards = [];
  String imageFilePath;

  FileOperations fileOperations;
  String dirPath;
  String fileName;
  bool _statusSuccess;
  List<Map<String, dynamic>> directoryData;
  List<ImageOS> directoryImages = [];

  void imageEditCallback({ImageOS imageOS}) {
    bool isFirstImage = false;
    if (imageOS.imgPath == widget.directoryOS.firstImgPath) {
      isFirstImage = true;
    }
    getDirectoryData(
      updateFirstImage: isFirstImage,
      updateIndex: true,
    );
  }

  Future<void> displayDialog(BuildContext context) async {
    String displayText;
    (_statusSuccess)
        ? displayText = "Success. File stored in the OpenScan folder."
        : displayText = "Failed to generate pdf. Try Again.";
    Scaffold.of(context).showSnackBar(
      SnackBar(content: Text(displayText)),
    );
  }

  Future<void> createDirectoryPath() async {
    Directory appDir = await getExternalStorageDirectory();
    dirPath = "${appDir.path}/OpenScan ${DateTime.now()}";
    fileName = dirPath.substring(dirPath.lastIndexOf("/") + 1);
    widget.directoryOS.dirName = fileName;
  }

  Future<dynamic> createImage() async {
    File image = await fileOperations.openCamera();
    Directory cacheDir = await getTemporaryDirectory();
    if (image != null) {
      if (!widget.quickScan) {
        imageFilePath = await FlutterScannerCropper.openCrop({
          'src': image.path,
          'dest': cacheDir.path,
        });
      }
      File imageFile = File(imageFilePath ?? image.path);
      setState(() {});
      await fileOperations.saveImage(
        image: imageFile,
        index: directoryImages.length + 1,
        dirPath: dirPath,
      );
      await fileOperations.deleteTemporaryFiles();
      if (widget.quickScan) createImage();
      getDirectoryData();
    }
  }

  getImageCards() {
    imageCards = [];
    for (var image in directoryImages) {
      ImageCard imageCard = ImageCard(
        imageOS: image,
        directoryOS: widget.directoryOS,
        imageFileEditCallback: () {
          imageEditCallback(imageOS: image);
        },
      );
      if (!imageCards.contains(imageCard)) {
        imageCards.add(imageCard);
      }
    }
    return imageCards;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      Widget row = imageCards.removeAt(oldIndex);
      imageCards.insert(newIndex, row);
    });
  }

  void getDirectoryData({
    bool updateFirstImage = false,
    bool updateIndex = false,
  }) async {
    directoryImages = [];
    imageFilesPath = [];
    int index = 1;
    directoryData = await database.getDirectoryData(widget.directoryOS.dirName);
    print('Directory table[$widget.directoryOS.dirName] => $directoryData');
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

      directoryImages.add(
        ImageOS(
          idx: i,
          imgPath: image['img_path'],
        ),
      );
      imageFilesPath.add(image['img_path']);

      index += 1;
    }
    setState(() {});
  }

  void handleClick(String value) {
    switch (value) {
      case 'Reorder':
        break;
      case 'Select':
        break;
      case 'Share':
        showModalBottomSheet(
          context: context,
          builder: _buildBottomSheet,
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    fileOperations = FileOperations();
    if (widget.directoryOS.dirPath != null) {
      dirPath = widget.directoryOS.dirPath;
      fileName = widget.directoryOS.newName ?? widget.directoryOS.dirName;
      getDirectoryData();
    } else {
      createDirectoryPath();
      createImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: primaryColor,
        key: scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
          title: RichText(
            text: TextSpan(
              text: 'View ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              children: [
                TextSpan(
                  text: 'Document',
                  style: TextStyle(color: secondaryColor),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: () async {
                _statusSuccess = await fileOperations.saveToAppDirectory(
                  context: context,
                  fileName: fileName,
                  images: directoryImages,
                );
                Directory storedDirectory =
                    await getApplicationDocumentsDirectory();
                //TODO: Doubt! Is this line needed??
                // File('${storedDirectory.path}/$fileName.pdf').deleteSync();
                final result = await OpenFile.open(
                    '${storedDirectory.path}/$fileName.pdf');

                setState(() {
                  String _openResult =
                      "type=${result.type}  message=${result.message}";
                  print(_openResult);
                });
              },
            ),
            PopupMenuButton<String>(
              onSelected: handleClick,
              color: primaryColor.withOpacity(0.95),
              elevation: 30,
              offset: Offset.fromDirection(20, 20),
              icon: Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) {
                return {'Share', 'Reorder', 'Select'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
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
                    //TODO: Check
                    spacing: 10,
                    runSpacing: 10,
                    minMainAxisCount: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: getImageCards(),
                    onReorder: _onReorder,
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
        // TODO: Add photos from gallery
        floatingActionButton: FloatingActionButton(
          backgroundColor: secondaryColor,
          onPressed: createImage,
          child: Icon(
            Icons.camera_alt,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    FileOperations fileOperations = FileOperations();
    Size size = MediaQuery.of(context).size;
    return Container(
      color: primaryColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(15, 20, 15, 15),
            child: Text(
              fileName,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Divider(
            thickness: 0.2,
            indent: 8,
            endIndent: 8,
            color: Colors.white,
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Share PDF'),
            onTap: () async {
              Navigator.pop(context);
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      title: Text('Share PDF'),
                      content: TextField(
                        onChanged: (value) {
                          fileName = '$value OpenScan';
                        },
                        controller: TextEditingController(
                          text: fileName.substring(8, fileName.length),
                        ),
                        cursorColor: secondaryColor,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          prefixStyle: TextStyle(color: Colors.white),
                          suffixText: ' OpenScan.pdf',
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: secondaryColor)),
                        ),
                      ),
                      actions: <Widget>[
                        FlatButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        FlatButton(
                          onPressed: () async {
                            _statusSuccess =
                                await fileOperations.saveToAppDirectory(
                              context: context,
                              fileName: fileName,
                              images: directoryImages,
                            );
                            Directory storedDirectory =
                                await getApplicationDocumentsDirectory();
                            ShareExtend.share(
                                '${storedDirectory.path}/$fileName.pdf',
                                'file');
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Share',
                          ),
                        ),
                      ],
                    );
                  });
            },
          ),
          ListTile(
            leading: Icon(Icons.phone_android),
            title: Text('Save to device'),
            onTap: () async {
              String savedDirectory;
              Navigator.pop(context);
              savedDirectory = await fileOperations.saveToDevice(
                context: context,
                fileName: fileName,
                images: directoryImages,
              );
              String displayText;
              (savedDirectory != null)
                  ? displayText = "Saved at $savedDirectory"
                  : displayText = "Failed to generate pdf. Try Again.";
              scaffoldKey.currentState.showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  backgroundColor: primaryColor,
                  duration: Duration(seconds: 1),
                  content: Container(
                    decoration: BoxDecoration(),
                    alignment: Alignment.center,
                    height: 20,
                    width: size.width * 0.3,
                    child: Text(
                      displayText,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.image),
            title: Text('Share images'),
            onTap: () {
              ShareExtend.shareMultiple(imageFilesPath, 'file');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete,
              color: Colors.redAccent,
            ),
            title: Text(
              'Delete All',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    title: Text('Delete'),
                    content: Text('Do you really want to delete this file?'),
                    actions: <Widget>[
                      FlatButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      FlatButton(
                        onPressed: () {
                          Directory(dirPath).deleteSync(recursive: true);
                          DatabaseHelper()..deleteDirectory(dirPath: dirPath);
                          Navigator.popUntil(
                            context,
                            ModalRoute.withName(HomeScreen.route),
                          );
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
