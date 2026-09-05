import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'models/quad.dart';
import 'native_decode.dart';
import 'perspective_crop.dart';

/// Entry point designed to be run via `compute()`. Encodes one stored file
/// from pixels the platform decoder has already produced (see
/// `native_decode.dart`), warping them to [Quad] first when the page was
/// captured with a boundary.
///
/// This is the isolate half of the fast storage path. The decode it used to
/// begin with — by far the most expensive step — now happens on the UI
/// isolate, because `dart:ui`'s codecs refuse to run anywhere else; what is
/// left here is the JPEG encode, which is pure Dart, CPU-bound, and exactly
/// the kind of work an isolate is for.
///
/// Parameters: `rgba` (a [TransferableTypedData] of 8-bit RGBA pixels),
/// their `width` and `height`, `dest`, `quality`, `maxEdge`, and `quad` —
/// the boundary in fractional [0,1] portrait-overlay coordinates, or null
/// to store the pixels whole.
///
/// Returns whether the file was written.
Future<bool> encodeStoredPageIsolateEntry(Map<String, dynamic> params) async {
  final dest = params['dest'] as String;
  try {
    final rgba = (params['rgba'] as TransferableTypedData).materialize();
    // The platform decoder hands back premultiplied pixels; a stored page
    // is opaque, so flatten before the encoder drops the alpha channel and
    // leaves transparent regions showing whatever was underneath.
    flattenOntoWhite(rgba.asUint8List());
    var page = img.Image.fromBytes(
      width: params['width'] as int,
      height: params['height'] as int,
      bytes: rgba,
      numChannels: 4,
    );

    final quad = params['quad'] as Quad?;
    if (quad != null) {
      // The caller already decoded at a scale that puts the warp's natural
      // output at the page cap, so this warps roughly 1:1 and the cap is
      // only here to hold the line if the estimate came out high.
      page = warpToPage(page, quadInPixels(quad, page),
              maxEdge: params['maxEdge'] as int) ??
          page;
    }

    await File(dest).writeAsBytes(
      img.encodeJpg(page, quality: params['quality'] as int),
      flush: true,
    );
    return true;
  } catch (e) {
    debugPrint('Could not encode stored page $dest: $e');
    return false;
  }
}

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
/// through as-is instead, since an oversized page — or one in a format
/// only the platform's own decoder knows, like HEIC — is worth far more
/// than no page at all. Returns which of the two files were written,
/// whether the page was actually cropped, and `decoded`: false means the
/// bytes went through untouched and nothing here has confirmed they are a
/// readable image, so the caller has to check before keeping the page.
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

    return {
      'page': true,
      'original': wroteOriginal,
      'cropped': cropped,
      'decoded': true,
    };
  } catch (e) {
    debugPrint('Could not decode/warp capture $src; copying through raw: $e');
    final page = await _copyThrough(src, pageDest);
    final original =
        originalDest == null ? false : await _copyThrough(src, originalDest);
    return {
      'page': page,
      'original': original,
      'cropped': false,
      'decoded': false,
    };
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
  } catch (e) {
    debugPrint('Could not copy $src to $dest: $e');
    return false;
  }
}
