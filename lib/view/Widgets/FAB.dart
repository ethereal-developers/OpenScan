import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:simple_animated_icon/simple_animated_icon.dart';

class FAB extends StatefulWidget {
  final void Function()? normalScanOnPressed;
  final void Function()? quickScanOnPressed;
  final void Function()? galleryOnPressed;
  final void Function()? dialOpen;
  final void Function()? dialClose;

  const FAB({
    Key? key,
    this.normalScanOnPressed,
    this.quickScanOnPressed,
    this.galleryOnPressed,
    this.dialOpen,
    this.dialClose,
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
        AnimationController(vsync: this, duration: Duration(milliseconds: 300))
          ..addListener(() {
            setState(() {});
          });
    _progress =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      // marginRight: 18,
      // marginBottom: 20,
      child: SimpleAnimatedIcon(
        startIcon: Icons.add_rounded,
        endIcon: Icons.close_rounded,
        size: 30,
        progress: _progress,
      ),
      visible: true,
      closeManually: false,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      tooltip: AppLocalizations.of(context)!.scan_options,
      heroTag: 'speed-dial-hero-tag',
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.primary,
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
          child: Icon(
            Icons.camera_alt_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          backgroundColor: Colors.white,
          label: AppLocalizations.of(context)!.normal_scan,
          labelStyle:
              TextStyle(fontSize: 18.0, color: Theme.of(context).colorScheme.primary),
          onTap: widget.normalScanOnPressed,
        ),
        SpeedDialChild(
          child: Icon(
            Icons.timelapse_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          backgroundColor: Colors.white,
          label: AppLocalizations.of(context)!.quick_scan,
          labelStyle:
              TextStyle(fontSize: 18.0, color: Theme.of(context).colorScheme.primary),
          onTap: widget.quickScanOnPressed,
        ),
        SpeedDialChild(
          child: Icon(
            Icons.image_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          backgroundColor: Colors.white,
          label: AppLocalizations.of(context)!.import_from_gallery,
          labelStyle:
              TextStyle(fontSize: 18.0, color: Theme.of(context).colorScheme.primary),
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
