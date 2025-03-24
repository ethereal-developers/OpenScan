import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openscan/core/appRouter.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/FAB.dart';
import 'package:openscan/view/Widgets/delete_dialog.dart';
import 'package:openscan/view/Widgets/drawer.dart';
import 'package:openscan/view/screens/view_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DatabaseHelper database = DatabaseHelper();
  late List<Map<String, dynamic>> masterData;
  List<DirectoryOS> masterDirectories = [];
  QuickActions quickActions = QuickActions();

  Future homeRefresh() async {
    await getMasterData();
    setState(() {});
  }

  Future<bool> _requestPermission() async {
    if (await Permission.storage.request().isGranted &&
        await Permission.camera.request().isGranted) {
      return true;
    }
    await Permission.storage.request();
    await Permission.camera.request();
    return false;
  }

  pushView({String? scanType, DirectoryOS? masterDirectory}) {
    switch (scanType) {
      case 'Normal Scan':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider<DirectoryCubit>(
              create: (context) => DirectoryCubit()
                ..createDirectory()
                ..createImage(context),
              child: ViewScreen(),
            ),
            settings: RouteSettings(name: AppRouter.viewScreen),
          ),
        ).whenComplete(() {
          homeRefresh();
        });
        break;
      case 'Quick Scan':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider<DirectoryCubit>(
              create: (context) => DirectoryCubit()
                ..createDirectory()
                ..createImage(
                  context,
                  quickScan: true,
                ),
              child: ViewScreen(),
            ),
            settings: RouteSettings(name: AppRouter.viewScreen),
          ),
        ).whenComplete(() {
          homeRefresh();
        });
        break;
      case 'Import from Gallery':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider<DirectoryCubit>(
              create: (context) => DirectoryCubit()
                ..createDirectory()
                ..createImage(
                  context,
                  fromGallery: true,
                ),
              child: ViewScreen(),
            ),
            settings: RouteSettings(name: AppRouter.viewScreen),
          ),
        ).whenComplete(() {
          homeRefresh();
        });
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider<DirectoryCubit>(
              create: (context) => DirectoryCubit(
                dirName: masterDirectory!.dirName,
                created: masterDirectory.created,
                dirPath: masterDirectory.dirPath,
                firstImgPath: masterDirectory.firstImgPath,
                imageCount: masterDirectory.imageCount,
                lastModified: masterDirectory.lastModified,
                newName: masterDirectory.newName,
                images: <ImageOS>[],
              )..getImageData(),
              lazy: false,
              child: ViewScreen(),
            ),
            settings: RouteSettings(name: AppRouter.viewScreen),
          ),
        ).whenComplete(() {
          homeRefresh();
        });
    }
  }

  Future<List<DirectoryOS>> getMasterData() async {
    masterDirectories = [];
    masterData = await database.getMasterData();
    debugPrint('Master Table => $masterData');
    for (var directory in masterData) {
      var alreadyExistsFlag = false;
      for (var dir in masterDirectories) {
        if (dir.dirPath == directory['dir_path']) {
          alreadyExistsFlag = true;
        }
      }
      if (!alreadyExistsFlag) {
        masterDirectories.add(
          DirectoryOS(
            dirName: directory['dir_name'],
            dirPath: directory['dir_path'],
            created: DateTime.parse(directory['created']),
            imageCount: directory['image_count'],
            firstImgPath: directory['first_img_path'],
            lastModified: DateTime.parse(directory['last_modified']),
            newName: directory['new_name'],
          ),
        );
      }
    }
    masterDirectories = masterDirectories.reversed.toList();
    return masterDirectories;
  }

  void showDemo() async {
    bool visitingFlag = false;

    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (preferences.getBool("alreadyVisited") != null) {
      visitingFlag = true;
    }
    await preferences.setBool('alreadyVisited', true);

    if (!visitingFlag) Navigator.of(context).pushNamed(AppRouter.demoScreen);
  }

  @override
  void initState() {
    super.initState();
    _requestPermission();
    showDemo();
    getMasterData();

    // Quick Action related
    quickActions.initialize((String shortcutType) {
      pushView(scanType: shortcutType);
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'Normal Scan',
        localizedTitle: 'Normal Scan',
        icon: 'normal_scan',
      ),
      ShortcutItem(
        type: 'Quick Scan',
        localizedTitle: 'Quick Scan',
        icon: 'quick_scan',
      ),
      ShortcutItem(
        type: 'Import from Gallery',
        localizedTitle: 'Import from Gallery',
        icon: 'gallery_action',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: RichText(
          text: TextSpan(
            text: 'Open',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
            children: [
              TextSpan(
                text: 'Scan',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ],
          ),
        ),
        // actions: [
        //   IconGestureDetector(
        //     icon: Icon(Icons.camera),
        //     onTap: () {
        //       Navigator.push(context,
        //           MaterialPageRoute(builder: (context) => CameraScreen()));
        //     },
        //   ),
        // ],
      ),
      drawer: CustomDrawer(),
      body: RefreshIndicator(
        backgroundColor: Theme.of(context).primaryColor,
        color: Theme.of(context).colorScheme.secondary,
        onRefresh: homeRefresh,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                AppLocalizations.of(context)!.refresh,
                style: TextStyle(color: Colors.grey[700], fontSize: 11),
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: getMasterData(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  return ListView.builder(
                    itemCount: masterDirectories.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () async {
                          pushView(
                            scanType: 'default',
                            masterDirectory: masterDirectories[index],
                          );
                        },
                        child: Card(
                          color: Theme.of(context).primaryColor,
                          elevation: 0,
                          margin:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.file(
                                      File(masterDirectories[index]
                                          .firstImgPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  masterDirectories[index].newName ??
                                      masterDirectories[index].dirName,
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${masterDirectories[index].lastModified!.year}-${masterDirectories[index].lastModified!.month.toString().padLeft(2, '0')}-${masterDirectories[index].lastModified!.day.toString().padLeft(2, '0')} ${masterDirectories[index].lastModified!.hour.toString().padLeft(2, '0')}:${masterDirectories[index].lastModified!.minute.toString().padLeft(2, '0')}:${masterDirectories[index].lastModified!.second.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    Text(
                                      // TODO: Add size of document
                                      '${masterDirectories[index].imageCount} ${AppLocalizations.of(context)!.images} (700kb)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0, bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.share, size: 20),
                                      onPressed: () async {
                                        FileOperations fileOps =
                                            FileOperations();
                                        var directoryData =
                                            await database.getImageData(
                                                masterDirectories[index]
                                                    .dirName);
                                        List<ImageOS> images = directoryData
                                            .map((image) => ImageOS(
                                                  idx: image['idx'],
                                                  imgPath: image['img_path'],
                                                  selected: false,
                                                ))
                                            .toList();

                                        await fileOps.sharePdf(
                                          context: context,
                                          fileName: masterDirectories[index]
                                                  .newName ??
                                              masterDirectories[index].dirName,
                                          images: images,
                                        );
                                      },
                                      color: Colors.white70,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.download, size: 20),
                                      onPressed: () async {
                                        // Show loading dialog
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            return Center(
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                              ),
                                            );
                                          },
                                        );

                                        FileOperations fileOps =
                                            FileOperations();
                                        var directoryData =
                                            await database.getImageData(
                                                masterDirectories[index]
                                                    .dirName);
                                        List<ImageOS> images = directoryData
                                            .map((image) => ImageOS(
                                                  idx: image['idx'],
                                                  imgPath: image['img_path'],
                                                  selected: false,
                                                ))
                                            .toList();
                                        String? savedPath =
                                            await fileOps.saveToDevice(
                                          context: context,
                                          fileName: masterDirectories[index]
                                                  .newName ??
                                              masterDirectories[index].dirName,
                                          images: images,
                                          quality: 2, // High quality
                                        );

                                        // Hide loading dialog
                                        Navigator.pop(context);

                                        if (savedPath != null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'PDF saved successfully at: $savedPath'),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 5),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text('Failed to save PDF'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      color: Colors.white70,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 20),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) {
                                            return DeleteDialog(
                                              deleteOnPressed: () {
                                                Directory(
                                                        masterDirectories[index]
                                                            .dirPath)
                                                    .deleteSync(
                                                        recursive: true);
                                                database.deleteDirectory(
                                                    dirPath:
                                                        masterDirectories[index]
                                                            .dirPath);
                                                Navigator.pop(context);
                                                homeRefresh();
                                              },
                                            );
                                          },
                                        );
                                      },
                                      color: Colors.white70,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.more_vert, size: 20),
                                      onPressed: () {
                                        // Handle more options
                                      },
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FAB(
        normalScanOnPressed: () {
          pushView(scanType: 'Normal Scan');
        },
        quickScanOnPressed: () {
          pushView(scanType: 'Quick Scan');
        },
        galleryOnPressed: () {
          pushView(scanType: 'Import from Gallery');
        },
      ),
    );
  }
}
