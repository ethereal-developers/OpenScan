import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'models/detection_result.dart';
import 'models/point.dart';
import 'models/quad.dart';

/// Entry point designed to be run via `compute()`. Warps the quad region
/// of the image at `params['path']` into an upright rectangle and
/// overwrites the file in place, mirroring the previous native behavior
/// (`ImageUtil.cropImage` also wrote the result back to the same path).
///
/// Replaces `Imgproc.getPerspectiveTransform` + `Imgproc.warpPerspective`
/// with a hand-rolled direct-linear-transform homography solve and
/// bilinear-sampled inverse warp.
Future<CropResult> cropImageIsolateEntry(Map<String, dynamic> params) async {
  final String path = params['path'] as String;
  final Quad quad = params['quad'] as Quad;

  try {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const CropFailure('Could not decode image');
    }

    final srcWidth = decoded.width;
    final srcHeight = decoded.height;
    final srcRgba = decoded.getBytes(order: img.ChannelOrder.rgba);

    final tl = quad.topLeft, tr = quad.topRight;
    final br = quad.bottomRight, bl = quad.bottomLeft;

    final widthTop = _dist(tl.x, tl.y, tr.x, tr.y);
    final widthBottom = _dist(bl.x, bl.y, br.x, br.y);
    final outWidth = max(widthTop, widthBottom).round().clamp(1, 1 << 16);

    final heightLeft = _dist(tl.x, tl.y, bl.x, bl.y);
    final heightRight = _dist(tr.x, tr.y, br.x, br.y);
    final outHeight = max(heightLeft, heightRight).round().clamp(1, 1 << 16);

    // Homography mapping output-rectangle coordinates -> source quad
    // coordinates, used to inverse-sample the source for each output pixel.
    final h = _solveHomography(outWidth.toDouble(), outHeight.toDouble(), tl, tr, br, bl);

    final outRgba = Uint8List(outWidth * outHeight * 4);
    for (int y = 0; y < outHeight; y++) {
      for (int x = 0; x < outWidth; x++) {
        final srcPoint = _applyHomography(h, x.toDouble(), y.toDouble());
        final sampled =
            _bilinearSample(srcRgba, srcWidth, srcHeight, srcPoint[0], srcPoint[1]);
        final dstIdx = (y * outWidth + x) * 4;
        outRgba[dstIdx] = sampled[0];
        outRgba[dstIdx + 1] = sampled[1];
        outRgba[dstIdx + 2] = sampled[2];
        outRgba[dstIdx + 3] = 255;
      }
    }

    final outImage = img.Image.fromBytes(
      width: outWidth,
      height: outHeight,
      bytes: outRgba.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );

    final jpg = img.encodeJpg(outImage, quality: 100);
    await File(path).writeAsBytes(jpg, flush: true);

    return CropSuccess(path);
  } catch (e) {
    return CropFailure(e.toString());
  }
}

double _dist(double x1, double y1, double x2, double y2) =>
    sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));

/// Solves the 8-parameter homography mapping the destination rectangle
/// `(0,0)-(w,0)-(w,h)-(0,h)` onto the `(tl,tr,br,bl)` source quad, via a
/// direct linear transform — the same underlying math
/// `getPerspectiveTransform` used, solved in the direction needed for
/// inverse-mapping (output pixel -> source sample point).
List<double> _solveHomography(double w, double h, Pt tl, Pt tr, Pt br, Pt bl) {
  final dst = [
    [0.0, 0.0],
    [w, 0.0],
    [w, h],
    [0.0, h],
  ];
  final src = [
    [tl.x, tl.y],
    [tr.x, tr.y],
    [br.x, br.y],
    [bl.x, bl.y],
  ];

  // 8x8 linear system A*p = b for unknowns [a, b, c, d, e, f, g, h] where:
  //   x = (a*u + b*v + c) / (g*u + h*v + 1)
  //   y = (d*u + e*v + f) / (g*u + h*v + 1)
  final a = List.generate(8, (_) => List<double>.filled(8, 0.0));
  final bVec = List<double>.filled(8, 0.0);

  for (int i = 0; i < 4; i++) {
    final u = dst[i][0], v = dst[i][1];
    final x = src[i][0], y = src[i][1];

    a[2 * i] = [u, v, 1, 0, 0, 0, -u * x, -v * x];
    bVec[2 * i] = x;

    a[2 * i + 1] = [0, 0, 0, u, v, 1, -u * y, -v * y];
    bVec[2 * i + 1] = y;
  }

  final p = _solveLinearSystem(a, bVec);
  return [...p, 1.0];
}

/// Gaussian elimination with partial pivoting for a small dense system.
List<double> _solveLinearSystem(List<List<double>> a, List<double> b) {
  final n = b.length;
  for (int col = 0; col < n; col++) {
    int pivot = col;
    for (int row = col + 1; row < n; row++) {
      if (a[row][col].abs() > a[pivot][col].abs()) pivot = row;
    }
    final tmpRow = a[col];
    a[col] = a[pivot];
    a[pivot] = tmpRow;
    final tmpB = b[col];
    b[col] = b[pivot];
    b[pivot] = tmpB;

    final pivotVal = a[col][col];
    if (pivotVal.abs() < 1e-12) continue;

    for (int row = 0; row < n; row++) {
      if (row == col) continue;
      final factor = a[row][col] / pivotVal;
      if (factor == 0) continue;
      for (int c = col; c < n; c++) {
        a[row][c] -= factor * a[col][c];
      }
      b[row] -= factor * b[col];
    }
  }

  return List.generate(
      n, (i) => a[i][i].abs() < 1e-12 ? 0.0 : b[i] / a[i][i]);
}

List<double> _applyHomography(List<double> h, double u, double v) {
  final denom = h[6] * u + h[7] * v + 1;
  final x = (h[0] * u + h[1] * v + h[2]) / denom;
  final y = (h[3] * u + h[4] * v + h[5]) / denom;
  return [x, y];
}

List<int> _bilinearSample(
  Uint8List rgba,
  int width,
  int height,
  double x,
  double y,
) {
  final cx = x.clamp(0.0, width - 1.0);
  final cy = y.clamp(0.0, height - 1.0);

  final x0 = cx.floor();
  final y0 = cy.floor();
  final x1 = (x0 + 1).clamp(0, width - 1);
  final y1 = (y0 + 1).clamp(0, height - 1);

  final fx = cx - x0;
  final fy = cy - y0;

  List<int> pixel(int px, int py) {
    final idx = (py * width + px) * 4;
    return [rgba[idx], rgba[idx + 1], rgba[idx + 2], rgba[idx + 3]];
  }

  final p00 = pixel(x0, y0);
  final p10 = pixel(x1, y0);
  final p01 = pixel(x0, y1);
  final p11 = pixel(x1, y1);

  List<int> lerp(List<int> a, List<int> b, double t) =>
      List.generate(4, (i) => (a[i] + (b[i] - a[i]) * t).round());

  final top = lerp(p00, p10, fx);
  final bottom = lerp(p01, p11, fx);
  return lerp(top, bottom, fy);
}
