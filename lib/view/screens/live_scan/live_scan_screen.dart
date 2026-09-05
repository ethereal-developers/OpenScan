import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/config/globals.dart';
import 'package:openscan/core/cv/frame_adapter.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/settings/app_settings.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/core/cv/models/quad.dart';
import 'package:openscan/view/Widgets/live_scan/live_quad_painter.dart';
import 'package:openscan/view/screens/live_scan/auto_capture_detector.dart';
import 'package:openscan/view/screens/live_scan/live_scan_controller.dart';
import 'package:openscan/view/screens/live_scan/quad_smoother.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAutoCapturePrefKey = 'liveScanAutoCaptureEnabled';

/// Height of the two controls flanking the shutter — big enough to sit as
/// peers of the 70px shutter rather than as afterthoughts beside it.
const double _kSideControlSize = 60;

/// One page captured in a live-scan session: the full-resolution photo,
/// plus the document boundary that was on screen at the moment of capture
/// (fractional [0,1] portrait-overlay coordinates — see
/// `rotateQuadForPortrait`), or null if nothing was detected then.
///
/// A page is cropped to [quad] on the way into the document — those are
/// the edges the user was looking at when the shutter fired, by hand or by
/// auto-capture — and stored whole when there is no [quad]. Nothing here
/// opens the crop screen; cropping by hand is a deliberate act afterwards,
/// from the page's own Crop button.
///
/// [prepared] marks a page that has already been through the storage
/// pipeline here in the session — cropped to its boundary, downscaled and
/// re-encoded at page size, staged on disk — so [file] is the finished
/// page, [original] its uncropped companion when the keep-originals
/// setting is on, and [quad] is null because it has already been applied.
/// The document only has to move those files in. This is the normal case:
/// each page is processed the moment its shutter fires, while the user is
/// still framing the next one, rather than the whole batch being processed
/// after Done. A page whose processing failed falls back to the raw
/// capture with its [quad] intact, and the document processes it the old
/// way.
///
/// [imported] marks a page picked from the gallery rather than shot here.
/// An imported picture is already whatever the user wants it to be — it
/// was never framed through this viewfinder — so it goes straight into
/// the document, exactly like a gallery import from the library screen.
class LiveCapture {
  final File file;
  final Quad? quad;
  final bool imported;
  final bool prepared;
  final File? original;

  const LiveCapture({
    required this.file,
    this.quad,
    this.imported = false,
    this.prepared = false,
    this.original,
  });
}

