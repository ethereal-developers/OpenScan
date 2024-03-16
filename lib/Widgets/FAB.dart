import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../Utilities/constants.dart';
import 'package:simple_animated_icon/simple_animated_icon.dart';

class FAB extends StatefulWidget {
  final Function()? normalScanOnPressed;
  final Function()? quickScanOnPressed;
  final Function()? galleryOnPressed;
  final Function dialOpen;
  final Function dialClose;

  const FAB({
    required Key key,
    required this.normalScanOnPressed,
    required this.quickScanOnPressed,
    required this.galleryOnPressed,
    required this.dialOpen,
    required this.dialClose,
  });

  @override
  _FABState createState() => _FABState();
}

class _FABState extends State<FAB> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200))
          ..addListener(() {
            setState(() {});
          });
    _progress =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      childMargin: EdgeInsets.fromLTRB(0, 0, 18, 20),
      child: SimpleAnimatedIcon(
        startIcon: Icons.add,
        endIcon: Icons.close,
        size: 30,
        progress: _progress,
      ),
      visible: true,
      closeManually: false,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      tooltip: 'Scan Options',
      heroTag: 'speed-dial-hero-tag',
      backgroundColor: secondaryColor,
      foregroundColor: primaryColor,
      elevation: 8.0,
      shape: CircleBorder(),
      onOpen: () {
        _animationController.forward();
      },
      onClose: () {
        _animationController.reverse();
      },
      children: [
        SpeedDialChild(
          child: Icon(Icons.camera_alt),
          backgroundColor: Colors.white,
          label: 'Normal Scan',
          labelStyle: TextStyle(fontSize: 18.0, color: Colors.black),
          onTap: widget.normalScanOnPressed,
        ),
        SpeedDialChild(
          child: Icon(Icons.timelapse),
          backgroundColor: Colors.white,
          label: 'Quick Scan',
          labelStyle: TextStyle(fontSize: 18.0, color: Colors.black),
          onTap: widget.quickScanOnPressed,
        ),
        SpeedDialChild(
          child: Icon(Icons.image),
          backgroundColor: Colors.white,
          label: 'Import from Gallery',
          labelStyle: TextStyle(fontSize: 18.0, color: Colors.black),
          onTap: widget.galleryOnPressed,
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }
}
