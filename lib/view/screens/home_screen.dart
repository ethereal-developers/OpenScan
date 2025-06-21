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
import 'package:openscan/view/Widgets/hovering_snackbar.dart';
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
                ..importImagesFromGallery(context),
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

  Future<int> getDirectorySize(String dirPath) async {
    int totalSize = 0;
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await for (final file in dir.list()) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    }
    return totalSize;
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
        int dirSize = await getDirectorySize(directory['dir_path']);
        masterDirectories.add(
          DirectoryOS(
            dirName: directory['dir_name'],
            dirPath: directory['dir_path'],
            created: DateTime.parse(directory['created']),
            imageCount: directory['image_count'],
            firstImgPath: directory['first_img_path'],
            lastModified: DateTime.parse(directory['last_modified']),
            newName: directory['new_name'],
            size: dirSize,
          ),
        );
      }
    }
    masterDirectories.sort((a, b) => b.lastModified!.compareTo(a.lastModified!));
    return masterDirectories;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
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
                          child: Row(
                            children: [
                              Container(
                                height: 120,
                                width: 120,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    bottomLeft: Radius.circular(4),
                                  ),
                                  child: Image.file(
                                    File(
                                        masterDirectories[index].firstImgPath!),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        masterDirectories[index].newName ??
                                            masterDirectories[index].dirName,
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${masterDirectories[index].lastModified!.year}-${masterDirectories[index].lastModified!.month.toString().padLeft(2, '0')}-${masterDirectories[index].lastModified!.day.toString().padLeft(2, '0')} ${masterDirectories[index].lastModified!.hour.toString().padLeft(2, '0')}:${masterDirectories[index].lastModified!.minute.toString().padLeft(2, '0')}:${masterDirectories[index].lastModified!.second.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      Text(
                                        '${masterDirectories[index].imageCount} ${masterDirectories[index].imageCount == 1 ? 'Image' : 'Images'} (${_formatSize(masterDirectories[index].size!)})',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            icon: Icon(Icons.share, size: 20),
                                            onPressed: () async {
                                              FileOperations fileOps =
                                                  FileOperations();
                                              var directoryData =
                                                  await database.getImageData(
                                                      masterDirectories[index]
                                                          .dirName);
                                              List<ImageOS> images =
                                                  directoryData
                                                      .map((image) => ImageOS(
                                                            idx: image['idx'],
                                                            imgPath: image[
                                                                'img_path'],
                                                            selected: false,
                                                          ))
                                                      .toList();

                                              await fileOps.sharePdf(
                                                context: context,
                                                fileName:
                                                    masterDirectories[index]
                                                            .newName ??
                                                        masterDirectories[index]
                                                            .dirName,
                                                images: images,
                                              );
                                            },
                                            color: Colors.white70,
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            icon:
                                                Icon(Icons.download, size: 20),
                                            onPressed: () async {
                                              // Show loading dialog
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder:
                                                    (BuildContext context) {
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
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
                                              List<ImageOS> images =
                                                  directoryData
                                                      .map((image) => ImageOS(
                                                            idx: image['idx'],
                                                            imgPath: image[
                                                                'img_path'],
                                                            selected: false,
                                                          ))
                                                      .toList();
                                              String? savedPath =
                                                  await fileOps.saveToDevice(
                                                context: context,
                                                fileName:
                                                    masterDirectories[index]
                                                            .newName ??
                                                        masterDirectories[index]
                                                            .dirName,
                                                images: images,
                                                quality: 2, // High quality
                                              );

                                              // Hide loading dialog
                                              Navigator.pop(context);

                                              if (savedPath != null) {
                                                HoveringSnackBarHelper.showSuccess(
                                                  context,
                                                  message: 'PDF saved successfully at: $savedPath',
                                                  duration: Duration(seconds: 5),
                                                );
                                              } else {
                                                HoveringSnackBarHelper.showError(
                                                  context,
                                                  message: 'Failed to save PDF',
                                                );
                                              }
                                            },
                                            color: Colors.white70,
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            icon: Icon(Icons.delete, size: 20),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) {
                                                  return DeleteDialog(
                                                    deleteOnPressed: () {
                                                      Directory(
                                                              masterDirectories[
                                                                      index]
                                                                  .dirPath)
                                                          .deleteSync(
                                                              recursive: true);
                                                      database.deleteDirectory(
                                                          dirPath:
                                                              masterDirectories[
                                                                      index]
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
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            icon:
                                                Icon(Icons.more_vert, size: 20),
                                            onPressed: () {
                                              // Handle more options
                                            },
                                            color: Colors.white70,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
