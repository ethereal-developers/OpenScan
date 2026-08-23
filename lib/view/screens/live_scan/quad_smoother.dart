import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:openscan/core/cv/contours.dart';
import 'package:openscan/core/cv/models/point.dart';
import 'package:openscan/core/cv/models/quad.dart';

/// Diagonal of the normalized [0,1] coordinate space every `Quad` in this
/// pipeline lives in (post `rotateQuadForPortrait`), used to express
/// corner-distance thresholds below as frame-relative fractions rather
/// than raw units.
const double _kNormalizedSpaceDiagonal = 1.4142135623730951; // sqrt(2)

/// Smooths a noisy stream of per-frame detected quads (see
/// `LiveScanController.latestQuad`) into a stable signal suitable for
/// painting and for driving `AutoCaptureDetector`, without meaningfully
/// lagging behind a document that's actually being moved. Pure logic, no
/// Flutter/camera/isolate dependency beyond `ValueNotifier`, so it's
/// testable with synthetic quad sequences and a fake clock exactly like
/// `AutoCaptureDetector`.
///
/// The live detection pipeline (`lib/core/cv/`) re-derives its result
/// completely independently every frame — fresh per-frame threshold sweep,
/// fresh connected-component search, fresh RDP polygon simplification —
/// with no memory of the previous frame. Two distinct kinds of instability
/// fall out of that:
///
/// 1. Small positional noise around the true document edge, even when it's
///    held perfectly still (sensor/aliasing noise, RDP epsilon jitter).
///    Handled below by a per-corner One Euro Filter (see [_OneEuroFilter]).
/// 2. Occasional outright *different* detections — a different connected
///    component or threshold-sweep candidate scoring marginally better for
///    one frame (background clutter, a shadow, a texture) — which no
///    amount of positional smoothing fixes, since it isn't noise around a
///    fixed point, it's a jump to a different shape entirely. Handled by
///    the lock/confirmation gate below: consecutive raw samples are
///    compared to each other (not to the filtered/lagged output), and a
///    sample landing far from the last-accepted raw sample is held as a
///    *pending* candidate — invisible to the displayed output — until it's
///    been seen [kJumpConfirmFrameCount] times in a row. A single
///    conflicting frame never reaches the screen at all, exactly like the
///    reference app's auto-scan tracker requiring a tracked shape to
///    persist before acting on it.
class QuadSmoother {
  /// Baseline low-pass cutoff frequency (Hz) used when the signal is
  /// essentially stationary — lower means more smoothing at rest. Starting
  /// point for on-device tuning, same convention as
  /// `AutoCaptureDetector`'s threshold constants.
  static const double kMinCutoffHz = 0.5;

  /// How much the cutoff frequency increases per unit of estimated corner
  /// speed (normalized [0,1] units/second) — higher means the filter
  /// "opens up" and tracks a fast, deliberate move more closely instead of
  /// smoothing it into a lag.
  static const double kBeta = 0.5;

  /// Cutoff frequency (Hz) used to smooth the derivative estimate itself,
  /// per the One Euro Filter's standard two-stage design.
  static const double kDerivativeCutoffHz = 1.0;

  /// How long a null (no detection) raw sample is tolerated before the
  /// smoothed quad is actually cleared. A single momentary miss (motion
  /// blur, a hand briefly crossing the frame) shouldn't flicker the
  /// overlay away or reset `AutoCaptureDetector`'s stability window.
  static const Duration kNullGracePeriod = Duration(milliseconds: 500);

  /// Average per-corner distance (as a fraction of the normalized space's
  /// diagonal) between two *consecutive raw* detections beyond which the
  /// newer one is treated as a different document/contour rather than
  /// continued tracking of the same one. Deliberately compared raw-to-raw,
  /// not raw-to-displayed-output, so filter lag during a genuinely fast
  /// move can never itself be mistaken for a jump.
  static const double kJumpDistanceFraction = 0.12;

