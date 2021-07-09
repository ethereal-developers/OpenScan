package com.ethereal.openscan;

import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.Arrays;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import org.opencv.android.OpenCVLoader;
import org.opencv.android.Utils;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.Size;
import org.opencv.imgproc.Imgproc;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.ethereal.openscan/cropper";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            String methodCalled = call.method;
                            String path = call.argument("path").toString();
                            switch (methodCalled) {
                                case "cropImage": {
                                    Log.d("onCropImageCalled", "Crop started");
                                    Bitmap bitmap = BitmapFactory.decodeFile(path);
                                    int height = bitmap.getHeight();
                                    int width = bitmap.getWidth();
                                    double tl_x = call.argument("tl_x");
                                    double tl_y = call.argument("tl_y");
                                    double tr_x = call.argument("tr_x");
                                    double tr_y = call.argument("tr_y");
                                    double bl_x = call.argument("bl_x");
                                    double bl_y = call.argument("bl_y");
                                    double br_x = call.argument("br_x");
                                    double br_y = call.argument("br_y");
                                    try {
                                        if (OpenCVLoader.initDebug()) {
                                            Log.d("onOpenCVCalled", "OpenCV started");
                                            Mat mat = new Mat();
                                            Utils.bitmapToMat(bitmap, mat);

                                            Mat src_mat = new Mat(4, 1, CvType.CV_32FC2);
                                            Mat dst_mat = new Mat(4, 1, CvType.CV_32FC2);

                                            double widthBottom = Math.sqrt(Math.pow(br_x - bl_x, 2) + Math.pow(br_y - bl_y, 2));
                                            double widthTop = Math.sqrt(Math.pow(tr_x - tl_x, 2) + Math.pow(tr_y - tl_y, 2));
                                            double greaterWidth = Math.max(widthBottom, widthTop);
                                            int maxWidth = Double.valueOf(greaterWidth).intValue();

                                            double heightRight = Math.sqrt(Math.pow(tr_x - br_x, 2) + Math.pow(tr_y - br_y, 2));
                                            double heightLeft = Math.sqrt(Math.pow(tl_x - bl_x, 2) + Math.pow(tl_y - bl_y, 2));
                                            double greaterHeight = Math.max(heightRight, heightLeft);
                                            int maxHeight = Double.valueOf(greaterHeight).intValue();

                                            src_mat.put(0, 0, tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y);
                                            dst_mat.put(0, 0, 0.0, 0.0, greaterWidth, 0.0, 0.0, greaterHeight, greaterWidth, greaterHeight);

                                            Mat perspectiveTransform = Imgproc.getPerspectiveTransform(src_mat, dst_mat);
                                            Mat resultDoc = new Mat(maxHeight, maxWidth, CvType.CV_8UC4);

                                            Imgproc.warpPerspective(mat, resultDoc, perspectiveTransform, resultDoc.size());

                                            Bitmap cropped = Bitmap.createBitmap(maxWidth, maxHeight, Bitmap.Config.ARGB_8888);
                                            Utils.matToBitmap(resultDoc, cropped);
                                            FileOutputStream stream = null;
                                            try {
                                                stream = new FileOutputStream(new File(path));
                                            } catch (FileNotFoundException e) {
                                                e.printStackTrace();
                                            }
                                            cropped.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                                            String temp = stream.toString();
                                            Log.d("onCropOver", temp);

                                            mat.release();
                                            resultDoc.release();
                                            src_mat.release();
                                            dst_mat.release();
                                            perspectiveTransform.release();
                                            cropped.recycle();
                                            bitmap.recycle();

                                            result.success(true);
                                        }
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                    break;
                                }
                                case "getImageSize": {
                                    Log.d("onGetImageSizeCalled", "Get image size called");
                                    Bitmap bitmap = BitmapFactory.decodeFile(path);
                                    int height = bitmap.getHeight();
                                    int width = bitmap.getWidth();
                                    ArrayList<Integer> imageSize = new ArrayList<>();
                                    imageSize.add(width);
                                    imageSize.add(height);
                                    result.success(imageSize);
                                    break;
                                }
                                case "rotateImage": {
                                    Log.d("onRotateImageCalled", "Rotate image called");
                                    int degree = call.argument("degree");
                                    Bitmap original = BitmapFactory.decodeFile(path);
                                    Matrix matrix = new Matrix();
                                    matrix.postRotate(degree);
                                    Bitmap bitmap = Bitmap.createBitmap(original, 0, 0, original.getWidth(), original.getHeight(), matrix, true);
                                    FileOutputStream stream = null;
                                    try {
                                        stream = new FileOutputStream(new File(path));
                                    } catch (FileNotFoundException e) {
                                        e.printStackTrace();
                                    }
                                    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                                    try {
                                        stream.close();
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                    result.success(true);
                                    break;
                                }
                            }
                        }
                );
    }
}
