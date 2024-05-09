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
import java.io.FileNotFoundException;
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
import io.flutter.plugins.GeneratedPluginRegistrant;


public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.ethereal.openscan/cropper";
    private static final String TAG_NAME = "JavaMainActivity";
    private static boolean isOpenCVInitialized  = false;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (!isOpenCVInitialized) {
                                if (OpenCVLoader.initDebug()) {
                                    isOpenCVInitialized = true;
                                    Log.d(TAG_NAME, "OpenCV loaded successfully");
                                } else {
                                    Log.d(TAG_NAME, "OpenCV NOT loaded");
                                }
                            }

                            String methodCalled = call.method;
                            switch (methodCalled) {
                                case "compress": {
                                    int desiredQuality = call.argument("desiredQuality");
                                    String path = call.argument("src");
                                    String savePath = call.argument("dest");
                                    String fileName = String.format("%s/%d.jpg", savePath, System.currentTimeMillis());
                                    // Log.d("onCompressMethodCall", String.valueOf(percentage));
                                    File file;
                                    FileOutputStream outStream = null;
                                    Bitmap bitmap = null;
                                    try {
                                        file = new File(fileName);
                                        outStream = new FileOutputStream(file);
                                        bitmap = BitmapFactory.decodeFile(path);
                                        bitmap.compress(Bitmap.CompressFormat.JPEG, desiredQuality, outStream);
                                        result.success(file.getPath());
                                    } catch (IOException e) {
                                        e.printStackTrace();
                                    } finally {
                                        try {
                                            if (outStream != null) {
                                                outStream.flush();
                                                outStream.close();
                                            }
                                        } catch (Exception ignored) {
                                        }
                                        try {
                                            if (bitmap != null) {
                                                bitmap.recycle();
                                            }
                                        } catch (Exception ignored) {
                                        }
                                    }
                                    break;
                                }
                                case "fixRotation": {
                                    String srcPath = call.argument("srcPath");
                                    String destPath = call.argument("destPath");
                                    String fileName = String.format("%s/%d.jpg", destPath, System.currentTimeMillis());
                                    try {
                                        ExifInterface exif = new ExifInterface(srcPath);
                                        int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
                                        int rotationAngle = 0;
                                        switch (orientation) {
                                            case ExifInterface.ORIENTATION_ROTATE_90:
                                                rotationAngle = 90;
                                                break;
                                            case ExifInterface.ORIENTATION_ROTATE_180:
                                                rotationAngle = 180;
                                                break;
                                            case ExifInterface.ORIENTATION_ROTATE_270:
                                                rotationAngle = 270;
                                                break;
                                        }
                                        Bitmap bitmap = BitmapFactory.decodeFile(srcPath);
                                        Matrix matrix = new Matrix();
                                        matrix.setRotate(rotationAngle, (float) bitmap.getWidth() / 2, (float) bitmap.getHeight() / 2);
                                        Bitmap bmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
                                        FileOutputStream stream = null;
                                        try {
                                            stream = new FileOutputStream(fileName);
                                            bmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                                            result.success(fileName);
                                        } catch (FileNotFoundException e) {
                                            e.printStackTrace();
                                        } finally {
                                            if (stream != null) {
                                                stream.close();
                                            }
                                            bmap.recycle();
                                        }
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                    break;
                                }
                                case "cropImage": {
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
                                    Log.d(TAG_NAME, "Points " + tl_x + " " + tl_y + " " + tr_x + " " + tr_y + " " + bl_x + " " + bl_y + " " + br_x + " " + br_y);
                                    boolean isCropped = ImageUtil.cropImage(srcPath, destPath, tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y);
                                    result.success(isCropped);
                                    break;
                                }
                                case "getImageSize": {
                                    String path = call.argument("path");
                                    Map<String, Integer> imageSizeMap = ImageUtil.getImageSize(path);
                                    result.success(imageSizeMap);
                                    break;
                                }
                                case "rotateImage": {
                                    String path = call.argument("path");
                                    int degree = Objects.requireNonNull(call.argument("degree"));
                                    boolean isRotated = ImageUtil.rotateImage(path, degree);
                                    result.success(isRotated);
                                    break;
                                }
                                case "detectDocument": {
                                    Corners corners = ImageUtil.detectDocument(call.argument("path"));
                                    Log.d(TAG_NAME, "The corners are: " + corners);
                                    List<List<Double>> resultList = new ArrayList<>();
                                    if (corners != null) {
                                        for (Point p : corners.getCorners()) {
                                            resultList.add(Arrays.asList(p.x, p.y));
                                        }
                                    }
                                    result.success(resultList);
                                    break;
                                }
                            }
                        }
                );
    }
}
