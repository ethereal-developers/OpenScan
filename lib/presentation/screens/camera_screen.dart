import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/config/globals.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/presentation/Widgets/view/icon_gesture.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  MethodChannel channel = new MethodChannel('com.ethereal.openscan/cropper');
  late DocumentPoints documentPoints;

  @override
  void initState() {
    super.initState();

    controller = CameraController(
      Globals.cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final gyroscope =
    //     _gyroscopeValues?.map((double v) => v.toStringAsFixed(1)).toList();

    if (!controller.value.isInitialized) {
      //TODO: Optimize this error
      return Container();
    }

    controller.startImageStream((CameraImage cameraImage) async {
      print(
          'Planes => ${cameraImage.planes.length} => ${cameraImage.height} : ${cameraImage.width}');

      // var data = await channel.invokeMethod("detectDocument", {
      //   //TODO: Fix this
      //   'path': ' T T ',
      //   // 'matrix': ,
      // });
      // documentPoints = DocumentPoints.toDocumentPoints(data);
    });

    return SafeArea(
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          toolbarHeight: 70,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          title: Row(
            children: [
              Spacer(),
              IconGestureDetector(
                icon: Icon(Icons.flash_off),
                onTap: () {},
              ),
              // Spacer(),
              // IconGestureDetector(
              //   icon: Icon(Icons.add_road),
              // )
            ],
          ),
        ),
        body: Container(
          alignment: Alignment.center,
          child: CameraPreview(
            controller,
            child: SpiritLevel(),
            // child: Icon(Icons.ac_unit),
          ),
        ),
        bottomNavigationBar: Container(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          height: 110,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(
                Icons.ac_unit,
                size: 30,
              ),
              Icon(
                Icons.circle,
                size: 75,
              ),
              Icon(
                Icons.photo,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpiritLevel extends StatefulWidget {
  const SpiritLevel({Key? key}) : super(key: key);

  @override
  _SpiritLevelState createState() => _SpiritLevelState();
}

class _SpiritLevelState extends State<SpiritLevel> {
  List<double>? _gyroscopeValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  @override
  void initState() {
    super.initState();
    gyroscopeEvents.listen(
      (GyroscopeEvent event) {
        setState(() {
          _gyroscopeValues = <double>[event.x, event.y, event.z];
          print(_gyroscopeValues);
        });
      },
    );
  }

  @override
  void dispose() {
    _streamSubscriptions[0].cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text('Gyroscope: '),
        ],
      ),
    );
  }
}
