package com.ethereal.openscan;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.os.Build;
import android.util.Log;

import org.opencv.android.Utils;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Size;
import org.opencv.imgcodecs.Imgcodecs;
import org.opencv.imgproc.Imgproc;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ImageUtil {
    private static final String TAG = ImageUtil.class.getSimpleName();
    
    // OpenCV parameters
    private static final double CANNY_LOW_THRESHOLD = 75.0;
    private static final double CANNY_HIGH_THRESHOLD = 200.0;
    private static final double APPROX_POLY_EPSILON = 0.03;
    private static final Size GAUSSIAN_KERNEL_SIZE = new Size(3.0, 3.0);
    private static final Size MORPH_KERNEL_SIZE = new Size(9.0, 9.0);

    public static boolean cropImage(String srcPath, String destPath, double tl_x, double tl_y, 
            double tr_x, double tr_y, double bl_x, double bl_y, double br_x, double br_y) {
        Bitmap original = BitmapFactory.decodeFile(srcPath);
        if (original == null) {
            Log.e(TAG, "Failed to decode source image");
            return false;
        }

        try {
            Mat mat = new Mat();
            Utils.bitmapToMat(original, mat);

            Mat src_mat = new Mat(4, 1, CvType.CV_32FC2);
            Mat dst_mat = new Mat(4, 1, CvType.CV_32FC2);

            // Calculate dimensions
            double widthBottom = Math.sqrt(Math.pow(br_x - bl_x, 2) + Math.pow(br_y - bl_y, 2));
            double widthTop = Math.sqrt(Math.pow(tr_x - tl_x, 2) + Math.pow(tr_y - tl_y, 2));
            double greaterWidth = Math.max(widthBottom, widthTop);
            int maxWidth = Double.valueOf(greaterWidth).intValue();

            double heightRight = Math.sqrt(Math.pow(tr_x - br_x, 2) + Math.pow(tr_y - br_y, 2));
            double heightLeft = Math.sqrt(Math.pow(tl_x - bl_x, 2) + Math.pow(tl_y - bl_y, 2));
            double greaterHeight = Math.max(heightRight, heightLeft);
            int maxHeight = Double.valueOf(greaterHeight).intValue();

            // Set up transformation matrices
            src_mat.put(0, 0, tl_x, tl_y, tr_x, tr_y, bl_x, bl_y, br_x, br_y);
            dst_mat.put(0, 0, 0.0, 0.0, greaterWidth, 0.0, 0.0, greaterHeight, greaterWidth, greaterHeight);

            Mat perspectiveTransform = Imgproc.getPerspectiveTransform(src_mat, dst_mat);
            Mat resultDoc = new Mat(maxHeight, maxWidth, CvType.CV_8UC4);

            // Apply perspective transform
            Imgproc.warpPerspective(mat, resultDoc, perspectiveTransform, resultDoc.size());

            Bitmap cropped = Bitmap.createBitmap(maxWidth, maxHeight, Bitmap.Config.ARGB_8888);
            Utils.matToBitmap(resultDoc, cropped);

            // Save the result
            try (FileOutputStream stream = new FileOutputStream(destPath)) {
                cropped.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                return true;
            } catch (IOException e) {
                Log.e(TAG, "Failed to save cropped image", e);
                return false;
            } finally {
                cropped.recycle();
            }
        } catch (Exception e) {
            Log.e(TAG, "Error during perspective crop", e);
            return false;
        } finally {
            original.recycle();
        }
    }

    public static String fixRotation(String srcPath, String destPath) {

        return srcPath;
    }

    public static Map<String, Integer> getImageSize(String path) {
        Map<String, Integer> imageSizeMap = new HashMap<>();
        imageSizeMap.put("height", 1280);
        imageSizeMap.put("width", 720);

        Bitmap original = BitmapFactory.decodeFile(path);
        if (original != null) {
            try {
                imageSizeMap.put("height", original.getHeight());
                imageSizeMap.put("width", original.getWidth());
                Log.d(TAG, String.format("Image size: %dx%d", original.getWidth(), original.getHeight()));
            } finally {
                original.recycle();
            }
        } else {
            Log.e(TAG, "Failed to decode image for size calculation");
        }
        return imageSizeMap;
    }

    public static boolean rotateImage(String path, int degree) {
        Bitmap original = BitmapFactory.decodeFile(path);
        if (original == null) {
            Log.e(TAG, "Failed to decode image for rotation");
            return false;
        }

        try {
            Matrix matrix = new Matrix();
            matrix.postRotate(degree);
            Bitmap rotatedBitmap = Bitmap.createBitmap(original, 0, 0, 
                    original.getWidth(), original.getHeight(), matrix, true);

            try (FileOutputStream stream = new FileOutputStream(path)) {
                rotatedBitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                return true;
            } catch (IOException e) {
                Log.e(TAG, "Failed to save rotated image", e);
                return false;
            } finally {
                rotatedBitmap.recycle();
            }
        } finally {
            original.recycle();
        }
    }

    public static Corners detectDocument(String path) {
        Mat src = Imgcodecs.imread(path);
        if (src.empty()) {
            Log.e(TAG, "Failed to read image for document detection");
            return null;
        }

        try {
            ArrayList<MatOfPoint> contours = findContours(src);
            return getCorners(contours, src.size());
        } finally {
            src.release();
        }
    }

    private static ArrayList<MatOfPoint> findContours(Mat src) {
        Mat grayImage = new Mat(src.size(), CvType.CV_8UC4);
        Mat cannedImage = new Mat(src.size(), CvType.CV_8UC1);
        Mat kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, MORPH_KERNEL_SIZE);
        Mat dilate = new Mat(src.size(), CvType.CV_8UC1);

        try {
            // Preprocessing
            Imgproc.cvtColor(src, grayImage, Imgproc.COLOR_BGR2GRAY);
            Imgproc.GaussianBlur(grayImage, grayImage, GAUSSIAN_KERNEL_SIZE, 0.0);
            Imgproc.Canny(grayImage, cannedImage, CANNY_LOW_THRESHOLD, CANNY_HIGH_THRESHOLD);
            Imgproc.dilate(cannedImage, dilate, kernel);
            Imgproc.threshold(dilate, dilate, 20.0, 255.0, Imgproc.THRESH_TRIANGLE);

            // Find contours
            ArrayList<MatOfPoint> contours = new ArrayList<>();
            Mat hierarchy = new Mat();
            Imgproc.findContours(dilate, contours, hierarchy, Imgproc.RETR_TREE, Imgproc.CHAIN_APPROX_SIMPLE);
            hierarchy.release();

            // Sort contours by area
            Collections.sort(contours, (lhs, rhs) -> Double.compare(Imgproc.contourArea(rhs), Imgproc.contourArea(lhs)));
            return contours;
        } finally {
            grayImage.release();
            cannedImage.release();
            kernel.release();
            dilate.release();
        }
    }

    private static Corners getCorners(ArrayList<MatOfPoint> contours, Size size) {
        int maxContoursToCheck = Math.min(contours.size(), 5);
        
        for (int index = 0; index < maxContoursToCheck; index++) {
            MatOfPoint2f c2f = new MatOfPoint2f(contours.get(index).toArray());
            double peri = Imgproc.arcLength(c2f, true);
            MatOfPoint2f approx = new MatOfPoint2f();
            
            try {
                Imgproc.approxPolyDP(c2f, approx, APPROX_POLY_EPSILON * peri, true);
                List<Point> points = approx.toList();
                MatOfPoint convex = new MatOfPoint();
                
                try {
                    approx.convertTo(convex, CvType.CV_32S);
                    Log.d(TAG, "Detected Points: " + points);

                    if (points.size() == 4 && Imgproc.isContourConvex(convex)) {
                        List<Point> sortedPoints = sortPoints(points);
                        return new Corners(sortedPoints, size);
                    }
                } finally {
                    convex.release();
                }
            } finally {
                approx.release();
            }
        }
        return null;
    }

    private static List<Point> sortPoints(List<Point> points) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            points.sort((point1, point2) -> (int) ((point1.x + point1.y) - (point2.x + point2.y)));
        }
        Point p0 = points.get(0);
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            points.sort((point1, point2) -> (int) ((point1.y - point1.x) - (point2.y - point2.x)));
        }
        Point p1 = points.get(0);
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            points.sort((point1, point2) -> (int) ((point2.x + point2.y) - (point1.x + point1.y)));
        }
        Point p2 = points.get(0);
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            points.sort((point1, point2) -> (int) ((point2.y - point2.x) - (point1.y - point1.x)));
        }
        Point p3 = points.get(0);
        
        return Arrays.asList(p0, p1, p2, p3);
    }
}

class Corners {
    private final List<Point> corners;
    private final Size size;

    public Corners(List<Point> foundPoints, Size size) {
        this.corners = foundPoints;
        this.size = size;
    }

    public List<Point> getCorners() {
        return corners;
    }

    public Size getSize() {
        return size;
    }

    @Override
    public String toString() {
        return "Corners: " + corners + ", Size: " + size;
    }
}

