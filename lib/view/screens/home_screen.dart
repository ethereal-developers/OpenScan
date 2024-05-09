import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:openscan/core/appRouter.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/FAB.dart';
import 'package:openscan/view/Widgets/delete_dialog.dart';
import 'package:openscan/view/Widgets/drawer.dart';
import 'package:openscan/view/Widgets/renameDialog.dart';
import 'package:openscan/view/screens/camera_screen.dart';
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
            settings: RouteSettings(name: AppRouter.VIEW_SCREEN),
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
            settings: RouteSettings(name: AppRouter.VIEW_SCREEN),
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
            settings: RouteSettings(name: AppRouter.VIEW_SCREEN),
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
            settings: RouteSettings(name: AppRouter.VIEW_SCREEN),
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

    if (!visitingFlag) Navigator.of(context).pushNamed(AppRouter.DEMO_SCREEN);
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
                      return FocusedMenuHolder(
                        onPressed: () {},
                        menuWidth: size.width * 0.44,
                        child: ListTile(
                          leading: Image.file(
                            File(masterDirectories[index].firstImgPath!),
                            width: 50,
                            height: 50,
                          ),
                          title: Text(
                            masterDirectories[index].newName ??
                                masterDirectories[index].dirName,
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.last_updated +
                                    ': ${masterDirectories[index].lastModified!.day}/${masterDirectories[index].lastModified!.month}/${masterDirectories[index].lastModified!.year}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                              Text(
                                '${masterDirectories[index].imageCount} ${(masterDirectories[index].imageCount == 1) ? AppLocalizations.of(context)!.image : AppLocalizations.of(context)!.images}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_right_rounded,
                            size: 30,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          onTap: () async {
                            pushView(
                              scanType: 'default',
                              masterDirectory: masterDirectories[index],
                            );
                          },
                        ),
                        menuItems: [
                          FocusedMenuItem(
                            title: Text(
                              AppLocalizations.of(context)!.rename,
                              style: TextStyle(color: Colors.black),
                            ),
                            trailingIcon: Icon(
                              Icons.edit_rounded,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return RenameDialog(
                                    onConfirm: (value) {
                                      homeRefresh();
                                    },
                                    docTableName:
                                        masterDirectories[index].dirName,
                                    fileName:
                                        masterDirectories[index].newName ??
                                            masterDirectories[index].dirName,
                                  );
                                },
                              ).whenComplete(() {
                                setState(() {});
                              });
                            },
                          ),
                          FocusedMenuItem(
                            title: Text(AppLocalizations.of(context)!.delete),
                            trailingIcon: Icon(Icons.delete_rounded),
                            backgroundColor: Colors.redAccent,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) {
                                  return DeleteDialog(
                                    deleteOnPressed: () {
                                      Directory(
                                              masterDirectories[index].dirPath)
                                          .deleteSync(recursive: true);
                                      database.deleteDirectory(
                                          dirPath:
                                              masterDirectories[index].dirPath);
                                      Navigator.pop(context);
                                      homeRefresh();
                                    },
                                  );
                                },
                              ).whenComplete(() {
                                setState(() {});
                              });
                            },
                          ),
                        ],
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
