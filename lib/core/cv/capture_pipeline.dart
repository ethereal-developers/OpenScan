import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

import 'models/quad.dart';
import 'perspective_crop.dart';

/// Everything one captured page needs on its way into storage, done in a
/// single isolate pass over a single decode.
///
/// The steps used to be separate `compute()` calls — warp the capture in
/// place at full resolution and full quality, decode that again to
/// downscale it into a page, decode the untouched capture a third time to
/// downscale it into a kept original. Three decodes and three encodes of a
/// multi-megapixel photo, each on a freshly spawned isolate, is most of
/// the wait between finishing a scan and seeing the page. Done here it is
/// one decode, and one encode per file actually written.
///
/// Parameters, all via a plain map so this can be a `compute()` entry
/// point: `src` (the capture), `pageDest`, `pageMaxEdge`, `pageQuality`,
/// `quad` (the boundary to crop to, in fractional [0,1] portrait-overlay
/// coordinates, or null to store the photo whole), and optionally
/// `originalDest` with `originalMaxEdge` and `originalQuality`.
///
/// Never throws: a capture that cannot be decoded or re-encoded is copied
/// through as-is instead, since an oversized page is worth far more than
/// no page at all. Returns which of the two files were written, and
/// whether the page was actually cropped.
Future<Map<String, bool>> storeCaptureIsolateEntry(
    Map<String, dynamic> params) async {
  final src = params['src'] as String;
  final pageDest = params['pageDest'] as String;
  final pageMaxEdge = params['pageMaxEdge'] as int;
  final pageQuality = params['pageQuality'] as int;
  final quad = params['quad'] as Quad?;
  final originalDest = params['originalDest'] as String?;

  try {
    final decoded = img.decodeImage(await File(src).readAsBytes());
    if (decoded == null) throw const FormatException('Could not decode');

    var wroteOriginal = false;
    if (originalDest != null) {
      // Written from the same decode as the page, before the warp touches
      // anything: this is what the page would have been uncropped.
      await File(originalDest).writeAsBytes(
        img.encodeJpg(
          _fit(decoded, params['originalMaxEdge'] as int),
          quality: params['originalQuality'] as int,
        ),
        flush: true,
      );
      wroteOriginal = true;
    }

    img.Image? page;
    if (quad != null) {
      page = warpToPage(decoded, quadInPixels(quad, decoded),
          maxEdge: pageMaxEdge);
    }
    final cropped = page != null;
    page ??= _fit(decoded, pageMaxEdge);

    await File(pageDest)
        .writeAsBytes(img.encodeJpg(page, quality: pageQuality), flush: true);

    return {'page': true, 'original': wroteOriginal, 'cropped': cropped};
  } catch (_) {
    final page = await _copyThrough(src, pageDest);
    final original =
        originalDest == null ? false : await _copyThrough(src, originalDest);
    return {'page': page, 'original': original, 'cropped': false};
  }
}

/// [image] scaled down to fit [maxEdge] on its long side, or itself if it
/// already does — a stored page is never upscaled to meet the cap.
img.Image _fit(img.Image image, int maxEdge) {
  final longest = max(image.width, image.height);
  if (maxEdge <= 0 || longest <= maxEdge) return image;
  final scale = maxEdge / longest;
  return img.copyResize(
    image,
    width: max(1, (image.width * scale).round()),
    height: max(1, (image.height * scale).round()),
    interpolation: img.Interpolation.average,
  );
}

Future<bool> _copyThrough(String src, String dest) async {
  try {
    await File(src).copy(dest);
    return true;
  } catch (_) {
    return false;
  }
}
