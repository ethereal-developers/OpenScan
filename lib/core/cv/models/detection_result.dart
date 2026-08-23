import 'quad.dart';

/// Result of running document-boundary detection on an image. Replaces the
/// old raw `List` / silently-empty-on-failure contract with an explicit
/// three-way outcome so the UI can never be left waiting forever.
abstract class DetectionResult {
  const DetectionResult();
}

/// A convex document-shaped quadrilateral was found.
class DetectionSuccess extends DetectionResult {
  final Quad quad;
  final int imageWidth;
  final int imageHeight;

  const DetectionSuccess(this.quad, this.imageWidth, this.imageHeight);
}

/// Detection ran without error, but no suitable quad was found.
class DetectionNotFound extends DetectionResult {
  final int imageWidth;
  final int imageHeight;

  const DetectionNotFound(this.imageWidth, this.imageHeight);
}

/// Detection threw (corrupt image, decode failure, timeout, etc).
class DetectionFailure extends DetectionResult {
  final String message;

  const DetectionFailure(this.message);
}

/// Result of running the perspective crop.
abstract class CropResult {
  const CropResult();
}

class CropSuccess extends CropResult {
  final String path;

  const CropSuccess(this.path);
}

class CropFailure extends CropResult {
  final String message;

  const CropFailure(this.message);
}
