import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:openscan/core/image_filter/filters/preset_filters.dart';
import 'package:image/image.dart' as imageLib;
import 'package:path/path.dart';

import '../../core/image_filter/filters/filters.dart';
import '../screens/filter_screen.dart';
import '../screens/preview_screen.dart';

class PreviewModel {
  Map<String, List<int>?> cachedFilters = {};
  Filter currentFilter = presetFiltersList[0];
}
