import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:openscan/core/cv/compress.dart';

import 'filters/document_filters.dart';
import 'filters/filters.dart';

/// Runs [filter] over the RGBA buffer in place and hands it back.
///
/// Kept separate from the file I/O below so the picker can filter an
/// already-decoded thumbnail without touching the disk.
Uint8List filterRgba(Filter filter, Uint8List rgba, int width, int height) {
  filter.apply(rgba, width, height);
  return rgba;
}

/// Decodes [image], applies [filter] and re-encodes as JPEG.
///
/// The `image` package hands out a *copy* of the pixel buffer from
/// `getBytes()`, so the filtered bytes have to be wrapped back into a new
/// [img.Image] before encoding — mutating the buffer alone would silently
/// encode the untouched original.
Uint8List filterEncodedImage(Filter filter, Uint8List encoded, {int? maxEdge}) {
  img.Image? decoded = img.decodeImage(encoded);
  if (decoded == null) {
    throw StateError('Could not decode image for filtering');
  }
  if (maxEdge != null &&
      (decoded.width > maxEdge || decoded.height > maxEdge)) {
    decoded = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: maxEdge)
        : img.copyResize(decoded, height: maxEdge);
  }

  final rgba = decoded.getBytes(order: img.ChannelOrder.rgba);
  filterRgba(filter, rgba, decoded.width, decoded.height);

  final filtered = img.Image.fromBytes(
    width: decoded.width,
    height: decoded.height,
    bytes: rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  // The same quality a page is stored at (see kStoredPageQuality): a
  // filtered page is still just a page, and encoding it richer than the
  // capture it came from buys nothing but bytes.
  return img.encodeJpg(filtered, quality: kStoredPageQuality);
}

/// Entry point designed to be run via `compute()`: filters the JPEG at
/// `params['src']` and returns the encoded result.
///
/// Pass `params['maxEdge']` to work on a downscaled copy — that is how the
/// picker builds its previews and thumbnails without decoding a
/// full-resolution capture once per chip.
///
/// Pass `params['dest']` to have the result written there and the path
/// returned instead of the bytes; that is the full-resolution path, where
/// shipping megabytes back across the isolate boundary is pure waste.
Future<Object> applyFilterIsolateEntry(Map<String, dynamic> params) async {
  final filter = documentFilterByName(params['filter'] as String?);
  final src = params['src'] as String;
  final dest = params['dest'] as String?;
  final maxEdge = params['maxEdge'] as int?;

  final encoded = await File(src).readAsBytes();
  final result = filterEncodedImage(filter, encoded, maxEdge: maxEdge);

  if (dest == null) return result;
  await File(dest).writeAsBytes(result, flush: true);
  return dest;
}

/// Entry point designed to be run via `compute()`: filters an already
/// decoded-and-downscaled JPEG held in memory.
///
/// The picker uses this so a page is decoded from disk once, not once per
/// filter chip — every chip then works on the same small JPEG.
Uint8List filterBytesIsolateEntry(Map<String, dynamic> params) {
  final filter = documentFilterByName(params['filter'] as String?);
  final bytes = params['bytes'] as Uint8List;
  return filterEncodedImage(filter, bytes);
}
