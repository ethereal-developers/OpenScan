import 'dart:io';

import 'package:image/image.dart' as img;

/// Entry point designed to be run via `compute()`. Re-encodes the JPEG at
/// `params['src']` at `params['quality']` and writes it to a new file
/// under `params['dest']`, mirroring the old native `compress` channel
/// method (including its `<dest>/<timestamp>.jpg` naming).
Future<String> compressImageIsolateEntry(Map<String, dynamic> params) async {
  final String src = params['src'] as String;
  final String dest = params['dest'] as String;
  final int quality = params['quality'] as int;

  final bytes = await File(src).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Could not decode image: $src');
  }

  final jpg = img.encodeJpg(decoded, quality: quality);
  final outPath = '$dest/${DateTime.now().millisecondsSinceEpoch}.jpg';
  await File(outPath).writeAsBytes(jpg, flush: true);
  return outPath;
}

/// Long edge, in pixels, a stored page is capped at. 2400px is ~200 DPI
/// across an A4 page — the resolution document scanners settle on, and
/// past which a photo of paper carries no more readable detail, only
/// bytes. Kept originals get a looser cap since they exist to be
/// re-cropped down.
const int kStoredPageMaxEdge = 2400;
const int kStoredPageQuality = 85;
const int kStoredOriginalMaxEdge = 3200;
const int kStoredOriginalQuality = 80;

/// Entry point designed to be run via `compute()`. Downscales the image at
/// `params['src']` so its long edge is at most `params['maxEdge']`,
/// re-encodes it as JPEG at `params['quality']`, and writes it to
/// `params['dest']`.
///
/// A capture straight off the camera — and especially a photo picked from
/// the gallery — is far larger than a page of text needs: normalizing on
/// the way into storage is what keeps a document in the hundreds of KB
/// rather than the tens of MB.
Future<void> normalizeImageIsolateEntry(Map<String, dynamic> params) async {
  final String src = params['src'] as String;
  final String dest = params['dest'] as String;
  final int maxEdge = params['maxEdge'] as int;
  final int quality = params['quality'] as int;

  final bytes = await File(src).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Could not decode image: $src');
  }

  final longEdge =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  final resized = longEdge > maxEdge
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxEdge : null,
          height: decoded.height > decoded.width ? maxEdge : null,
          interpolation: img.Interpolation.average,
        )
      : decoded;

  await File(dest).writeAsBytes(img.encodeJpg(resized, quality: quality),
      flush: true);
}

/// Entry point designed to be run via `compute()`. Encodes one already
/// decoded-from-disk image at several JPEG qualities (and optionally PNG)
/// and reports what each one weighs, so an export can quote a measured
/// size instead of a guess.
///
/// Returns bytes keyed by `'jpg:<quality>'` and `'png'`, plus `'source'`
/// for the file it measured.
Future<Map<String, int>> measureEncodedSizesIsolateEntry(
    Map<String, dynamic> params) async {
  final String src = params['src'] as String;
  final List<int> qualities = List<int>.from(params['qualities'] as List);
  final bool includePng = params['includePng'] as bool? ?? false;

  final file = File(src);
  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Could not decode image: $src');
  }

  final sizes = <String, int>{'source': bytes.length};
  for (final quality in qualities) {
    sizes['jpg:$quality'] = img.encodeJpg(decoded, quality: quality).length;
  }
  if (includePng) {
    sizes['png'] = img.encodePng(decoded).length;
  }
  return sizes;
}
