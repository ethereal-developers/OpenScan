import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Pixels handed back by the platform's own image decoder: 8-bit
/// premultiplied RGBA, four bytes per pixel, row-major, no padding — the
/// layout `img.Image.fromBytes(numChannels: 4)` expects, once
/// [flattenOntoWhite] has made them opaque.
///
/// [rgba] is carried as a [TransferableTypedData] because its only
/// destination is a worker isolate: materializing it there *moves* the
/// buffer instead of copying a page-sized image across the port.
class DecodedPixels {
  const DecodedPixels({
    required this.width,
    required this.height,
    required this.rgba,
  });

  final int width;
  final int height;
  final TransferableTypedData rgba;
}

/// Decodes [encoded] image bytes with the platform's image decoder, scaled
/// on the way so the result is at most [maxEdge] on its long side.
///
/// This exists because decoding is the single most expensive step in
/// storing a page, and `package:image` does it in pure Dart: on a mid-range
/// phone a 12MP capture costs ~2.7s to decode and another ~1.3s to resize,
/// against ~350ms for the platform decoder doing both at once. The engine
/// downsamples *during* decode, so the full-resolution bitmap never has to
/// exist — which is also why this is easier on memory than decoding whole
/// and shrinking afterwards.
///
/// Two things make this awkward enough to be worth a comment. It cannot run
/// in a `compute()` isolate: `dart:ui`'s codecs are reachable only from the
/// root isolate ("Failed to access the internal image decoder registry on
/// this isolate"), so this is called on the UI isolate — which is fine, as
/// the decode itself happens on the engine's own worker threads and only the
/// `await` lands here. And it returns raw pixels rather than a file, because
/// `dart:ui` can encode PNG and nothing else; the JPEG still has to be
/// written by `package:image`, off in a worker isolate where it belongs.
///
/// EXIF orientation is applied, matching what `img.decodeImage` already
/// does, so a page stored through here comes out the same way up as one
/// stored the old way.
///
/// Returns null if the platform cannot decode these bytes at all — a
/// truncated download, or a format it doesn't know — leaving the caller to
/// fall back rather than treating unreadable bytes as a page.
Future<DecodedPixels?> decodeScaled(
  Uint8List encoded, {
  required int maxEdge,
  String? label,
}) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(encoded);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final target = _fitted(descriptor.width, descriptor.height, maxEdge);

    codec = await descriptor.instantiateCodec(
      targetWidth: target.width,
      targetHeight: target.height,
    );
    image = (await codec.getNextFrame()).image;

    // Premultiplied on purpose: a stored page is opaque JPEG, so whatever
    // transparency a gallery pick carries has to be flattened onto
    // something, and premultiplied pixels flatten onto white by addition
    // alone (see `flattenOntoWhite`). The straight variant would be the
    // obvious choice, but it cannot recover colour where alpha is zero —
    // there is nothing to divide back out — so fully transparent regions
    // come back black and then stay black once the encoder drops alpha.
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;

    return DecodedPixels(
      width: image.width,
      height: image.height,
      rgba: TransferableTypedData.fromList([
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ]),
    );
  } catch (e) {
    debugPrint("Platform decoder couldn't read ${label ?? 'capture'}: $e");
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}

/// The pixel size [encoded] decodes to, without decoding it — the platform
/// decoder reads this out of the header alone.
///
/// Used to work out how far a capture can be scaled down *before* it is
/// decoded, which is the whole point of doing this ahead of the decode
/// rather than measuring the bitmap afterwards.
Future<({int width, int height})?> decodedSize(Uint8List encoded,
    {String? label}) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(encoded);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    return (width: descriptor.width, height: descriptor.height);
  } catch (e) {
    debugPrint("Platform decoder couldn't measure ${label ?? 'capture'}: $e");
    return null;
  } finally {
    descriptor?.dispose();
    buffer?.dispose();
  }
}

/// [width] x [height] scaled down to fit [maxEdge] on its long side, or
/// itself if it already does — a stored page is never upscaled to meet the
/// cap.
({int width, int height}) _fitted(int width, int height, int maxEdge) {
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

/// Flattens premultiplied RGBA onto a white background, in place.
///
/// A stored page is an opaque JPEG, so any transparency a gallery pick
/// carries has to go somewhere, and the encoder simply dropping the alpha
/// channel is not an answer: it leaves whatever happened to sit under a
/// transparent region showing through. White is the answer a scanner wants
/// — a logo PNG with a transparent background becomes a logo on paper
/// rather than a logo in a black box.
///
/// Because the pixels are premultiplied, compositing over white is
/// `channel + (255 - alpha)` with no division and no per-channel multiply,
/// and premultiplication guarantees `channel <= alpha`, so the sum cannot
/// exceed 255.
///
/// Fully opaque images — every camera capture, every JPEG — cost one
/// compare per pixel and no writes.
void flattenOntoWhite(Uint8List rgba) {
  for (int i = 0; i < rgba.length; i += 4) {
    final alpha = rgba[i + 3];
    if (alpha == 255) continue;
    final white = 255 - alpha;
    rgba[i] = rgba[i] + white;
    rgba[i + 1] = rgba[i + 1] + white;
    rgba[i + 2] = rgba[i + 2] + white;
    rgba[i + 3] = 255;
  }
}
