import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Gets the bundled language models onto disk, where Tesseract can open
/// them.
///
/// The native side takes a directory path and reads `<path>/tessdata/<lang>
/// .traineddata` itself, which an asset bundled in the APK cannot satisfy —
/// assets live inside the archive with no file path of their own. They are
/// copied out once, on first use, and left there.
class TessData {
  TessData._();

  /// Languages shipped in the APK. Listed in the asset manifest rather than
  /// hardcoded here so adding a language is one asset plus one JSON line.
  static const _manifest = 'assets/tessdata_config.json';
  static const _assetDir = 'assets/tessdata';

  /// The only language bundled today. Kept as a constant so the callers
  /// that need a default do not each pick their own.
  static const defaultLanguage = 'eng';

  static Future<String>? _installing;

  /// The directory to hand the native side, with `tessdata/` populated
  /// underneath it. Installs on the first call; later calls await the same
  /// future rather than racing to write the same files.
  static Future<String> ensureInstalled() => _installing ??= _install();

  static Future<String> _install() async {
    final documents = await getApplicationDocumentsDirectory();
    final tessdata = Directory(p.join(documents.path, 'tessdata'));
    if (!tessdata.existsSync()) tessdata.createSync(recursive: true);

    for (final file in await bundledLanguageFiles()) {
      final destination = File(p.join(tessdata.path, file));
      // A model is a fixed asset, so an existing copy of the right size is
      // the same bytes. Size rather than mere existence: a copy interrupted
      // half way through leaves a file that exists and cannot be loaded.
      final data = await rootBundle.load('$_assetDir/$file');
      if (destination.existsSync() &&
          destination.lengthSync() == data.lengthInBytes) {
        continue;
      }
      await destination.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return documents.path;
  }

  /// The `*.traineddata` filenames bundled in the APK.
  static Future<List<String>> bundledLanguageFiles() async {
    try {
      final manifest = jsonDecode(await rootBundle.loadString(_manifest));
      final files = manifest is Map ? manifest['files'] : null;
      if (files is! List) return const [];
      return [for (final file in files) if (file is String) file];
    } catch (e) {
      debugPrint('Could not read tessdata manifest: $e');
      return const [];
    }
  }

  /// The language codes those files provide, e.g. `eng`.
  static Future<List<String>> availableLanguages() async => [
        for (final file in await bundledLanguageFiles())
          p.basenameWithoutExtension(file),
      ];
}
