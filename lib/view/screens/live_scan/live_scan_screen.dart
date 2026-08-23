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

  CameraLensDirection _lensDirection = CameraLensDirection.back;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoomOnGestureStart = 1.0;
  bool _isZooming = false; // pauses auto-capture during an active pinch

  Offset? _focusPointNormalized; // null = reticle hidden
  Timer? _focusHideTimer;
  bool _focusSupported = true;
  bool _exposureSupported = true;

  double _minExposureOffset = 0.0;
  double _maxExposureOffset = 0.0;
  double _exposureStepSize = 0.0;
  double _currentExposureOffset = 0.0;

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
    final camera = Globals.cameras.firstWhere(
      (c) => c.lensDirection == _lensDirection,
      orElse: () => Globals.cameras.first,
    );

    for (int attempt = 0; attempt < 2; attempt++) {
      final controller = CameraController(
        camera,
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
        try {
          _minZoom = await controller.getMinZoomLevel();
          _maxZoom = await controller.getMaxZoomLevel();
          _currentZoom = _minZoom;
          _minExposureOffset = await controller.getMinExposureOffset();
          _maxExposureOffset = await controller.getMaxExposureOffset();
          _exposureStepSize = await controller.getExposureOffsetStepSize();
          _currentExposureOffset = 0.0;
        } catch (_) {
          _minZoom = _maxZoom = 1.0;
          _minExposureOffset = _maxExposureOffset = _exposureStepSize = 0.0;
        }
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
    if (_isZooming) return;
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
    _currentZoom = 1.0;
    _currentExposureOffset = 0.0;
    _focusPointNormalized = null;
    _focusHideTimer?.cancel();
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

  Future<void> _switchCamera() async {
    if (Globals.cameras.length < 2 || _capturing) return;
    final targetDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    if (!Globals.cameras.any((c) => c.lensDirection == targetDirection)) {
      return;
    }

    final controller = _cameraController;
    setState(() => _cameraController = null);
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    }

    _lensDirection = targetDirection;
    _torchOn = false;
    _currentZoom = 1.0;
    _currentExposureOffset = 0.0;
    _focusPointNormalized = null;
    _focusHideTimer?.cancel();
    _focusSupported = true;
    _exposureSupported = true;

    await _initializeCamera();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseZoomOnGestureStart = _currentZoom;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _cameraController;
    if (controller == null || _maxZoom <= _minZoom) return;
    if (!_isZooming) setState(() => _isZooming = true);
    final target =
        (_baseZoomOnGestureStart * details.scale).clamp(_minZoom, _maxZoom);
    if ((target - _currentZoom).abs() < 0.01) return;
    try {
      await controller.setZoomLevel(target);
      if (mounted) setState(() => _currentZoom = target);
    } catch (_) {}
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (mounted) setState(() => _isZooming = false);
  }

  Future<void> _onTapToFocus(TapUpDetails details, Size previewSize) async {
    final controller = _cameraController;
    if (controller == null ||
        previewSize.width == 0 ||
        previewSize.height == 0) {
      return;
    }
    final normalized = Offset(
      (details.localPosition.dx / previewSize.width).clamp(0.0, 1.0),
      (details.localPosition.dy / previewSize.height).clamp(0.0, 1.0),
    );

    _focusHideTimer?.cancel();
    setState(() => _focusPointNormalized = normalized);
    _focusHideTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _focusPointNormalized = null);
    });

    if (_focusSupported) {
      try {
        await controller.setFocusMode(FocusMode.auto);
        await controller.setFocusPoint(normalized);
      } catch (_) {
        _focusSupported = false;
      }
    }
    if (_exposureSupported) {
      try {
        await controller.setExposureMode(ExposureMode.auto);
        await controller.setExposurePoint(normalized);
      } catch (_) {
        _exposureSupported = false;
      }
    }
  }

  Future<void> _adjustExposure(double delta) async {
    final controller = _cameraController;
    if (controller == null || _exposureStepSize <= 0) return;
    final target = (_currentExposureOffset + delta)
        .clamp(_minExposureOffset, _maxExposureOffset);
    if (target == _currentExposureOffset) return;
    try {
      // Not the return value: on Android, camera_android_camerax's
      // setExposureOffset returns the raw exposure-compensation index
      // (an integer step count) rather than the EV offset its own
      // doc comment promises, so trusting it here corrupts
      // _currentExposureOffset by a factor of ~1/stepSize and makes
      // the offset run away upward regardless of which button was
      // pressed. `target` is already the exact step-aligned EV value
      // we asked the camera to apply, so use that instead.
      await controller.setExposureOffset(target);
      if (mounted) setState(() => _currentExposureOffset = target);
    } catch (_) {}
  }

  @override
  void dispose() {
    _focusHideTimer?.cancel();
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
              onPressed: (_cameraController != null &&
                      _lensDirection == CameraLensDirection.back)
                  ? _toggleTorch
                  : null,
            ),
            IconButton(
              tooltip: _lensDirection == CameraLensDirection.back
                  ? 'Switch to front camera'
                  : 'Switch to back camera',
              icon: const Icon(Icons.cameraswitch, color: Colors.white),
              onPressed:
                  (_cameraController != null && Globals.cameras.length > 1)
                      ? _switchCamera
                      : null,
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
                  return LayoutBuilder(
                    builder: (context, outerConstraints) {
                      final previewSize = outerConstraints.biggest;
                      return GestureDetector(
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                        onScaleEnd: _onScaleEnd,
                        onTapUp: (details) =>
                            _onTapToFocus(details, previewSize),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: CameraPreview(
                                controller,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final size = constraints.biggest;
                                    return ValueListenableBuilder(
                                      valueListenable:
                                          _quadSmoother.smoothedQuad,
                                      builder: (context, quad, _) {
                                        if (quad == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return CustomPaint(
                                          painter: LiveQuadPainter(
                                            points: quad.points
                                                .map((p) => Offset(
                                                    p.x * size.width,
                                                    p.y * size.height))
                                                .toList(),
                                            isImminent: _autoCaptureImminent,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (_maxZoom > _minZoom)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${_currentZoom.toStringAsFixed(1)}x',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ),
                            if (_focusPointNormalized != null)
                              Positioned(
                                left: _focusPointNormalized!.dx *
                                        previewSize.width -
                                    32,
                                top: _focusPointNormalized!.dy *
                                        previewSize.height -
                                    32,
                                child: IgnorePointer(
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey(_focusPointNormalized),
                                    tween: Tween(begin: 1.4, end: 1.0),
                                    duration:
                                        const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                    builder: (context, scale, child) =>
                                        Transform.scale(
                                      scale: scale,
                                      child: Opacity(
                                        opacity:
                                            (2.0 - scale).clamp(0.0, 1.0),
                                        child: child,
                                      ),
                                    ),
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (_exposureStepSize > 0)
                              Positioned(
                                bottom: 16,
                                right: 16,
                                // Absorb taps on this panel so they don't
                                // fall through to the preview's
                                // GestureDetector below — otherwise a tap
                                // that misses an IconButton's hit target
                                // (the container background, the padding,
                                // the EV label) is read as a tap-to-focus
                                // at this corner, which re-points
                                // auto-exposure metering there and fights
                                // the manual offset, making exposure creep
                                // upward regardless of which button was
                                // pressed.
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add,
                                              color: Colors.white, size: 20),
                                          onPressed: _currentExposureOffset >=
                                                  _maxExposureOffset
                                              ? null
                                              : () => _adjustExposure(
                                                  _exposureStepSize),
                                        ),
                                        Text(
                                          _currentExposureOffset == 0
                                              ? 'EV'
                                              : '${_currentExposureOffset > 0 ? '+' : ''}${_currentExposureOffset.toStringAsFixed(1)}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove,
                                              color: Colors.white, size: 20),
                                          onPressed: _currentExposureOffset <=
                                                  _minExposureOffset
                                              ? null
                                              : () => _adjustExposure(
                                                  -_exposureStepSize),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
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
