package com.ethereal.openscan;

import android.util.Log;

import androidx.annotation.NonNull;

import org.opencv.android.OpenCVLoader;
import org.opencv.core.Point;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;


public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.ethereal.openscan/cropper";
    private static final String TAG_NAME = "JavaMainActivity";

    static {
        if (OpenCVLoader.initDebug()) {
            Log.d(TAG_NAME, "OpenCV loaded successfully");
        } else {
            Log.d(TAG_NAME, "OpenCV NOT loaded successfully");
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            String methodCalled = call.method;
                            switch (methodCalled) {
                                case "cropImage": {
                                    String path = call.argument("path");
                                    double tl_x = call.argument("tl_x");
                                    double tl_y = call.argument("tl_y");
                                    double tr_x = call.argument("tr_x");
                                    double tr_y = call.argument("tr_y");
                                    double bl_x = call.argument("bl_x");
                                    double bl_y = call.argument("bl_y");
                                    double br_x = call.argument("br_x");
                                    double br_y = call.argument("br_y");
                                    boolean isCropped = ImageUtil.cropImage(path, tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y);
                                    result.success(isCropped);
                                }
                                case "getImageSize": {
                                    String path = call.argument("path");
                                    Map<String, Integer> imageSizeMap = ImageUtil.getImageSize(path);
                                    result.success(imageSizeMap);
                                    break;
                                }
                                case "rotateImage": {
                                    String path = call.argument("path");
                                    int degree = call.argument("degree");
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
