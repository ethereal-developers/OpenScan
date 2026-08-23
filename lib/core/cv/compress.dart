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