/// Pushes the live-scan route and resolves with the captured pages (one
/// per photo, in capture order), or null if the user backed out without
/// capturing anything — mirrors `imageCropper()`'s existing pop-with-value
/// contract in `crop_screen.dart`.
Future<List<LiveCapture>?> captureWithLiveScan(BuildContext context) async {
  // Callers (directory_cubit.dart's createImage) can invoke this
  // synchronously from within a BlocProvider's create: callback, which
  // runs during the new route's initial build — pushing another route
  // from inside that build throws ("setState() or markNeedsBuild()
  // called during build"). Deferring to the next frame, the same fix
  // already used for a similar build-time-side-effect issue in
  // crop_screen.dart, avoids the re-entrant Navigator.push.
  final completer = Completer<List<LiveCapture>?>();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final result = await Navigator.push<List<LiveCapture>?>(
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final LiveScanController _liveScanController = LiveScanController();
  final QuadSmoother _quadSmoother = QuadSmoother();
  late final AutoCaptureDetector _autoCaptureDetector;

  CameraController? _cameraController;
  Future<void>? _initializeFuture;
  int _frameCounter = 0;
  // True from the shutter firing until that page is processed and staged.
  // Gates the shutter, auto-capture and Done, and shows the spinner in
  // the shutter's place: one page is finished before the next is framed,
  // so a session's pages are ready by the time the user is.
  bool _capturing = false;
  bool _permissionDenied = false;
  bool _cameraError = false;

  // Batch capture: pages accumulated in this live-scan session so far.
  // Plain State fields — untouched by the camera controller being
  // disposed/recreated across app-lifecycle pause/resume, and the
  // underlying photo files are already persisted to disk by
  // takePicture(), so this survives a background/resume cycle.
  final List<LiveCapture> _capturedFiles = [];

  /// Where processed pages are staged until the document adopts them.
  /// Resolved once per session, on the first capture.
  Directory? _stagingDir;
  final FileOperations _fileOperations = FileOperations();

  bool _autoCaptureEnabled = true;
  bool _autoCaptureImminent = false;
  bool _torchOn = false;

  /// True while the scene is too dark for detection to be reliable. Derived
  /// from the same grayscale buffer detection already runs on, so it costs
  /// a sampled pass over a 320px frame rather than a second pipeline.
  bool _lowLight = false;
  static const int _kLowLightThreshold = 55;

  /// Rule-of-thirds guides over the preview. Off by default — the resting
  /// viewfinder shows the document boundary and nothing else.
  bool _gridVisible = false;

  /// Shows the white shutter flash for one frame's worth of time after a
  /// capture. Only used when nothing was detected: a capture with a
  /// document on screen is acknowledged by [_captureFillController]
  /// filling that document instead.
  bool _flashing = false;

  /// Drives the capture acknowledgement over [_captureFillQuad]: the
  /// detected page fills with light from its bottom edge upward.
  late final AnimationController _captureFillController;

  /// The boundary the fill animation runs inside — the quad as it was at
  /// the moment of capture, kept after the smoother is reset so the
  /// animation outlives the detection that produced it.
  Quad? _captureFillQuad;

  CameraLensDirection _lensDirection = CameraLensDirection.back;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  // A ValueNotifier rather than a plain field: a pinch updates this dozens
  // of times a second, and driving it through setState would rebuild the
  // whole Scaffold — AppBar, FutureBuilder, CameraPreview and all — on
  // every gesture tick just to repaint one small text label.
  final ValueNotifier<double> _currentZoom = ValueNotifier(1.0);
  bool _isZooming = false; // pauses detection/auto-capture during a drag
  double? _pendingZoomTarget;
  static const _kZoomCallInterval = Duration(milliseconds: 60);
  DateTime _lastZoomCallAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _zoomThrottleTimer;

  Offset? _focusPointNormalized; // null = reticle hidden
  Timer? _focusHideTimer;
  bool _focusSupported = true;
  bool _exposureSupported = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _captureFillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() => _captureFillQuad = null);
        _captureFillController.value = 0;
      });
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
    // Same preference the Settings screen writes — the camera's long-press
    // and the settings row are two doors onto one switch.
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
          _currentZoom.value = _minZoom;
        } catch (e) {
          debugPrint('Could not read zoom range: $e');
          _minZoom = _maxZoom = 1.0;
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
        debugPrint('Camera init failed (attempt $attempt): $e');
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
    // Detection is the heaviest work this screen does per frame, and its
    // result is meaningless mid-pinch anyway (the framing is changing
    // under it). Skipping it frees the CPU for the gesture, which is what
    // makes the zoom feel like it's tracking the fingers.
    if (_isZooming) return;

    final gray = grayscaleFromFrame(
      yPlaneOrBgraBytes: image.planes[0].bytes,
      bytesPerRow: image.planes[0].bytesPerRow,
      width: image.width,
      height: image.height,
      format: image.format.group,
      targetLongEdge: kLiveDetectionMaxDimension,
    );
    if (gray == null) return;
    _updateLowLight(gray);

    final scale = kLiveDetectionMaxDimension /
        (image.width > image.height ? image.width : image.height);
    final w = scale < 1.0 ? (image.width * scale).round() : image.width;
    final h = scale < 1.0 ? (image.height * scale).round() : image.height;
    _liveScanController.submitFrame(gray, w, h);
  }

  /// Averages every 16th sample of the downsampled frame; enough to tell a
  /// dim room from a lit one without walking the whole buffer.
  void _updateLowLight(Uint8List gray) {
    if (gray.isEmpty) return;
    var sum = 0;
    var count = 0;
    for (var i = 0; i < gray.length; i += 16) {
      sum += gray[i];
      count++;
    }
    final mean = sum / count;
    // Hysteresis: without a dead band the banner flickers on and off as
    // the auto-exposure hunts around the threshold.
    final lowLight = _lowLight
        ? mean < _kLowLightThreshold + 8
        : mean < _kLowLightThreshold;
    if (lowLight != _lowLight && mounted) {
      setState(() => _lowLight = lowLight);
    }
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
    _currentZoom.value = 1.0;
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
    // Snapshot the overlay's current quad before anything else: this is
    // the boundary the user is looking at as the shutter fires, and it's
    // what the page gets cropped to in auto mode. Taken up front because
    // the smoother is reset (and the stream stopped) further down.
    //
    // Only for the back camera: `rotateQuadForPortrait` maps sensor space
    // to overlay space for a back camera's fixed 90-degree mount, so the
    // front camera's overlay — mirrored, and mounted the other way — can't
    // be projected back onto its still photo. Those pages keep their null
    // quad and go through the crop screen instead of being cropped to a
    // boundary that doesn't correspond to the photo.
    final quadAtCapture = _lensDirection == CameraLensDirection.back
        ? _quadSmoother.smoothedQuad.value
        : null;
    setState(() {
      _capturing = true;
      // With a page on screen the capture is acknowledged inside that
      // page; the whole-screen blink is the fallback for a shot taken
      // with nothing detected, where there is no shape to fill.
      _captureFillQuad = quadAtCapture;
      _flashing = quadAtCapture == null;
    });
    if (quadAtCapture != null) {
      _captureFillController.forward(from: 0);
    } else {
      // 90ms white flash, per the motion spec — long enough to register as
      // "that was taken", short enough not to hide the next framing.
      Future.delayed(const Duration(milliseconds: 90), () {
        if (mounted) setState(() => _flashing = false);
      });
    }
    try {
      await controller.stopImageStream();
      if (AppSettings.instance.captureSound) {
        // The plugin has no shutter-sound hook, so this is the system's
        // own click — audible confirmation without bundling an asset.
        unawaited(SystemSound.play(SystemSoundType.click));
      }
      final shot = await controller.takePicture();
      _autoCaptureDetector.notifyCaptured();
      // A new document after this one shouldn't inherit the outgoing
      // one's filter velocity/lag.
      _quadSmoother.reset();
      if (!mounted) {
        // Nothing left to process into, but the photo is on disk and the
        // session may still be read by whoever popped this route.
        _capturedFiles.add(LiveCapture(file: File(shot.path), quad: quadAtCapture));
        return;
      }
      // The feed comes back before the page is processed: only the shutter
      // waits on the encode, so the viewfinder is live and detecting again
      // while the last page finishes in the background.
      await controller.startImageStream(_onFrame);
      _capturedFiles.add(await _prepareCapture(File(shot.path), quadAtCapture));
    } catch (e) {
      debugPrint('Capture failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.couldnt_capture)),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  /// Runs the page through the storage pipeline here and now — cropped to
  /// the boundary that was on screen, downscaled and re-encoded at page
  /// size — and stages the result, so adopting it into the document later
  /// is a file move rather than a decode of a multi-megapixel photo.
  ///
  /// This is the work that used to happen for the whole batch after Done,
  /// where a long session meant a long wait at the end with nothing to
  /// look at. Done doing it per capture spends the same total time in the
  /// gaps between shots, which is time the user is already using to frame
  /// the next page.
  ///
  /// A capture that could not be processed — unreadable bytes, a full
  /// disk — is returned raw, with its quad intact, and the document
  /// processes it the way it always did.
  Future<LiveCapture> _prepareCapture(File shot, Quad? quad) async {
    try {
      final dir = _stagingDir ??= await _fileOperations.captureDirectory();
      final written = await _fileOperations.writeCapture(
        source: shot,
        dir: dir.path,
        stamp: DateTime.now().microsecondsSinceEpoch.toString(),
        quad: quad,
        keepOriginal: AppSettings.instance.keepOriginal,
      );
      if (written != null) {
        final original = written.originalPath;
        return LiveCapture(
          file: File(written.pagePath),
          original: original == null ? null : File(original),
          prepared: true,
        );
      }
      debugPrint('Could not process capture ${shot.path}; storing it raw');
    } catch (e) {
      debugPrint('Could not process capture ${shot.path}: $e');
    }
    return LiveCapture(file: shot, quad: quad);
  }

  void _onDonePressed() {
    Navigator.pop(
      context,
      _capturedFiles.isEmpty ? null : List<LiveCapture>.from(_capturedFiles),
    );
  }

  void _onUndoLastPressed() {
    if (_capturedFiles.isEmpty) return;
    setState(() => _capturedFiles.removeLast());
  }

  /// Imports pages from the gallery without leaving the session: picked
  /// images join [_capturedFiles] with no quad, so they go through the crop
  /// screen exactly like a manual shot does.
  Future<void> _onImportPressed() async {
    try {
      final picked = await FileOperations().openGallery();
      if (picked.isEmpty || !mounted) return;
      setState(() {
        for (final file in picked) {
          _capturedFiles.add(LiveCapture(file: file, imported: true));
        }
      });
    } catch (e) {
      debugPrint('Gallery import from camera failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.couldnt_open_gallery)),
      );
    }
  }

  Future<void> _toggleAutoCapture() async {
    setState(() => _autoCaptureEnabled = !_autoCaptureEnabled);
    _autoCaptureDetector.enabled = _autoCaptureEnabled;
    await AppSettings.instance.setAutoCapture(_autoCaptureEnabled);
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null) return;
    final newMode = _torchOn ? FlashMode.off : FlashMode.torch;
    try {
      await controller.setFlashMode(newMode);
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (e) {
      debugPrint('Torch toggle failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.torch_unavailable)),
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
    _currentZoom.value = 1.0;
    _focusPointNormalized = null;
    _focusHideTimer?.cancel();
    _focusSupported = true;
    _exposureSupported = true;

    await _initializeCamera();
  }

  void _onZoomSliderChanged(double value) {
    final controller = _cameraController;
    if (controller == null || _maxZoom <= _minZoom) return;
    final target = value.clamp(_minZoom, _maxZoom);
    // Move the slider thumb and label immediately, without waiting on the
    // camera round-trip below: dragging fires this dozens of times a
    // second, and a thumb that only advances once each setZoomLevel
    // resolves visibly trails the finger.
    _isZooming = true; // plain assignment: nothing in build() reads this
    _currentZoom.value = target;
    // Coalesce the actual hardware calls: only one is ever in flight,
    // always chasing the latest target rather than replaying every
    // intermediate value from a burst of drag updates.
    _requestZoomLevel(controller, target);
  }

  /// Issues zoom changes to the camera on a fixed interval, without
  /// waiting for the previous one to complete.
  ///
  /// Measured on a moto g71 (camera_android_camerax): a single
  /// `setZoomLevel` future takes ~370ms to resolve, because it only
  /// completes once CameraX has actually applied the zoom ratio to a
  /// capture request. Chaining calls — awaiting one before issuing the
  /// next — therefore caps the preview at ~3 zoom steps per second no
  /// matter how fast the slider moves, which is what made dragging feel
  /// so laggy. Superseding an in-flight zoom with a newer ratio is fine:
  /// CameraX cancels the older request (its future completes with an
  /// error we deliberately swallow below) and applies the latest.
  void _requestZoomLevel(CameraController controller, double target) {
    _pendingZoomTarget = target;
    final sinceLast = DateTime.now().difference(_lastZoomCallAt);
    if (sinceLast >= _kZoomCallInterval) {
      _issuePendingZoom(controller);
      return;
    }
    // Too soon — let the already-scheduled flush pick up this newer
    // target, or schedule one for the remainder of the interval.
    _zoomThrottleTimer ??= Timer(_kZoomCallInterval - sinceLast, () {
      _zoomThrottleTimer = null;
      final current = _cameraController;
      if (current != null) _issuePendingZoom(current);
    });
  }

  void _issuePendingZoom(CameraController controller) {
    final target = _pendingZoomTarget;
    if (target == null) return;
    _pendingZoomTarget = null;
    _lastZoomCallAt = DateTime.now();
    // Deliberately not awaited: see _requestZoomLevel's doc comment.
    // A superseded call rejects, which is expected, not an error worth
    // surfacing.
    unawaited(controller.setZoomLevel(target).catchError((_) {}));
  }

  void _onZoomSliderChangeEnd(double value) {
    _isZooming = false;
    // The throttle may have dropped the last few updates of the drag —
    // make sure the camera ends up at exactly where the thumb was
    // released rather than one interval behind it.
    final controller = _cameraController;
    if (controller != null && _pendingZoomTarget != null) {
      _zoomThrottleTimer?.cancel();
      _zoomThrottleTimer = null;
      _issuePendingZoom(controller);
    }
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
      } catch (e) {
        debugPrint('Tap-to-focus unsupported, disabling: $e');
        _focusSupported = false;
      }
    }
    if (_exposureSupported) {
      try {
        await controller.setExposureMode(ExposureMode.auto);
        await controller.setExposurePoint(normalized);
      } catch (e) {
        debugPrint('Tap-to-expose unsupported, disabling: $e');
        _exposureSupported = false;
      }
    }
  }

  @override
  void dispose() {
    _focusHideTimer?.cancel();
    _zoomThrottleTimer?.cancel();
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
    _captureFillController.dispose();
    _currentZoom.dispose();
    _liveScanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: OSColors.chromeBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        // The viewfinder is fixed-dark in both app themes: it is already
        // the darkest, highest-contrast context there is.
        backgroundColor: OSColors.chromeBackground,
        body: _permissionDenied
            ? _permissionDeniedState(accent, onAccent)
            : _cameraError
                ? _buildMessage(l10n.couldnt_start_camera)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // The viewfinder is a bounded box with the controls
                      // laid out around it, rather than one full-bleed
                      // feed with buttons floating on top: nothing the
                      // camera sees ends up underneath a button.
                      SafeArea(
                        child: Column(
                          children: [
                            _topChrome(accent),
                            Expanded(child: _previewBox(accent, onAccent)),
                            _bottomChrome(accent, onAccent),
                          ],
                        ),
                      ),
                      if (_flashing)
                        IgnorePointer(
                          child: Container(
                              color: Colors.white.withValues(alpha: 0.85)),
                        ),
                    ],
                  ),
      ),
    );
  }

  // <========================= Preview =========================>

  /// The viewfinder itself: a rounded, bounded box that owns the feed, the
  /// detection overlay, the status line and the zoom rail — and nothing
  /// else. Every button lives outside it.
  Widget _previewBox(Color accent, Color onAccent) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: OSSpace.md, vertical: OSSpace.xs),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OSRadius.card),
        child: Container(
          color: const Color(0xFF0A0908),
          child: _preview(accent, onAccent),
        ),
      ),
    );
  }

  Widget _preview(Color accent, Color onAccent) {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        final controller = _cameraController;
        if (controller == null || !controller.value.isInitialized) {
          return Center(child: CircularProgressIndicator(color: accent));
        }
        // CameraPreview lays itself out in its own internal AspectRatio +
        // (on Android) RotatedBox for the device's current orientation, and
        // offers a `child` slot sized identically to the rotated preview
        // texture — so an overlay passed there sits in exactly the
        // "portrait" coordinate space rotateQuadForPortrait's normalized
        // output already targets, with no separate rotation here.
        // Everything that has to line up with what the camera sees — the
        // quad, the focus reticle, tap-to-focus coordinates — lives inside
        // CameraPreview's child slot, which is sized to the preview
        // texture itself. Inside a letterboxing box that is no longer the
        // same rectangle as the box, so measuring against the box would
        // put the reticle where the user didn't tap.
        return Center(
          child: CameraPreview(
            controller,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _onTapToFocus(details, size),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_gridVisible)
                        IgnorePointer(
                          child: CustomPaint(
                              painter: const _ThirdsGridPainter()),
                        ),
                      ValueListenableBuilder(
                        valueListenable: _quadSmoother.smoothedQuad,
                        builder: (context, quad, _) => quad == null
                            ? const SizedBox.shrink()
                            : LiveQuadOverlay(
                                quad: quad,
                                size: size,
                                accent: accent,
                                isImminent: _autoCaptureImminent,
                              ),
                      ),
                      if (_captureFillQuad != null)
                        IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _captureFillController,
                            builder: (context, _) => CustomPaint(
                              size: size,
                              painter: CaptureFillPainter(
                                points: _captureFillQuad!.points
                                    .map((p) => Offset(
                                        p.x * size.width, p.y * size.height))
                                    .toList(),
                                progress: _captureFillController.value,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      if (_focusPointNormalized != null)
                        Positioned(
                          left: _focusPointNormalized!.dx * size.width - 32,
                          top: _focusPointNormalized!.dy * size.height - 32,
                          child: IgnorePointer(
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(_focusPointNormalized),
                              tween: Tween(begin: 1.4, end: 1.0),
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              builder: (context, scale, child) =>
                                  Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: (2.0 - scale).clamp(0.0, 1.0),
                                  child: child,
                                ),
                              ),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: accent, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      _statusOverlay(accent, onAccent),
                      if (_maxZoom > _minZoom) _zoomSlider(),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // <========================= Chrome =========================>

  /// Every camera control on one row above the viewfinder: torch, the
  /// auto-capture toggle, the composition grid, the lens switch, and undo
  /// once there is something to undo. Nothing hides behind a caret — the
  /// row is short enough to show all of it at once.
  Widget _topChrome(Color accent) {
    final l10n = AppLocalizations.of(context)!;
    final canTorch = _cameraController != null &&
        _lensDirection == CameraLensDirection.back;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: OSSpace.md, vertical: OSSpace.xs),
      child: Row(
        children: [
          _ChromeButton(
            icon: _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            tooltip: _torchOn ? l10n.torch_on : l10n.torch_off,
            // The torch is the fix for the low-light warning, so it
            // adopts the warning colour while that banner is up.
            highlight: _torchOn || _lowLight,
            highlightColor: _lowLight && !_torchOn ? context.os.warning : null,
            onPressed: canTorch ? _toggleTorch : null,
          ),
          const SizedBox(width: OSSpace.xs),
          _ChromeButton(
            icon: Icons.auto_awesome_rounded,
            tooltip: _autoCaptureEnabled
                ? l10n.auto_capture_on
                : l10n.auto_capture_off,
            highlight: _autoCaptureEnabled,
            onPressed: _toggleAutoCapture,
          ),
          const Spacer(),
          if (_capturedFiles.isNotEmpty) ...[
            _ChromeButton(
              icon: Icons.undo_rounded,
              tooltip: l10n.undo_last_capture,
              onPressed: _onUndoLastPressed,
            ),
            const SizedBox(width: OSSpace.xs),
          ],
          _ChromeButton(
            icon: Icons.grid_3x3_rounded,
            tooltip: l10n.composition_grid,
            highlight: _gridVisible,
            onPressed: () => setState(() => _gridVisible = !_gridVisible),
          ),
          const SizedBox(width: OSSpace.xs),
          _ChromeButton(
            icon: Icons.cameraswitch_rounded,
            tooltip: l10n.switch_camera,
            onPressed: (_cameraController != null && Globals.cameras.length > 1)
                ? _switchCamera
                : null,
          ),
        ],
      ),
    );
  }

  /// The detection state, spelled out in words as well as colour: the quad
  /// turning accent is never the only signal that a page was found.
  Widget _statusOverlay(Color accent, Color onAccent) {
    final l10n = AppLocalizations.of(context)!;
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.only(top: OSSpace.sm),
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_lowLight)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: OSSpace.md),
                  padding: const EdgeInsets.symmetric(
                      horizontal: OSSpace.sm, vertical: OSSpace.xs),
                  decoration: BoxDecoration(
                    color: context.os.warning.withValues(alpha: 0.16),
                    border: Border.all(color: context.os.warning),
                    borderRadius: BorderRadius.circular(OSRadius.card),
                  ),
                  child: Text(
                    l10n.low_light,
                    style: OSTypography.caption.copyWith(
                      color: context.os.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: OSSpace.xs),
              ValueListenableBuilder(
                valueListenable: _quadSmoother.smoothedQuad,
                builder: (context, quad, _) {
                  if (quad == null) {
                    return Text(
                      l10n.looking_for_document,
                      style: OSTypography.caption.copyWith(
                        color: OSColors.chromeOnBackground,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Color(0x990A0908)),
                        ],
                      ),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: OSSpace.sm, vertical: OSSpace.xxs + 2),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(OSRadius.sheet),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 14, color: onAccent),
                        const SizedBox(width: OSSpace.xxs + 1),
                        Text(
                          l10n.document_detected,
                          style: OSTypography.caption.copyWith(
                            color: onAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The one row of controls under the viewfinder: gallery, shutter and
  /// done, all on the same centre line and evenly spaced, with the
  /// auto-capture state spelled out above them.
  Widget _bottomChrome(Color accent, Color onAccent) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: OSSpace.md, vertical: OSSpace.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _autoCaptureImminent
                ? l10n.hold_still
                : _autoCaptureEnabled
                    ? l10n.auto_on
                    : l10n.auto_off,
            style: OSTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: _autoCaptureImminent
                  ? OSColors.chromeOnBackground
                  : _autoCaptureEnabled
                      ? accent
                      : OSColors.chromeMuted,
            ),
          ),
          const SizedBox(height: OSSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ChromeButton(
                icon: Icons.photo_library_rounded,
                tooltip: l10n.import_from_gallery_short,
                size: _kSideControlSize,
                iconSize: 30,
                onPressed: _onImportPressed,
              ),
              _shutter(accent),
              _doneButton(accent, onAccent),
            ],
          ),
        ],
      ),
    );
  }

  /// The session's exit, carrying its page count: nothing captured yet
  /// means nothing to finish, so it sits inert rather than disappearing
  /// and shifting the row around the shutter. Sized to match the gallery
  /// button on the other side of the shutter.
  Widget _doneButton(Color accent, Color onAccent) {
    final l10n = AppLocalizations.of(context)!;
    final count = _capturedFiles.length;
    // Inert while a page is still being processed: the shot in flight is
    // not in the list yet, and leaving on it would drop it.
    final enabled = count > 0 && !_capturing;
    final ink = enabled ? onAccent : OSColors.chromeMuted;
    return Material(
      color: enabled ? accent : OSColors.chromeScrim,
      borderRadius: BorderRadius.circular(OSRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? _onDonePressed : null,
        child: SizedBox(
          height: _kSideControlSize,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: OSSpace.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  enabled ? l10n.done_count(count) : l10n.done,
                  style: OSTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(width: OSSpace.xxs),
                Icon(Icons.check_rounded, size: 20, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The shutter. Its ring is the auto-capture state: accent when a page is
  /// locked, pulsing when a capture is about to fire on its own.
  Widget _shutter(Color accent) {
    if (_capturing) {
      return SizedBox(
        height: 70,
        width: 70,
        child: Center(
          child: CircularProgressIndicator(color: accent),
        ),
      );
    }

    final locked = _quadSmoother.smoothedQuad.value != null;
    return GestureDetector(
      onLongPress: _toggleAutoCapture,
      child: SizedBox(
        height: 70,
        width: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_autoCaptureImminent)
              _PulseRing(color: accent),
            GestureDetector(
              onTap: _cameraController != null ? _onCapturePressed : null,
              child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: locked
                        ? accent
                        : Colors.white.withValues(alpha: 0.35),
                    width: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A vertical rail down the right edge of the viewfinder: up is closer.
  /// Compact on purpose — it sits over the feed, so it takes a strip
  /// rather than a whole row.
  Widget _zoomSlider() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: OSSpace.xs, vertical: OSSpace.md),
        // Absorb taps so a miss on the slider track isn't read as a
        // tap-to-focus by the preview's GestureDetector below.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: OSSpace.xs),
            decoration: BoxDecoration(
              color: OSColors.chromeScrim,
              borderRadius: BorderRadius.circular(OSRadius.pill),
            ),
            child: ValueListenableBuilder<double>(
              valueListenable: _currentZoom,
              builder: (context, zoom, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 160,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 12),
                          thumbShape:
                              const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          min: _minZoom,
                          max: _maxZoom,
                          value: zoom.clamp(_minZoom, _maxZoom),
                          onChanged: _onZoomSliderChanged,
                          onChangeEnd: _onZoomSliderChangeEnd,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${zoom.toStringAsFixed(1)}x',
                    style: OSTypography.caption
                        .copyWith(color: OSColors.chromeOnBackground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Explains what the camera is for before asking again — the permission
  /// prompt itself has no room for the "nothing leaves your device" half.
  Widget _permissionDeniedState(Color accent, Color onAccent) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OSSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF221E18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.no_photography_rounded,
                  color: OSColors.chromeMuted),
            ),
            const SizedBox(height: OSSpace.md),
            Text(l10n.camera_access_needed,
                style: OSTypography.subtitle
                    .copyWith(color: OSColors.chromeOnBackground)),
            const SizedBox(height: OSSpace.xs),
            Text(
              l10n.camera_access_body,
              textAlign: TextAlign.center,
              style:
                  OSTypography.body.copyWith(color: OSColors.chromeMuted),
            ),
            const SizedBox(height: OSSpace.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: onAccent,
              ),
              onPressed: openAppSettings,
              child: Text(l10n.open_settings),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(l10n.not_now,
                  style: OSTypography.label
                      .copyWith(color: OSColors.chromeMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OSSpace.xl),
        child: Text(
          message,
          style: OSTypography.body.copyWith(color: OSColors.chromeOnBackground),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// A round translucent control button, the camera's one button shape.
class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.highlight = false,
    this.highlightColor,
    this.size = 48,
    this.iconSize = 26,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool highlight;
  final Color? highlightColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final active = highlightColor ?? Theme.of(context).colorScheme.primary;
    final enabled = onPressed != null;
    final button = Material(
      color: highlight ? active : OSColors.chromeScrim,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: size,
          width: size,
          child: Icon(
            icon,
            size: iconSize,
            color: highlight
                ? Theme.of(context).colorScheme.onPrimary
                : enabled
                    ? OSColors.chromeOnBackground
                    : OSColors.chromeMuted,
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// The 900ms ring that expands out of the shutter while an auto-capture is
/// about to fire — the "something is about to happen" cue that pairs with
/// the HOLD STILL label.
class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.color});

  final Color color;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Transform.scale(
          scale: 0.9 + t * 0.45,
          child: Opacity(
            opacity: (1 - t / 0.7).clamp(0.0, 0.9),
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 3),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Rule-of-thirds guides, drawn hairline-thin so they never compete with
/// the detected document boundary.
class _ThirdsGridPainter extends CustomPainter {
  const _ThirdsGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final dx = size.width * i / 3;
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThirdsGridPainter oldDelegate) => false;
}
