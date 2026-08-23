import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:openscan/config/globals.dart';
import 'package:openscan/core/cv/frame_adapter.dart';
import 'package:openscan/view/Widgets/live_scan/live_quad_painter.dart';
import 'package:openscan/view/screens/live_scan/live_scan_controller.dart';
import 'package:permission_handler/permission_handler.dart';

/// Pushes the live-scan route and resolves with the captured photo, or
/// null if the user backed out without capturing — mirrors
/// `imageCropper()`'s existing pop-with-value contract in
/// `crop_screen.dart`. The captured photo is NOT pre-cropped: it goes
/// through the same unchanged crop screen as every other capture flow,
/// which reruns detection fresh at full resolution. The live overlay is
/// guidance-only.
Future<File?> captureWithLiveScan(BuildContext context) async {
  // Callers (directory_cubit.dart's createImage) can invoke this
  // synchronously from within a BlocProvider's create: callback, which
  // runs during the new route's initial build — pushing another route
  // from inside that build throws ("setState() or markNeedsBuild()
  // called during build"). Deferring to the next frame, the same fix
  // already used for a similar build-time-side-effect issue in
  // crop_screen.dart, avoids the re-entrant Navigator.push.
  final completer = Completer<File?>();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final result = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (context) => LiveScanScreen()),
    );
    completer.complete(result);
  });
  return completer.future;
}

class LiveScanScreen extends StatefulWidget {
  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen>
    with WidgetsBindingObserver {
  final LiveScanController _liveScanController = LiveScanController();

  CameraController? _cameraController;
  Future<void>? _initializeFuture;
  int _frameCounter = 0;
  bool _capturing = false;
  bool _permissionDenied = false;
  bool _cameraError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFuture = _initialize();
  }

  Future<void> _initialize() async {
    if (!await Permission.camera.isGranted) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) setState(() => _permissionDenied = true);
        return;
      }
    }

    await _liveScanController.start();
    await _initializeCamera();
  }

  /// Opens the camera with a timeout + one retry. On this device, reopening
  /// a CameraController shortly after disposing the previous one (e.g. on
  /// app resume) can race the platform's camera2 session teardown and hang
  /// initialize() forever waiting for an onOpened callback that never
  /// arrives (observed on-device via logcat: an onClosed event for the
  /// stale session lands on the new open attempt instead) — a known rough
  /// edge of the stale camera plugin fork this app is pinned to. Retrying
  /// once after a longer delay recovers in the common case; if it still
  /// fails, surface an error instead of leaving the user on an infinite
  /// spinner.
  Future<void> _initializeCamera() async {
    final backCamera = Globals.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => Globals.cameras.first,
    );

    for (int attempt = 0; attempt < 2; attempt++) {
      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      try {
        await controller.initialize().timeout(const Duration(seconds: 5));
        if (!mounted) {
          await controller.dispose();
          return;
        }
        _cameraController = controller;
        await controller.startImageStream(_onFrame);
        setState(() {});
        return;
      } catch (e) {
        // Don't await dispose() here: when initialize() hung, the native
        // camera plugin's platform channel is itself wedged processing
        // that stuck open() call, so a dispose() call queued behind it
        // would hang just as long, defeating the retry. Let it resolve
        // in the background instead.
        // ignore: unawaited_futures
        controller.dispose();
        if (attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 1000));
        } else if (mounted) {
          setState(() => _cameraError = true);
        }
      }
    }
  }

  void _onFrame(CameraImage image) {
    if (++_frameCounter % 3 != 0) return;
    if (_liveScanController.isBusy) return;

    final gray = grayscaleFromFrame(
      yPlaneOrBgraBytes: image.planes[0].bytes,
      bytesPerRow: image.planes[0].bytesPerRow,
      width: image.width,
      height: image.height,
      format: image.format.group,
      targetLongEdge: kLiveDetectionMaxDimension,
    );
    if (gray == null) return;

    final scale = kLiveDetectionMaxDimension /
        (image.width > image.height ? image.width : image.height);
    final w = scale < 1.0 ? (image.width * scale).round() : image.width;
    final h = scale < 1.0 ? (image.height * scale).round() : image.height;
    _liveScanController.submitFrame(gray, w, h);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
      // Rebuild immediately so no widget keeps referencing the disposed
      // controller — without this, the stale CameraPreview from the last
      // build stays on screen until something else triggers a rebuild,
      // which throws "buildPreview() was called on a disposed
      // CameraController" on resume.
      if (mounted) setState(() => _cameraController = null);
    } else if (state == AppLifecycleState.resumed &&
        _cameraController == null &&
        !_permissionDenied) {
      // The just-disposed controller's camera2 session doesn't always
      // finish releasing the device before this fires — opening a new
      // CameraController immediately can race the platform's device
      // close and hang forever waiting for an onOpened callback that
      // never comes (observed on-device via logcat: an "onClosed" event
      // arrives for the new open attempt instead). A short delay avoids
      // the race.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted &&
            _cameraController == null &&
            !_permissionDenied &&
            !_cameraError) {
          _initializeCamera();
        }
      });
    }
  }

  Future<void> _onCapturePressed() async {
    final controller = _cameraController;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      await controller.stopImageStream();
      final shot = await controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, File(shot.path));
    } catch (e) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't capture — please try again.")),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // _onCapturePressed already stops the stream before takePicture(); a
    // second stopImageStream() call throws CameraException since the
    // plugin doesn't allow stopping an already-stopped stream.
    if (_cameraController?.value.isStreamingImages ?? false) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    _liveScanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0.0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context, null),
          ),
        ),
        body: _permissionDenied
            ? _buildMessage('Camera permission is required for live scan.')
            : _cameraError
                ? _buildMessage(
                    "Couldn't start the camera — please go back and try again.")
                : FutureBuilder<void>(
                future: _initializeFuture,
                builder: (context, snapshot) {
                  final controller = _cameraController;
                  if (controller == null || !controller.value.isInitialized) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  // CameraPreview lays itself out in its own internal
                  // AspectRatio + (on Android) RotatedBox for the device's
                  // current orientation, and offers a `child` slot that's
                  // sized identically to the rotated preview texture — so
                  // an overlay passed there sits in exactly the same
                  // "portrait" coordinate space that
                  // rotateQuadForPortrait's normalized output already
                  // targets, with no separate rotation/measurement needed
                  // here.
                  return Center(
                    child: CameraPreview(
                      controller,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.biggest;
                          return ValueListenableBuilder(
                            valueListenable: _liveScanController.latestQuad,
                            builder: (context, quad, _) {
                              if (quad == null) return const SizedBox.shrink();
                              return CustomPaint(
                                painter: LiveQuadPainter(
                                  points: quad.points
                                      .map((p) => Offset(
                                          p.x * size.width, p.y * size.height))
                                      .toList(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
        bottomNavigationBar: SafeArea(
          child: Container(
            color: Colors.black,
            height: 90,
            child: Center(
              child: _capturing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : IconButton(
                      iconSize: 64,
                      icon: const Icon(Icons.camera, color: Colors.white),
                      onPressed:
                          _cameraController != null ? _onCapturePressed : null,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          message,
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
