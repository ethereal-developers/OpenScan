package com.ethereal.openscan;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.util.Log;

import androidx.annotation.NonNull;

import org.opencv.android.OpenCVLoader;
import org.opencv.core.Point;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.ethereal.openscan/cropper";
    private static final String TAG_NAME = "JavaMainActivity";
    private static boolean isOpenCVInitialized = false;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(this::handleMethodCall);
    }

    private void handleMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (!isOpenCVInitialized) {
            initializeOpenCV();
        }

        String methodCalled = call.method;
        try {
            switch (methodCalled) {
                case "compress":
                    handleCompress(call, result);
                    break;
                case "fixRotation":
                    handleFixRotation(call, result);
                    break;
                case "cropImage":
                    handleCropImage(call, result);
                    break;
                case "getImageSize":
                    handleGetImageSize(call, result);
                    break;
                case "rotateImage":
                    handleRotateImage(call, result);
                    break;
                case "detectDocument":
                    handleDetectDocument(call, result);
                    break;
                default:
                    result.error("UNKNOWN_METHOD", "Method " + methodCalled + " not found", null);
            }
        } catch (Exception e) {
            Log.e(TAG_NAME, "Error handling method " + methodCalled, e);
            result.error("METHOD_ERROR", e.getMessage(), null);
        }
    }

    private void initializeOpenCV() {
        if (OpenCVLoader.initDebug()) {
            isOpenCVInitialized = true;
            Log.d(TAG_NAME, "OpenCV loaded successfully");
        } else {
            Log.e(TAG_NAME, "OpenCV NOT loaded");
        }
    }

    private void handleCompress(@NonNull MethodCall call, @NonNull MethodChannel.Result result) throws IOException {
        int desiredQuality = call.argument("desiredQuality");
        String path = call.argument("src");
        String savePath = call.argument("dest");
        String fileName = String.format("%s/%d.jpg", savePath, System.currentTimeMillis());

        try (FileOutputStream outStream = new FileOutputStream(fileName)) {
            Bitmap bitmap = BitmapFactory.decodeFile(path);
            try {
                bitmap.compress(Bitmap.CompressFormat.JPEG, desiredQuality, outStream);
                result.success(fileName);
            } finally {
                bitmap.recycle();
            }
        }
    }

    private void handleFixRotation(@NonNull MethodCall call, @NonNull MethodChannel.Result result) throws IOException {
        String srcPath = call.argument("srcPath");
        String destPath = call.argument("destPath");
        String fileName = String.format("%s/%d.jpg", destPath, System.currentTimeMillis());

        ExifInterface exif = new ExifInterface(srcPath);
        int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
        int rotationAngle = getRotationAngle(orientation);

        Bitmap bitmap = BitmapFactory.decodeFile(srcPath);
        try {
            Matrix matrix = new Matrix();
            matrix.setRotate(rotationAngle, (float) bitmap.getWidth() / 2, (float) bitmap.getHeight() / 2);
            Bitmap rotatedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
            
            try (FileOutputStream stream = new FileOutputStream(fileName)) {
                rotatedBitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                result.success(fileName);
            } finally {
                rotatedBitmap.recycle();
            }
        } finally {
            bitmap.recycle();
        }
    }

    private int getRotationAngle(int orientation) {
        switch (orientation) {
            case ExifInterface.ORIENTATION_ROTATE_90:
                return 90;
            case ExifInterface.ORIENTATION_ROTATE_180:
                return 180;
            case ExifInterface.ORIENTATION_ROTATE_270:
                return 270;
            default:
                return 0;
        }
    }

    private void handleCropImage(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String srcPath = call.argument("srcPath");
        String destPath = call.argument("destPath");
        double tl_x = Double.parseDouble(Objects.requireNonNull(call.argument("tl_x")));
        double tl_y = Double.parseDouble(Objects.requireNonNull(call.argument("tl_y")));
        double tr_x = Double.parseDouble(Objects.requireNonNull(call.argument("tr_x")));
        double tr_y = Double.parseDouble(Objects.requireNonNull(call.argument("tr_y")));
        double bl_x = Double.parseDouble(Objects.requireNonNull(call.argument("bl_x")));
        double bl_y = Double.parseDouble(Objects.requireNonNull(call.argument("bl_y")));
        double br_x = Double.parseDouble(Objects.requireNonNull(call.argument("br_x")));
        double br_y = Double.parseDouble(Objects.requireNonNull(call.argument("br_y")));

        Log.d(TAG_NAME, String.format("Crop points: TL(%.2f,%.2f) TR(%.2f,%.2f) BL(%.2f,%.2f) BR(%.2f,%.2f)",
                tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y));

        boolean isCropped = ImageUtil.cropImage(srcPath, destPath, tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y);
        result.success(isCropped);
    }

    private void handleGetImageSize(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String path = call.argument("path");
        Map<String, Integer> imageSizeMap = ImageUtil.getImageSize(path);
        result.success(imageSizeMap);
    }

    private void handleRotateImage(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String path = call.argument("path");
        int degree = Objects.requireNonNull(call.argument("degree"));
        boolean isRotated = ImageUtil.rotateImage(path, degree);
        result.success(isRotated);
    }

    private void handleDetectDocument(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String path = call.argument("path");
        Corners corners = ImageUtil.detectDocument(path);
        Log.d(TAG_NAME, "Detected corners: " + corners);
        
        List<List<Double>> resultList = new ArrayList<>();
        if (corners != null) {
            for (Point p : corners.getCorners()) {
                resultList.add(Arrays.asList(p.x, p.y));
            }
        }
        result.success(resultList);
    }
}
