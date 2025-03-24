import '../data/native_android_util.dart';

class DocumentScannerService {
  Future<String> enhanceDocument(String imagePath, String filterType) async {
    try {
      return await NativeAndroidUtil.enhanceDocument(imagePath, filterType);
    } catch (e) {
      throw Exception('Failed to enhance document: $e');
    }
  }
}

enum DocumentFilterType {
  adaptiveThreshold,
  otsuThreshold,
  edgeEnhancement,
  contrastEnhancement,
}

extension DocumentFilterTypeExtension on DocumentFilterType {
  String get value {
    switch (this) {
      case DocumentFilterType.adaptiveThreshold:
        return 'adaptive_threshold';
      case DocumentFilterType.otsuThreshold:
        return 'otsu_threshold';
      case DocumentFilterType.edgeEnhancement:
        return 'edge_enhancement';
      case DocumentFilterType.contrastEnhancement:
        return 'contrast_enhancement';
    }
  }

  String get displayName {
    switch (this) {
      case DocumentFilterType.adaptiveThreshold:
        return 'Adaptive Threshold';
      case DocumentFilterType.otsuThreshold:
        return 'Otsu Threshold';
      case DocumentFilterType.edgeEnhancement:
        return 'Edge Enhancement';
      case DocumentFilterType.contrastEnhancement:
        return 'Contrast Enhancement';
    }
  }
}