  /// How many consecutive raw samples landing within
  /// [kJumpDistanceFraction] of *each other* (not of the previously
  /// accepted track) are required before a far-away detection replaces
  /// what's displayed. This is what makes a single conflicting frame
  /// invisible to the output — only a detection that keeps recurring gets
  /// treated as real.
  static const int kJumpConfirmFrameCount = 3;

  final DateTime Function() _now;

  QuadSmoother({DateTime Function() now = DateTime.now}) : _now = now;

  final ValueNotifier<Quad?> _smoothedQuad = ValueNotifier(null);
  ValueListenable<Quad?> get smoothedQuad => _smoothedQuad;

  // One filter per corner scalar, in [tl.x, tl.y, tr.x, tr.y, br.x, br.y,
  // bl.x, bl.y] order. Null whenever there's no active track.
  List<_OneEuroFilter>? _filters;
  DateTime? _lastSampleAt;
  DateTime? _lastSeenAt;

  // The last raw sample accepted as "the same document" — the reference
  // point for both corner-label correspondence and the jump distance
  // check on the next sample. Deliberately the raw input, not the
  // filtered/lagged smoothedQuad, so filter lag can't masquerade as a
  // jump (see kJumpDistanceFraction's doc comment).
  Quad? _lastRawQuad;

  // A far-from-_lastRawQuad candidate accumulating consecutive matching
  // samples before it's allowed to replace the current track.
  Quad? _pendingQuad;
  int _pendingStreak = 0;

  /// Feed each new raw detection as it arrives, including nulls (frames
  /// where nothing was detected).
  void onRawQuad(Quad? raw) {
    final now = _now();

    if (raw == null) {
      if (_lastSeenAt != null &&
          now.difference(_lastSeenAt!) <= kNullGracePeriod) {
        // Within the grace period: leave the smoothed value exactly as it
        // was — not just unchanged in value, but the same instance — so
        // ValueNotifier doesn't even notify listeners for this frame.
        return;
      }
      _reset();
      return;
    }

    _lastSeenAt = now;

    final lastRaw = _lastRawQuad;
    if (lastRaw == null) {
      // No active track: nothing to compare against yet, so this raw
      // sample immediately becomes the track. Applies both to the very
      // first sample and to the first sample after a reset — in both
      // cases we'd rather show something than wait out a confirmation
      // window with a blank overlay.
      _pendingQuad = null;
      _pendingStreak = 0;
      _lastRawQuad = raw;
      _seedTrack(raw, now);
      return;
    }

    final matchToTrack = bestCornerAssignment(raw.points, lastRaw);
    final trackDist = _asFraction(matchToTrack.totalDistance);
    if (trackDist < kJumpDistanceFraction) {
      // Same document as what's currently tracked — feed it into the
      // position filters as normal continued tracking.
      _pendingQuad = null;
      _pendingStreak = 0;
      _lastRawQuad = matchToTrack.quad;
      _trackContinued(matchToTrack.quad, now);
      return;
    }

    // Conflicts with the current track. Only accept it once it's recurred
    // kJumpConfirmFrameCount times in a row against itself — a one-off
    // wrong detection never reaches the displayed output at all.
    final pending = _pendingQuad;
    if (pending != null) {
      final matchToPending = bestCornerAssignment(raw.points, pending);
      if (_asFraction(matchToPending.totalDistance) < kJumpDistanceFraction) {
        _pendingQuad = matchToPending.quad;
        _pendingStreak++;
      } else {
        _pendingQuad = raw;
        _pendingStreak = 1;
      }
    } else {
      _pendingQuad = raw;
      _pendingStreak = 1;
    }

    if (_pendingStreak >= kJumpConfirmFrameCount) {
      // Confirmed: this is a genuinely different document, not noise —
      // switch the track to it fresh (no easing from the old position).
      final confirmed = _pendingQuad!;
      _pendingQuad = null;
      _pendingStreak = 0;
      _lastRawQuad = confirmed;
      _seedTrack(confirmed, now);
    }
    // Otherwise: leave the currently-displayed smoothedQuad untouched
    // while this candidate is still unconfirmed.
  }

