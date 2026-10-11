package com.ethereal.openscan;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.media.ExifInterface;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Writes a captured photo into storage — the cropped page, its kept
 * original, or both — using the platform's own image code: one native
 * decode, a perspective warp done by {@link Matrix#setPolyToPoly} on a
 * {@link Canvas}, and {@link Bitmap#compress} for the JPEG.
 *
 * The Dart pipeline does the same work in pure Dart, and on a 12MP capture
 * that is around fourteen seconds a page, nearly all of it JPEG encoding.
 * Here it is a fraction of a second. The Dart pipeline stays as the
 * fallback: anything this can't do — an orientation it doesn't handle, a
 * decode that runs out of memory — is reported as an error, and the caller
 * goes the slow way instead.
 *
 * Every output is described the same way: four corners (TL, TR, BR, BL)
 * as fractions of the photo the right way up, the size of the rectangle
 * they are warped into, and a JPEG quality. A kept original is just the
 * whole frame. The corners are fractions rather than pixels so that the
 * orientation is resolved here, against the file itself, and the Dart side
 * never has to agree with it about which way round the photo is stored.
 */
final class CaptureStore implements MethodChannel.MethodCallHandler {
    static final String CHANNEL = "openscan/capture_store";

    /** One at a time: each decode can be tens of megabytes. */
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (!"store".equals(call.method)) {
            result.notImplemented();
            return;
        }
        executor.execute(() -> {
            try {
                final Map<String, Boolean> written = store(call);
                main.post(() -> result.success(written));
            } catch (Throwable t) {
                // OutOfMemoryError included: the Dart pipeline can still try.
                main.post(() -> result.error("store_failed", String.valueOf(t), null));
            }
        });
    }

    private static final class Output {
        final String dest;
        final double[] corners;
        final int width, height, quality;

        Output(Map<String, Object> m) {
            dest = (String) m.get("dest");
            @SuppressWarnings("unchecked")
            final List<Number> c = (List<Number>) m.get("corners");
            corners = new double[8];
            for (int i = 0; i < 8; i++) corners[i] = c.get(i).doubleValue();
            width = ((Number) m.get("width")).intValue();
            height = ((Number) m.get("height")).intValue();
            quality = ((Number) m.get("quality")).intValue();
        }

        /** Longest of each pair of opposite edges, in upright pixels. */
        double naturalLongEdge(int uprightWidth, int uprightHeight) {
            final double[] p = new double[8];
            for (int i = 0; i < 4; i++) {
                p[i * 2] = corners[i * 2] * uprightWidth;
                p[i * 2 + 1] = corners[i * 2 + 1] * uprightHeight;
            }
            final double w = Math.max(dist(p, 0, 1), dist(p, 3, 2));
            final double h = Math.max(dist(p, 0, 3), dist(p, 1, 2));
            return Math.max(w, h);
        }

        private static double dist(double[] p, int a, int b) {
            return Math.hypot(p[a * 2] - p[b * 2], p[a * 2 + 1] - p[b * 2 + 1]);
        }
    }

    private Map<String, Boolean> store(MethodCall call) throws Exception {
        final String src = call.argument("src");
        final Integer turnsArg = call.argument("quarterTurns");
        final int turns = turnsArg == null ? 0 : ((turnsArg % 4) + 4) % 4;
        final List<Map<String, Object>> rawOutputs = call.argument("outputs");
        final List<Output> outputs = new ArrayList<>();
        for (Map<String, Object> m : rawOutputs) outputs.add(new Output(m));

        final BitmapFactory.Options bounds = new BitmapFactory.Options();
        bounds.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(src, bounds);
        final int rawWidth = bounds.outWidth, rawHeight = bounds.outHeight;
        if (rawWidth <= 0 || rawHeight <= 0) throw new IllegalStateException("unreadable " + src);

        final int orientation = new ExifInterface(src).getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
        switch (orientation) {
            case ExifInterface.ORIENTATION_UNDEFINED:
            case ExifInterface.ORIENTATION_NORMAL:
            case ExifInterface.ORIENTATION_ROTATE_90:
            case ExifInterface.ORIENTATION_ROTATE_180:
            case ExifInterface.ORIENTATION_ROTATE_270:
                break;
            default:
                // Mirrored orientations: not something a camera writes.
                throw new IllegalStateException("orientation " + orientation);
        }
        final boolean sideways = orientation == ExifInterface.ORIENTATION_ROTATE_90
                || orientation == ExifInterface.ORIENTATION_ROTATE_270;
        final int uprightWidth = sideways ? rawHeight : rawWidth;
        final int uprightHeight = sideways ? rawWidth : rawHeight;

        // Decode at the smallest power-of-two reduction that still leaves
        // every output at least as much detail as it is being written at,
        // so the warp only ever shrinks by less than half — which a
        // bilinear filter does cleanly — and a 12MP photo isn't held at
        // full size when a quarter of it would do.
        double headroom = Double.MAX_VALUE;
        for (Output o : outputs) {
            final double natural = o.naturalLongEdge(uprightWidth, uprightHeight);
            final double wanted = Math.max(o.width, o.height);
            if (wanted > 0) headroom = Math.min(headroom, natural / wanted);
        }
        int sample = 1;
        while (sample * 2 <= headroom) sample *= 2;

        final BitmapFactory.Options opts = new BitmapFactory.Options();
        opts.inSampleSize = sample;
        opts.inPreferredConfig = Bitmap.Config.ARGB_8888;
        final Bitmap photo = BitmapFactory.decodeFile(src, opts);
        if (photo == null) throw new IllegalStateException("could not decode " + src);

        final float sx = (float) photo.getWidth() / rawWidth;
        final float sy = (float) photo.getHeight() / rawHeight;
        final Map<String, Boolean> written = new HashMap<>();
        try {
            final Paint paint = new Paint(Paint.FILTER_BITMAP_FLAG | Paint.ANTI_ALIAS_FLAG);
            for (Output o : outputs) {
                final float[] from = new float[8];
                for (int i = 0; i < 4; i++) {
                    // Upright pixel -> stored pixel, undoing the EXIF turn.
                    final double ux = o.corners[i * 2] * uprightWidth;
                    final double uy = o.corners[i * 2 + 1] * uprightHeight;
                    double rx, ry;
                    switch (orientation) {
                        case ExifInterface.ORIENTATION_ROTATE_90:
                            rx = uy;
                            ry = rawHeight - ux;
                            break;
                        case ExifInterface.ORIENTATION_ROTATE_180:
                            rx = rawWidth - ux;
                            ry = rawHeight - uy;
                            break;
                        case ExifInterface.ORIENTATION_ROTATE_270:
                            rx = rawWidth - uy;
                            ry = ux;
                            break;
                        default:
                            rx = ux;
                            ry = uy;
                    }
                    from[i * 2] = (float) (rx * sx);
                    from[i * 2 + 1] = (float) (ry * sy);
                }
                final int w = o.width, h = o.height;
                final float[] to = {0, 0, w, 0, w, h, 0, h};
                final Matrix matrix = new Matrix();
                if (!matrix.setPolyToPoly(from, 0, to, 0, 4)) {
                    throw new IllegalStateException("degenerate corners");
                }
                // Then the page's own clockwise turns, for a phone held on
                // its side.
                final int outWidth = turns % 2 == 0 ? w : h;
                final int outHeight = turns % 2 == 0 ? h : w;
                if (turns == 1) {
                    matrix.postRotate(90);
                    matrix.postTranslate(h, 0);
                } else if (turns == 2) {
                    matrix.postRotate(180);
                    matrix.postTranslate(w, h);
                } else if (turns == 3) {
                    matrix.postRotate(270);
                    matrix.postTranslate(0, w);
                }

                final Bitmap out = Bitmap.createBitmap(outWidth, outHeight, Bitmap.Config.ARGB_8888);
                try {
                    final Canvas canvas = new Canvas(out);
                    canvas.drawColor(Color.WHITE);
                    canvas.drawBitmap(photo, matrix, paint);
                    try (FileOutputStream stream = new FileOutputStream(o.dest)) {
                        if (!out.compress(Bitmap.CompressFormat.JPEG, o.quality, stream)) {
                            throw new IllegalStateException("could not encode " + o.dest);
                        }
                    }
                    written.put(o.dest, true);
                } finally {
                    out.recycle();
                }
            }
        } finally {
            photo.recycle();
        }
        return written;
    }
}
