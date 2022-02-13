package com.ethereal.openscan;

import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.lang.reflect.Array;
import java.nio.BufferUnderflowException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import org.opencv.android.OpenCVLoader;
import org.opencv.android.Utils;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.Scalar;
import org.opencv.core.Size;
import org.opencv.imgproc.Imgproc;

import java.util.*;

import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;


public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.ethereal.openscan/cropper";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            String methodCalled = call.method;
                            switch (methodCalled) {
                                case "cropImage": {
                                    String path = call.argument("path").toString();
                                    Bitmap original = BitmapFactory.decodeFile(path);
                                    int height = original.getHeight();
                                    int width = original.getWidth();
                                    Log.d("onCropImageCalled", "Crop started");
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
                                            Utils.bitmapToMat(original, mat);

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
                                            original.recycle();

                                            result.success(true);
                                        }
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                    break;
                                }
                                case "getImageSize": {
                                    String path = call.argument("path").toString();
                                    Bitmap original = BitmapFactory.decodeFile(path);
                                    int height = original.getHeight();
                                    int width = original.getWidth();
                                    Log.d("onGetImageSizeCalled", "Get image size called");
                                    ArrayList<Integer> imageSize = new ArrayList<>();
                                    imageSize.add(width);
                                    imageSize.add(height);
                                    result.success(imageSize);
                                    break;
                                }
                                case "rotateImage": {
                                    String path = call.argument("path").toString();
                                    Bitmap original = BitmapFactory.decodeFile(path);
                                    int height = original.getHeight();
                                    int width = original.getWidth();
                                    Log.d("onRotateImageCalled", "Rotate image called");
                                    int degree = call.argument("degree");
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
                                case "detectDocument": {
//                                    Mat mat = new Mat();
//                                    Utils.bitmapToMat(original, mat);
                                    Bitmap bmapFromByte = BitmapFactory.decodeByteArray(call.argument("byteArr"), call.argument("offset"), call.argument("length"));
                                    FileOutputStream stream = null;
                                    try {
                                        stream = new FileOutputStream(new File("/storage/emulated/0/Documents/temp.jpg"));
                                    } catch (FileNotFoundException e) {
                                        e.printStackTrace();
                                    }
                                    bmapFromByte.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                                    try {
                                        stream.close();
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                    result.success(true);
                                    break;


                                    // Log.d("Matrix", mat.height + mat.width + "");
                                    // Log.d("DetectedDocument", detectPreviewDocument(mat) + "");

//                                        ScannedDocument doc = detectDocument(mat);

//                                        Log.d("OnScanComplete", doc.hasPoints + "");

                                    // result.success({'points': doc.getArray(), 'hasPoints': doc.hasPoints});

                                }
                            }
                        }
                );
    }

    Point[] mPreviewPoints;
    Size mPreviewSize;
    private static final String TAG = "ImageProcessor";

    private boolean detectPreviewDocument(Mat inputRgba) {
        ArrayList<MatOfPoint> contours = findContours(inputRgba);

        Quadrilateral quad = getQuadrilateral(contours, inputRgba.size());

        mPreviewPoints = null;
        mPreviewSize = inputRgba.size();

        if (quad != null) {

            Point[] rescaledPoints = new Point[4];

            double ratio = inputRgba.size().height / 500;

            for (int i = 0; i < 4; i++) {
                int x = Double.valueOf(quad.points[i].x * ratio).intValue();
                int y = Double.valueOf(quad.points[i].y * ratio).intValue();
//                if (mBugRotate) {
//                    rescaledPoints[(i+2)%4] = new Point( Math.abs(x- mPreviewSize.width), Math.abs(y- mPreviewSize.height));
//                } else {
                rescaledPoints[i] = new Point(x, y);
//                }
            }

            mPreviewPoints = rescaledPoints;

//            drawDocumentBox(mPreviewPoints, mPreviewSize);

            Log.d(TAG, quad.points[0].toString() + " , " + quad.points[1].toString() + " , " + quad.points[2].toString() + " , " + quad.points[3].toString());

            return true;

        }

//        mMainActivity.getHUD().clear();
//        mMainActivity.invalidateHUD();

        return false;
    }

    private ScannedDocument detectDocument(Mat inputRgba) {
        ArrayList<MatOfPoint> contours = findContours(inputRgba);

        ScannedDocument sd = new ScannedDocument(inputRgba);

        Quadrilateral quad = getQuadrilateral(contours, inputRgba.size());

        Mat doc;

        if (quad != null) {

//            MatOfPoint c = quad.contours;

            sd.quadrilateral = quad;
            sd.previewPoints = mPreviewPoints;
            sd.previewSize = mPreviewSize;
            sd.hasPoints = true;

            doc = fourPointTransform(inputRgba, quad.points);

        } else {
            doc = new Mat(inputRgba.size(), CvType.CV_8UC4);
            inputRgba.copyTo(doc);
            sd.hasPoints = false;
        }

//        enhanceDocument(doc);

        sd.processed = doc;

        return sd;
    }

    private Quadrilateral getQuadrilateral(ArrayList<MatOfPoint> contours, Size srcSize) {

        double ratio = srcSize.height / 500;
        int height = Double.valueOf(srcSize.height / ratio).intValue();
        int width = Double.valueOf(srcSize.width / ratio).intValue();
        Size size = new Size(width, height);

        for (MatOfPoint c : contours) {
            MatOfPoint2f c2f = new MatOfPoint2f(c.toArray());
            double peri = Imgproc.arcLength(c2f, true);
            MatOfPoint2f approx = new MatOfPoint2f();
            Imgproc.approxPolyDP(c2f, approx, 0.02 * peri, true);

            Point[] points = approx.toArray();

            // select biggest 4 angles polygon
            if (points.length == 4) {
                Point[] foundPoints = sortPoints(points);

                if (insideArea(foundPoints, size)) {
                    return new Quadrilateral(c, foundPoints);
                }
            }
        }
        return null;
    }

    private ArrayList<MatOfPoint> findContours(Mat src) {
        Mat grayImage = null;
        Mat cannedImage = null;
        Mat resizedImage = null;

        double ratio = src.size().height / 500;
        int height = Double.valueOf(src.size().height / ratio).intValue();
        int width = Double.valueOf(src.size().width / ratio).intValue();
        Size size = new Size(width, height);

        resizedImage = new Mat(size, CvType.CV_8UC4);
        grayImage = new Mat(size, CvType.CV_8UC4);
        cannedImage = new Mat(size, CvType.CV_8UC1);

        Imgproc.resize(src, resizedImage, size);
        Imgproc.cvtColor(resizedImage, grayImage, Imgproc.COLOR_RGBA2GRAY, 4);
        Imgproc.GaussianBlur(grayImage, grayImage, new Size(5, 5), 0);
        Imgproc.Canny(grayImage, cannedImage, 75, 200);

        ArrayList<MatOfPoint> contours = new ArrayList<MatOfPoint>();
        Mat hierarchy = new Mat();

        Imgproc.findContours(cannedImage, contours, hierarchy, Imgproc.RETR_LIST, Imgproc.CHAIN_APPROX_SIMPLE);

        hierarchy.release();

        Collections.sort(contours, (lhs, rhs) -> Double.valueOf(Imgproc.contourArea(rhs)).compareTo(Imgproc.contourArea(lhs)));

        resizedImage.release();
        grayImage.release();
        cannedImage.release();

        return contours;
    }

    @NonNull
    private Mat fourPointTransform(Mat src, Point[] pts) {

        double ratio = src.size().height / 500;

        Point tl = pts[0];
        Point tr = pts[1];
        Point br = pts[2];
        Point bl = pts[3];

        double widthA = Math.sqrt(Math.pow(br.x - bl.x, 2) + Math.pow(br.y - bl.y, 2));
        double widthB = Math.sqrt(Math.pow(tr.x - tl.x, 2) + Math.pow(tr.y - tl.y, 2));

        double dw = Math.max(widthA, widthB) * ratio;
        int maxWidth = Double.valueOf(dw).intValue();


        double heightA = Math.sqrt(Math.pow(tr.x - br.x, 2) + Math.pow(tr.y - br.y, 2));
        double heightB = Math.sqrt(Math.pow(tl.x - bl.x, 2) + Math.pow(tl.y - bl.y, 2));

        double dh = Math.max(heightA, heightB) * ratio;
        int maxHeight = Double.valueOf(dh).intValue();

        Mat doc = new Mat(maxHeight, maxWidth, CvType.CV_8UC4);

        Mat src_mat = new Mat(4, 1, CvType.CV_32FC2);
        Mat dst_mat = new Mat(4, 1, CvType.CV_32FC2);

        src_mat.put(0, 0, tl.x * ratio, tl.y * ratio, tr.x * ratio, tr.y * ratio, br.x * ratio, br.y * ratio, bl.x * ratio, bl.y * ratio);
        dst_mat.put(0, 0, 0.0, 0.0, dw, 0.0, dw, dh, 0.0, dh);

        Mat m = Imgproc.getPerspectiveTransform(src_mat, dst_mat);

        Imgproc.warpPerspective(src, doc, m, doc.size());

        return doc;
    }

    private Point[] sortPoints(Point[] src) {

        ArrayList<Point> srcPoints = new ArrayList<>(Arrays.asList(src));

        Point[] result = {null, null, null, null};

        Comparator<Point> sumComparator = (lhs, rhs) -> Double.valueOf(lhs.y + lhs.x).compareTo(rhs.y + rhs.x);

        Comparator<Point> diffComparator = (lhs, rhs) -> Double.valueOf(lhs.y - lhs.x).compareTo(rhs.y - rhs.x);

        // top-left corner = minimal sum
        result[0] = Collections.min(srcPoints, sumComparator);

        // bottom-right corner = maximal sum
        result[2] = Collections.max(srcPoints, sumComparator);

        // top-right corner = minimal diference
        result[1] = Collections.min(srcPoints, diffComparator);

        // bottom-left corner = maximal diference
        result[3] = Collections.max(srcPoints, diffComparator);

        return result;
    }

    private boolean insideArea(Point[] rp, Size size) {

        int width = Double.valueOf(size.width).intValue();
        int height = Double.valueOf(size.height).intValue();
        int baseMeasure = height / 4;

        int bottomPos = height - baseMeasure;
        int topPos = baseMeasure;
        int leftPos = width / 2 - baseMeasure;
        int rightPos = width / 2 + baseMeasure;

        return (
                rp[0].x <= leftPos && rp[0].y <= topPos
                        && rp[1].x >= rightPos && rp[1].y <= topPos
                        && rp[2].x >= rightPos && rp[2].y >= bottomPos
                        && rp[3].x <= leftPos && rp[3].y >= bottomPos

        );
    }

    private void enhanceDocument(Mat src) {
        boolean colorMode = false;
        boolean filterMode = true;
        if (colorMode && filterMode) {
//            src.convertTo(src,-1, colorGain , colorBias);
            Mat mask = new Mat(src.size(), CvType.CV_8UC1);
            Imgproc.cvtColor(src, mask, Imgproc.COLOR_RGBA2GRAY);

            Mat copy = new Mat(src.size(), CvType.CV_8UC3);
            src.copyTo(copy);

            Imgproc.adaptiveThreshold(mask, mask, 255, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY_INV, 15, 15);

            src.setTo(new Scalar(255, 255, 255));
            copy.copyTo(src, mask);

            copy.release();
            mask.release();

            // special color threshold algorithm
//            colorThresh(src,colorThresh);
        } else if (!colorMode) {
            Imgproc.cvtColor(src, src, Imgproc.COLOR_RGBA2GRAY);
            if (filterMode) {
                Imgproc.adaptiveThreshold(src, src, 255, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 15, 15);
            }
        }
    }

    class Quadrilateral {
        private MatOfPoint contours;
        private Point[] points;

        Quadrilateral(MatOfPoint contours, Point[] points) {
            this.contours = contours;
            this.points = points;
        }
    }

    class ScannedDocument {
        private Mat processed;
        private Quadrilateral quadrilateral;
        private Point[] previewPoints;
        private Size previewSize;
        private boolean hasPoints;

        public double[] getArray() {
            double[] array2D = {10, 0, 10, 0, 10, 0, 10, 0};
            for (int i = 0; i < 7; i += 2) {
                array2D[i] = previewPoints[i / 2].x;
                array2D[i + 1] = previewPoints[i / 2].y;
            }
            return array2D;
        }

        ScannedDocument(Mat processed) {
            this.processed = processed;
        }
    }
}
