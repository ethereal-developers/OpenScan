import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openscan/Utilities/Image_Card.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/Utilities/cropper.dart';
import 'package:openscan/Utilities/file_operations.dart';
import 'package:openscan/screens/home_screen.dart';
import 'package:openscan/screens/pdf_screen.dart';
import 'package:openscan/screens/share_document.dart';
import 'package:share_extend/share_extend.dart';

class ViewDocument extends StatefulWidget {
  static String route = "ViewDocument";

  ViewDocument({this.dirPath});

  final String dirPath;

  @override
  _ViewDocumentState createState() => _ViewDocumentState();
}

class _ViewDocumentState extends State<ViewDocument> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> imageFilesWithDate = [];
  List<String> imageFilesPath = [];

  FileOperations fileOperations;

  String dirName;
  Directory selectedDirectory;

  String fileName;

  bool _statusSuccess;

  void getImages() {
    imageFilesPath = [];
    imageFilesWithDate = [];

    Directory(dirName)
        .list(recursive: false, followLinks: false)
        .listen((FileSystemEntity entity) {
      List<String> temp = entity.path.split(" ");
      imageFilesWithDate.add({
        "file": entity,
        "creationDate": DateTime.parse("${temp[3]} ${temp[4]}")
      });

      setState(() {
        imageFilesWithDate
            .sort((a, b) => a["creationDate"].compareTo(b["creationDate"]));

        for (var image in imageFilesWithDate) {
          imageFilesPath.add(image["path"]);
        }
      });
    });
  }

  void imageEditCallback() {
    getImages();
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

  @override
  void initState() {
    super.initState();
    fileOperations = FileOperations();
    dirName = widget.dirPath;
    getImages();
    fileName =
        dirName.substring(dirName.lastIndexOf("/") + 1, dirName.length - 1);
  }

  Future<dynamic> createImage() async {
    File image = await fileOperations.openCamera();
    if (image != null) {
      Cropper cropper = Cropper();
      var imageFile = await cropper.cropImage(image);
      if (imageFile != null) return imageFile;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              //TODO : Reload home
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PDFScreen(
                      path: dirName,
                    ),
                  ),
                );
              },
            ),
            Builder(builder: (context) {
              return IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {
                  showModalBottomSheet(
                      context: context, builder: _buildBottomSheet);
                },
              );
            }),
          ],
        ),
        body: RefreshIndicator(
          backgroundColor: primaryColor,
          color: secondaryColor,
          onRefresh: () async {
            getImages();
          },
          child: ListView.builder(
            itemCount: ((imageFilesWithDate.length) / 2).round(),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ImageCard(
                      imageFile:
                          File(imageFilesWithDate[index * 2]["file"].path),
                      imageFileEditCallback: imageEditCallback,
                    ),
                    if (index * 2 + 1 < imageFilesWithDate.length)
                      ImageCard(
                        imageFile: File(
                            imageFilesWithDate[index * 2 + 1]["file"].path),
                        imageFileEditCallback: imageEditCallback,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    FileOperations fileOperations = FileOperations();
    Size size = MediaQuery.of(context).size;
    String folderName =
        dirName.substring(dirName.lastIndexOf('/') + 1, dirName.length - 1);
    return Container(
      color: primaryColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(15, 20, 15, 15),
            child: Text(
              folderName,
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
            leading: Icon(Icons.add_a_photo),
            title: Text('Add Image'),
            onTap: () async {
              Navigator.pop(context);
              var image = await createImage();
              setState(() {});
              await fileOperations.saveImage(
                image: image,
                i: imageFilesWithDate.length,
                dirName: dirName,
              );
              getImages();
            },
          ),
          ListTile(
            leading: Icon(Icons.phone_android),
            title: Text('Save to device'),
            onTap: () async {
              Navigator.pop(context);
              showDialog(context: context,builder: (context){
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  title: Text('Save as PDF'),
                  content:TextField(
                    onChanged: (value){
                      fileName = '$value OpenScan';
                    },
                    controller: TextEditingController(text: fileName.substring(8,fileName.length)),
                    cursorColor: secondaryColor,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      prefixStyle: TextStyle(color: Colors.white),
                      suffixText: ' OpenScan.pdf',
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: secondaryColor)),
                    ),
                  ),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    FlatButton(
                      onPressed: () async {
                        _statusSuccess = await fileOperations.saveToDevice(
                          context: context,
                          selectedDirectory: selectedDirectory,
                          fileName: fileName,
                          images: imageFilesWithDate,
                        );
                        String displayText;
                        (_statusSuccess)
                            ? displayText = "Saved at /storage/emulated/0/OpenScan/PDF/"
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
                              height: 15,
                              width: size.width * 0.3,
                              child: Text(
                                displayText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Save',
                      ),
                    ),
                  ],
                );
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Share as PDF'),
            onTap: () async {
              Navigator.pop(context);
              showDialog(context: context,builder: (context){
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  title: Text('Share as PDF'),
                  content:TextField(
                    onChanged: (value){
                      fileName = '$value OpenScan';
                    },
                    controller: TextEditingController(text: fileName.substring(8,fileName.length)),
                    cursorColor: secondaryColor,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      prefixStyle: TextStyle(color: Colors.white),
                      suffixText: ' OpenScan.pdf',
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: secondaryColor)),
                    ),
                  ),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    FlatButton(
                      onPressed: () async {
                        _statusSuccess = await fileOperations.saveToDevice(
                          context: context,
                          selectedDirectory: selectedDirectory,
                          fileName: fileName,
                          images: imageFilesWithDate,
                        );
                        ShareExtend.share(
                            '/storage/emulated/0/OpenScan/PDF/$fileName.pdf', 'file');
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
            leading: Icon(Icons.image),
            title: Text('Share as image'),
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
              'Delete',
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
                    content: Text('Do you really want to delete file?'),
                    actions: <Widget>[
                      FlatButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      FlatButton(
                        onPressed: () {
                          Directory(dirName).deleteSync(recursive: true);
                          Navigator.popUntil(
                              context, ModalRoute.withName(HomeScreen.route));
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
              Directory(dirName).deleteSync(recursive: true);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
