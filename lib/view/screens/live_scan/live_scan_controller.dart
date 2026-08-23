import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:openscan/core/cv/contours.dart';
import 'package:openscan/core/cv/document_detector.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';

class _FrameRequest {
  final int requestId;
  final Uint8List gray;
  final int width;
  final int height;

  const _FrameRequest(this.requestId, this.gray, this.width, this.height);
}

class _FrameResult {
  final int requestId;
  final Quad? quad;

  const _FrameResult(this.requestId, this.quad);
}

/// Worker isolate entry point. Runs the same pure detection pipeline as
/// the one-shot file-based detector (`detectQuadFromGrayscale`), just fed
/// pre-downsampled grayscale frames instead of a decoded photo.
void _liveDetectionIsolateEntry(SendPort mainSendPort) {
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);
  workerReceivePort.listen((message) {
    final req = message as _FrameRequest;
    final quad = detectQuadFromGrayscale(req.gray, req.width, req.height);
    mainSendPort.send(_FrameResult(req.requestId, quad));
  });
}

/// Owns a persistent worker isolate for the lifetime of a live-scan
/// session, so per-frame detection doesn't pay isolate-spawn overhead
/// (unlike `compute()`, which is a fresh isolate per call — fine for the
/// one-shot crop-screen detection, too slow for a live camera stream).
///
/// Frames are submitted already grayscale+downsampled (by
/// `grayscaleFromFrame` in `frame_adapter.dart`, run on the main isolate
/// so only a small buffer crosses the isolate boundary) and already in
/// sensor-native (landscape) coordinates; [latestQuad] publishes results
/// rotated into portrait "overlay space" via [rotateQuadForPortrait].
class LiveScanController {
  Isolate? _isolate;
  SendPort? _workerSendPort;
  ReceivePort? _mainReceivePort;
  StreamSubscription? _subscription;
  Completer<void>? _handshake;

  int _nextRequestId = 0;
  int _lastHandledRequestId = -1;
  bool _isDetecting = false;

  /// Latest detected quad, rotated into portrait orientation and
  /// normalized to fractional [0,1] coordinates (see
  /// [rotateQuadForPortrait]) — multiply by a preview widget's rendered
  /// size to get on-screen offsets. Null if nothing was detected in the
  /// most recent processed frame.
  final ValueNotifier<Quad?> latestQuad = ValueNotifier(null);

  /// Round-trip latency (submitFrame -> result received) of the most
  /// recently completed detection, in milliseconds. Only one frame is
  /// ever in flight at a time (submitFrame no-ops while `isBusy`), so a
  /// single stopwatch is enough to time it. Exists to make the live-scan
  /// pipeline's real-world per-frame cost directly observable — e.g. for
  /// the p50-latency profiling check described in the project's
  /// implementation plan — without needing external instrumentation.
  final ValueNotifier<int?> lastLatencyMs = ValueNotifier(null);
  final Stopwatch _frameStopwatch = Stopwatch();

  /// Sensor-native dimensions of the frames currently being submitted,
  /// needed to rotate quad points into portrait space. Set on the first
  /// call to [submitFrame] and assumed constant for the session.
  int? _frameWidth;
  int? _frameHeight;

  bool get isBusy => _isDetecting;

  Future<void> start() async {
    _mainReceivePort = ReceivePort();
    _handshake = Completer<void>();
    _isolate = await Isolate.spawn(
      _liveDetectionIsolateEntry,
      _mainReceivePort!.sendPort,
    );
    _subscription = _mainReceivePort!.listen(_onMessage);
    await _handshake!.future;
  }

  void _onMessage(dynamic message) {
    if (message is SendPort) {
      _workerSendPort = message;
      _handshake?.complete();
      return;
    }
    if (message is _FrameResult) {
      _isDetecting = false;
      _frameStopwatch.stop();
      lastLatencyMs.value = _frameStopwatch.elapsedMilliseconds;
      if (message.requestId < _lastHandledRequestId) return;
      _lastHandledRequestId = message.requestId;
      final quad = message.quad;
      latestQuad.value = quad == null
          ? null
          : rotateQuadForPortrait(quad, _frameWidth!, _frameHeight!);
    }
  }

  /// Submits a pre-downsampled grayscale frame for detection. No-ops if a
  /// previous frame is still being processed, so the worker's mailbox
  /// never backs up under load — callers should also throttle how often
  /// this is called (e.g. every 3rd camera frame).
  void submitFrame(Uint8List gray, int width, int height) {
    final port = _workerSendPort;
    if (port == null || _isDetecting) return;
    _frameWidth = width;
    _frameHeight = height;
    _isDetecting = true;
    _frameStopwatch
      ..reset()
      ..start();
    port.send(_FrameRequest(_nextRequestId++, gray, width, height));
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _mainReceivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _workerSendPort = null;
  }
}

/// Rotates a quad detected on a sensor-native (landscape-shaped, w > h)
/// buffer into portrait "overlay space", matching a back camera's fixed
/// 90-degree sensor mount in portrait orientation, and normalizes the
/// result to fractional [0,1] coordinates so callers can map it onto any
/// preview widget box just by multiplying by that box's size — no need
/// to plumb frame dimensions out to the UI layer.
///
/// This is point rotation, not pixel-buffer rotation — much cheaper per
/// frame. v1 scope is portrait + back-camera only, so this is a fixed
/// 90-degree rotation rather than derived from live device orientation.
@visibleForTesting
Quad rotateQuadForPortrait(Quad quad, int frameWidth, int frameHeight) {
  Pt rotate(Pt p) => Pt(frameHeight - p.y, p.x);
  // Rotating the sensor-space corners doesn't preserve which corner is
  // visually top-left in portrait space, so re-derive the canonical
  // corner order from the rotated points via the same sum/diff sort used
  // everywhere else in the app, instead of assuming positional
  // correspondence with the pre-rotation quad.
  final rotated = sortCorners(quad.points.map(rotate).toList());
  return rotated.scaled(1 / frameHeight, 1 / frameWidth);
}
