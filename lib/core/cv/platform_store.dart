import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models/point.dart';
import 'models/quad.dart';

const _channel = MethodChannel('openscan/capture_store');

/// One file to write from a photo: the part of it inside [corners] —
/// fractions of the photo the right way up, TL, TR, BR, BL — warped into
/// a [width] x [height] rectangle and encoded as a JPEG at [quality].
/// A kept original is the whole frame ([PlatformOutput.wholeFrame]).
class PlatformOutput {
  final String dest;
  final Quad corners;
  final int width;
  final int height;
  final int quality;

  const PlatformOutput({
    required this.dest,
    required this.corners,
    required this.width,
    required this.height,
    required this.quality,
  });

  static const Quad wholeFrame = Quad(
    topLeft: Pt(0, 0),
    topRight: Pt(1, 0),
    bottomRight: Pt(1, 1),
    bottomLeft: Pt(0, 1),
  );

  Map<String, Object> toMap() => {
        'dest': dest,
        'corners': [for (final p in corners.points) ...[p.x, p.y]],
        'width': width,
        'height': height,
        'quality': quality,
      };
}

/// Writes [outputs] from the photo at [src] with the platform's own image
/// code (see `CaptureStore.java`): a native decode, warp and JPEG encode,
/// a fraction of a second where the pure-Dart pipeline takes many seconds
/// on a full-resolution capture. [quarterTurns] turns every output
/// clockwise after the warp.
///
/// Returns false — having written nothing the caller should keep — when
/// the platform can't do it: not Android, an orientation it doesn't
/// handle, a decode that ran out of memory. The caller then goes the
/// Dart way, which is slower but handles everything.
Future<bool> storeOnPlatform({
  required String src,
  required List<PlatformOutput> outputs,
  int quarterTurns = 0,
}) async {
  if (!Platform.isAndroid || outputs.isEmpty) return false;
  try {
    final written = await _channel.invokeMapMethod<String, bool>('store', {
      'src': src,
      'quarterTurns': quarterTurns,
      'outputs': [for (final o in outputs) o.toMap()],
    });
    return written != null && outputs.every((o) => written[o.dest] == true);
  } on PlatformException catch (e) {
    debugPrint('Native store failed for $src, falling back: ${e.message}');
  } on MissingPluginException {
    // Tests, or an engine without the channel registered.
  }
  for (final o in outputs) {
    // Never the photo itself: the Dart fallback still has to read it.
    if (o.dest == src) continue;
    final file = File(o.dest);
    if (file.existsSync()) file.deleteSync();
  }
  return false;
}

/// [width] x [height] scaled down to fit [maxEdge] on its long side, never
/// up.
({int width, int height}) fitWithin(int width, int height, int maxEdge) {
  final longest = max(width, height);
  if (maxEdge <= 0 || longest <= maxEdge) {
    return (width: width, height: height);
  }
  final scale = maxEdge / longest;
  return (
    width: max(1, (width * scale).round()),
    height: max(1, (height * scale).round()),
  );
}