  /// Clears all filter/track state and publishes null. Called after a
  /// capture so a new document doesn't inherit the outgoing one's filter
  /// velocity/lag or track position.
  void reset() => _reset();

  double _asFraction(double totalCornerDistance) =>
      (totalCornerDistance / 4) / _kNormalizedSpaceDiagonal;

  void _seedTrack(Quad raw, DateTime now) {
    final filters = List.generate(
      8,
      (_) => _OneEuroFilter(
        minCutoffHz: kMinCutoffHz,
        beta: kBeta,
        derivativeCutoffHz: kDerivativeCutoffHz,
      ),
    );
    final scalars = _scalarsOf(raw);
    for (int i = 0; i < 8; i++) {
      filters[i].seed(scalars[i]);
    }
    _filters = filters;
    _lastSampleAt = now;
    _smoothedQuad.value = raw;
  }

  void _trackContinued(Quad corresponded, DateTime now) {
    final dtSeconds = max(
      now.difference(_lastSampleAt!).inMicroseconds / 1e6,
      0.001,
    );
    _lastSampleAt = now;

    final rawScalars = _scalarsOf(corresponded);
    final filters = _filters!;
    final smoothedScalars = List<double>.generate(
      8,
      (i) => filters[i].filter(rawScalars[i], dtSeconds),
    );
    _smoothedQuad.value = _quadFromScalars(smoothedScalars);
  }

  void _reset() {
    _filters = null;
    _lastSampleAt = null;
    _lastSeenAt = null;
    _lastRawQuad = null;
    _pendingQuad = null;
    _pendingStreak = 0;
    _smoothedQuad.value = null;
  }

  List<double> _scalarsOf(Quad q) => [
        q.topLeft.x, q.topLeft.y,
        q.topRight.x, q.topRight.y,
        q.bottomRight.x, q.bottomRight.y,
        q.bottomLeft.x, q.bottomLeft.y,
      ];

  Quad _quadFromScalars(List<double> s) => Quad(
        topLeft: Pt(s[0], s[1]),
        topRight: Pt(s[2], s[3]),
        bottomRight: Pt(s[4], s[5]),
        bottomLeft: Pt(s[6], s[7]),
      );
}

/// A single-scalar One Euro Filter (Casiez, Roussel & Vogel, 2012): an
/// adaptive low-pass filter whose cutoff frequency increases with the
/// estimated speed of the signal, so it smooths heavily when the value is
/// near-stationary (killing noise) and tracks closely when it's moving
/// fast (avoiding lag). `dt` is the actual elapsed time since the previous
/// sample, in seconds, rather than an assumed fixed rate — needed here
/// since the live pipeline's effective sample rate is irregular (frame
/// throttling + isolate round-trip latency both vary).
class _OneEuroFilter {
  final double minCutoffHz;
  final double beta;
  final double derivativeCutoffHz;

  _OneEuroFilter({
    required this.minCutoffHz,
    required this.beta,
    required this.derivativeCutoffHz,
  });

  double? _xPrev;
  double _dxPrev = 0;

  void seed(double x) {
    _xPrev = x;
    _dxPrev = 0;
  }

  double filter(double x, double dt) {
    final xPrev = _xPrev;
    if (xPrev == null) {
      seed(x);
      return x;
    }

    final dx = (x - xPrev) / dt;
    final alphaD = _alpha(derivativeCutoffHz, dt);
    final dxHat = alphaD * dx + (1 - alphaD) * _dxPrev;

    final cutoff = minCutoffHz + beta * dxHat.abs();
    final alpha = _alpha(cutoff, dt);
    final xHat = alpha * x + (1 - alpha) * xPrev;

    _xPrev = xHat;
    _dxPrev = dxHat;
    return xHat;
  }

  double _alpha(double cutoffHz, double dt) {
    final tau = 1 / (2 * pi * cutoffHz);
    return 1 / (1 + tau / dt);
  }
}
