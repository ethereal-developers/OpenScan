import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openscan/Utilities/cropper.dart';

import 'package:path_provider/path_provider.dart';
import 'package:directory_picker/directory_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:openscan/Utilities/Image_Card.dart';
import 'package:openscan/Utilities/constants.dart';

import 'package:openscan/screens/share_document.dart';

class ViewDocument extends StatefulWidget {
  static String route = "ViewDocument";

  ViewDocument({this.dirPath});

  final String dirPath;

  @override
  _ViewDocumentState createState() => _ViewDocumentState();
}

class _ViewDocumentState extends State<ViewDocument> {
  List<FileSystemEntity> imageFiles;

  String dirName;
  Directory selectedDirectory;

  List<File> images = [];
  String fileName;

  bool _statusSuccess;

  void imageEditCallback() {
    _getImages();
  }

  void _getImages() {
    setState(() {
      imageFiles =
          Directory(dirName).listSync(recursive: false, followLinks: false);
      images = [];
      Directory(dirName)
          .list(recursive: false, followLinks: false)
          .listen((FileSystemEntity entity) {
        images.add(File(entity.path));
      });
    });
  }

  @override
  void initState() {
    super.initState();
    dirName = widget.dirPath;
    _getImages();
    fileName =
        dirName.substring(dirName.lastIndexOf("/") + 1, dirName.length - 1);
  }

  // CREATE PDF
  Future<void> _createPdf() async {
    try {
      final output = File("${selectedDirectory.path}/$fileName.pdf");
      print(output);
      print(images);

      int i = 0;

      final doc = pw.Document();

      for (i = 0; i < images.length; i++) {
        final image = PdfImage.file(
          doc.document,
          bytes: images[i].readAsBytesSync(),
        );

        doc.addPage(pw.Page(build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image),
          ); // Center
        }));
      }

      output.writeAsBytesSync(doc.save());
      _statusSuccess = true;
    } catch (e) {
      _statusSuccess = false;
    }
  }

  Future<void> displayDialog() async {
    String displayText;

    if (_statusSuccess)
      displayText = "Success. File stored in the OpenScan folder.";
    else
      displayText = "Failed to generate pdf. Try Again.";

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('$displayText'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ADD IMAGES
  Future<File> _openCamera() async {
    File image;
    final _picker = ImagePicker();
    var picture = await _picker.getImage(source: ImageSource.camera);
    if (picture != null) {
      final requiredPicture = File(picture.path);
      image = requiredPicture;
    }
    return image;
  }

  Future _createImage() async {
    File image = await _openCamera();
    if (image != null) {
      Cropper cropper = Cropper();
      var imageFile = await cropper.cropImage(image);
      if (imageFile != null)
        setState(() {
          imageFiles.add(imageFile);
        });
    }
  }

  Future<void> _saveImage(File image, int i) async {
    if (await Directory(dirName).exists() != true) {
      new Directory(dirName).create();
    }

    File tempPic = File("$dirName/$i.jpg");
    image.copy(tempPic.path);
  }

  // SAVE TO DEVICE
  Future<void> _pickDirectory(BuildContext context) async {
    Directory directory = selectedDirectory;
    if (Platform.isAndroid) {
      directory = Directory("/storage/emulated/0/");
    } else {
      directory = await getExternalStorageDirectory();
    }

    Directory newDirectory = await DirectoryPicker.pick(
        allowFolderCreation: true,
        context: context,
        rootDirectory: directory,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))));

    setState(() {
      selectedDirectory = newDirectory;
    });
  }

  void _saveToDevice() async {
    Directory openscanDir = Directory("/storage/emulated/0/OpenScan");
    if (Platform.isAndroid) {
      if (!openscanDir.existsSync()) {
        openscanDir.createSync();
      }
      selectedDirectory = openscanDir;
    } else {
      await _pickDirectory(context);
    }
    await _createPdf();
    displayDialog();
  }

  // RENAME FOLDER
  void _renameFolder(String newName) {
    String name = "OpenScan $newName";
    // TODO: DOES NOT RENAME BECAUSE FILES ARE PRESENT
    Directory temp = Directory(dirName).renameSync(name);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: primaryColor,
          // TODO: add bottom sheet...
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
                    builder: (context) => ShareDocument(
                      dirName: dirName,
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
            _getImages();
          },
          child: ListView.builder(
            itemCount: ((imageFiles.length) / 2).round(),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ImageCard(
                      imageFile: File(imageFiles[index * 2].path),
                      imageFileEditCallback: imageEditCallback,
                    ),
                    if (index * 2 + 1 < imageFiles.length)
                      ImageCard(
                        imageFile: File(imageFiles[index * 2 + 1].path),
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
    Size size = MediaQuery.of(context).size;
    String folderName =
        dirName.substring(dirName.lastIndexOf('/') + 1, dirName.length - 1);
    return Container(
      height: size.height * 0.45,
      color: primaryColor,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  folderName,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                GestureDetector(
                  child: Icon(Icons.edit),
                  onTap: () {
                    // TODO: Rename folder
                    _renameFolder("Something 123");
                  },
                ),
              ],
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
              await _createImage();
              await _saveImage(imageFiles.last, imageFiles.length);
            },
          ),
          ListTile(
            leading: Icon(Icons.phone_android),
            title: Text('Save to device'),
            onTap: () {
              _saveToDevice();
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Share as PDF'),
            onTap: () {
              // TODO: Share
            },
          ),
          ListTile(
            leading: Icon(Icons.image),
            title: Text('Share as image'),
            onTap: () {
              //TODO: Share
            },
          ),
        ],
      ),
    );
  }
}
