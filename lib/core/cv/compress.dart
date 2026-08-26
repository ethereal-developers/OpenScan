import 'dart:io';

import 'package:image/image.dart' as img;

/// Entry point designed to be run via `compute()`. Re-encodes the JPEG at
/// `params['src']` at `params['quality']` and writes it to a new file
/// under `params['dest']`, mirroring the old native `compress` channel
/// method (including its `<dest>/<timestamp>.jpg` naming).
/// An optional `params['maxEdge']` caps the long edge first: an export
/// preset gets small by shedding pixels as well as JPEG quality, and past
/// a point the pixels are where the bytes actually are.
Future<String> compressImageIsolateEntry(Map<String, dynamic> params) async {
  final String src = params['src'] as String;
  final String dest = params['dest'] as String;
  final int quality = params['quality'] as int;
  final int? maxEdge = params['maxEdge'] as int?;

  final bytes = await File(src).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Could not decode image: $src');
  }

  final jpg = img.encodeJpg(fitToMaxEdge(decoded, maxEdge), quality: quality);
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

  await File(dest).writeAsBytes(
      img.encodeJpg(fitToMaxEdge(decoded, maxEdge), quality: quality),
      flush: true);
}

/// [image] scaled down so its long edge is at most [maxEdge], or [image]
/// itself when it already fits or [maxEdge] is null. Never enlarges: a
/// page smaller than the cap is left as it is rather than interpolated up
/// to a size it has no detail for.
img.Image fitToMaxEdge(img.Image image, int? maxEdge) {
  if (maxEdge == null) return image;
  final longEdge = image.width > image.height ? image.width : image.height;
  if (longEdge <= maxEdge) return image;
  return img.copyResize(
    image,
    width: image.width >= image.height ? maxEdge : null,
    height: image.height > image.width ? maxEdge : null,
    interpolation: img.Interpolation.average,
  );
}
