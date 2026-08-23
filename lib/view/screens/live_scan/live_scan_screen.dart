import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:openscan/config/globals.dart';
import 'package:openscan/core/cv/frame_adapter.dart';
import 'package:openscan/view/Widgets/live_scan/live_quad_painter.dart';
import 'package:openscan/view/screens/live_scan/auto_capture_detector.dart';
import 'package:openscan/view/screens/live_scan/live_scan_controller.dart';
import 'package:openscan/view/screens/live_scan/quad_smoother.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAutoCapturePrefKey = 'liveScanAutoCaptureEnabled';

/// Pushes the live-scan route and resolves with the captured photos (one
/// per page, in capture order), or null if the user backed out without
/// capturing anything — mirrors `imageCropper()`'s existing pop-with-value
/// contract in `crop_screen.dart`. The captured photos are NOT pre-cropped:
/// each goes through the same unchanged crop screen as every other capture
/// flow, which reruns detection fresh at full resolution. The live overlay
/// is guidance-only.
Future<List<File>?> captureWithLiveScan(BuildContext context) async {
  // Callers (directory_cubit.dart's createImage) can invoke this
  // synchronously from within a BlocProvider's create: callback, which
  // runs during the new route's initial build — pushing another route
  // from inside that build throws ("setState() or markNeedsBuild()
  // called during build"). Deferring to the next frame, the same fix
  // already used for a similar build-time-side-effect issue in
  // crop_screen.dart, avoids the re-entrant Navigator.push.
  final completer = Completer<List<File>?>();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final result = await Navigator.push<List<File>?>(
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
  final QuadSmoother _quadSmoother = QuadSmoother();
  late final AutoCaptureDetector _autoCaptureDetector;

  CameraController? _cameraController;
  Future<void>? _initializeFuture;
  int _frameCounter = 0;
  bool _capturing = false;
  bool _permissionDenied = false;
  bool _cameraError = false;

  // Batch capture: pages accumulated in this live-scan session so far.
  // Plain State fields — untouched by the camera controller being
  // disposed/recreated across app-lifecycle pause/resume, and the
  // underlying photo files are already persisted to disk by
  // takePicture(), so this survives a background/resume cycle.
  final List<File> _capturedFiles = [];

  bool _autoCaptureEnabled = true;
  bool _autoCaptureImminent = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoCaptureDetector = AutoCaptureDetector(
      onStable: _onAutoCaptureStable,
      onImminentChanged: (imminent) {
        if (mounted) setState(() => _autoCaptureImminent = imminent);
      },
    );
    _liveScanController.latestQuad.addListener(_onLatestQuadChanged);
    _quadSmoother.smoothedQuad.addListener(_onSmoothedQuadChanged);
    _initializeFuture = _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _autoCaptureEnabled = prefs.getBool(_kAutoCapturePrefKey) ?? true;
    _autoCaptureDetector.enabled = _autoCaptureEnabled;

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

  /// Opens the camera with a timeout + one retry, so a slow or failed
  /// camera open (low light, hardware contention, a genuinely flaky
  /// device) surfaces a graceful error instead of stranding the user on
  /// an infinite spinner.
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
        // Don't await dispose() here: if initialize() hung rather than
        // throwing outright, the platform channel may still be busy with
        // that call, and awaiting dispose() on it would block the retry
        // just as long. Let it resolve in the background instead.
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

  void _onLatestQuadChanged() {
    // Raw per-frame detections are noisy (see quad_smoother.dart's doc
    // comment) — route them through QuadSmoother first; the painter and
    // AutoCaptureDetector both consume its smoothed output instead of this
    // raw value directly.
    _quadSmoother.onRawQuad(_liveScanController.latestQuad.value);
  }

  void _onSmoothedQuadChanged() {
    _autoCaptureDetector.onQuadUpdate(_quadSmoother.smoothedQuad.value);
  }

  void _onAutoCaptureStable() {
    if (_capturing) return;
    _onCapturePressed();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle `resumed` first and unconditionally: by the time it fires,
    // _cameraController is always null (the pause/hidden path below just
    // disposed it), so a shared "return if controller == null" guard at
    // the top of this method — as this used to have — would make the
    // resume branch dead code. Bug found via on-device logging: the
    // resume path never ran at all, not a native-plugin race as first
    // suspected.
    if (state == AppLifecycleState.resumed) {
      if (_cameraController == null && !_permissionDenied && !_cameraError) {
        // The just-disposed controller's camera2 session doesn't always
        // finish releasing the device before this fires — opening a new
        // CameraController immediately can race the platform's device
        // close. A short delay avoids that race.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted &&
              _cameraController == null &&
              !_permissionDenied &&
              !_cameraError) {
            _initializeCamera();
          }
        });
      }
      return;
    }

    // inactive/hidden/paused (Flutter delivers all three while
    // backgrounding, in that order): release the camera. Safe to call
    // more than once across that sequence — controller is null after the
    // first dispose, so later calls just return.
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
    controller.dispose();
    // The torch dies with the disposed controller; a fresh controller on
    // resume always starts with flash off, so reset the flag here rather
    // than silently relighting it without the user re-tapping.
    _torchOn = false;
    // Rebuild immediately so no widget keeps referencing the disposed
    // controller — without this, the stale CameraPreview from the last
    // build stays on screen until something else triggers a rebuild,
    // which throws "buildPreview() was called on a disposed
    // CameraController" on resume.
    if (mounted) setState(() => _cameraController = null);
  }

  Future<void> _onCapturePressed() async {
    final controller = _cameraController;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      await controller.stopImageStream();
      final shot = await controller.takePicture();
      _capturedFiles.add(File(shot.path));
      _autoCaptureDetector.notifyCaptured();
      // A new document after this one shouldn't inherit the outgoing
      // one's filter velocity/lag.
      _quadSmoother.reset();
      if (!mounted) return;
      await controller.startImageStream(_onFrame);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't capture — please try again.")),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _onDonePressed() {
    Navigator.pop(
      context,
      _capturedFiles.isEmpty ? null : List<File>.from(_capturedFiles),
    );
  }

  void _onUndoLastPressed() {
    if (_capturedFiles.isEmpty) return;
    setState(() => _capturedFiles.removeLast());
  }

  Future<void> _toggleAutoCapture() async {
    setState(() => _autoCaptureEnabled = !_autoCaptureEnabled);
    _autoCaptureDetector.enabled = _autoCaptureEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoCapturePrefKey, _autoCaptureEnabled);
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null) return;
    final newMode = _torchOn ? FlashMode.off : FlashMode.torch;
    try {
      await controller.setFlashMode(newMode);
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Torch isn't available on this device.")),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveScanController.latestQuad.removeListener(_onLatestQuadChanged);
    _quadSmoother.smoothedQuad.removeListener(_onSmoothedQuadChanged);
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
          actions: [
            IconButton(
              tooltip: _autoCaptureEnabled
                  ? 'Auto-capture on'
                  : 'Auto-capture off',
              icon: Icon(
                _autoCaptureEnabled
                    ? Icons.auto_awesome
                    : Icons.auto_awesome_outlined,
                color: Colors.white,
              ),
              onPressed: _toggleAutoCapture,
            ),
            IconButton(
              tooltip: _torchOn ? 'Torch on' : 'Torch off',
              icon: Icon(
                _torchOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: _cameraController != null ? _toggleTorch : null,
            ),
          ],
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
                            valueListenable: _quadSmoother.smoothedQuad,
                            builder: (context, quad, _) {
                              if (quad == null) return const SizedBox.shrink();
                              return CustomPaint(
                                painter: LiveQuadPainter(
                                  points: quad.points
                                      .map((p) => Offset(
                                          p.x * size.width, p.y * size.height))
                                      .toList(),
                                  isImminent: _autoCaptureImminent,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Undo last capture',
                        icon: const Icon(Icons.undo, color: Colors.white),
                        onPressed: _capturedFiles.isEmpty
                            ? null
                            : _onUndoLastPressed,
                      ),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white24,
                        child: Text(
                          '${_capturedFiles.length}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                _capturing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : GestureDetector(
                        onLongPress: _toggleAutoCapture,
                        child: IconButton(
                          iconSize: 64,
                          icon: const Icon(Icons.camera, color: Colors.white),
                          onPressed: _cameraController != null
                              ? _onCapturePressed
                              : null,
                        ),
                      ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _onDonePressed,
                        child: const Text(
                          'Done',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
