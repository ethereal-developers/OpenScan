package com.ethereal.openscan;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import org.opencv.android.OpenCVLoader;
import org.opencv.android.Utils;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Scalar;
import org.opencv.core.Size;
import org.opencv.imgproc.Imgproc;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ImageUtil {
    public static final String TAG = ImageUtil.class.getName();

    public static boolean cropImage(String path, double tl_x, double tl_y, double tr_x, double tr_y, double bl_x, double bl_y, double br_x, double br_y) {
        Bitmap original = BitmapFactory.decodeFile(path);
        Log.d(TAG, "Perspective crop started");
        try {
            if (OpenCVLoader.initDebug()) {
                Log.d(TAG, "OpenCV started");
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
                    stream = new FileOutputStream(path);
                } catch (FileNotFoundException e) {
                    Log.e(TAG, "Perspective crop done, but error while creating output file stream --> ", e);
                    return false;
                }
                cropped.compress(Bitmap.CompressFormat.JPEG, 100, stream);

                mat.release();
                resultDoc.release();
                src_mat.release();
                dst_mat.release();
                perspectiveTransform.release();
                cropped.recycle();
                original.recycle();
            }
        } catch (Exception e) {
            Log.e(TAG, "Error while calling perspective crop --> ", e);
            return false;
        }
        return true;
    }

    public static Map<String, Integer> getImageSize(String path) {
        Log.d(TAG, "Get image size called");
        Map<String, Integer> imageSizeMap = new HashMap<>();
        imageSizeMap.put("height", 1280);
        imageSizeMap.put("width", 720);
        try {
            Bitmap original = BitmapFactory.decodeFile(path);
            int height = original.getHeight();
            int width = original.getWidth();

            imageSizeMap.put("height", height);
            imageSizeMap.put("width", width);
        } catch (Exception e) {
            Log.e(TAG, "Exception while getting image size --> ", e);
            return imageSizeMap;
        }
        return imageSizeMap;
    }

    public static boolean rotateImage(String path, int degree) {
        Log.d(TAG, "Rotate image called");
        try {
            Bitmap original = BitmapFactory.decodeFile(path);
            Matrix matrix = new Matrix();
            matrix.postRotate(degree);
            Bitmap bitmap = Bitmap.createBitmap(original, 0, 0, original.getWidth(), original.getHeight(), matrix, true);
            FileOutputStream stream = null;
            try {
                stream = new FileOutputStream(path);
            } catch (FileNotFoundException e) {
                e.printStackTrace();
            }
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
            try {
                stream.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        } catch (Exception e) {
            Log.e(TAG, "Exception while rotating image --> ", e);
            return false;
        }
        return true;
    }

    public static Corners detectDocument(String path) {
        Mat mat = new Mat();
        Bitmap bitmap = BitmapFactory.decodeFile(path);
        Utils.bitmapToMat(bitmap, mat);
        ArrayList<MatOfPoint> contours = DetectDocumentHelper.findContours(mat);
        return DetectDocumentHelper.getCorners(contours, mat.size());
    }

    private static class DetectDocumentHelper {
        private static final String TAG = "ImageProcessor";

        public static ArrayList<MatOfPoint> findContours(Mat src) {
            Mat grayImage;
            Mat cannedImage;
            Mat kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(9.0, 9.0));
            Mat dilate;
            Size size = new Size(src.size().width, src.size().height);
            grayImage = new Mat(size, CvType.CV_8UC4);
            cannedImage = new Mat(size, CvType.CV_8UC1);
            dilate = new Mat(size, CvType.CV_8UC1);

            Imgproc.cvtColor(src, grayImage, Imgproc.COLOR_BGR2GRAY);
            Imgproc.GaussianBlur(grayImage, grayImage, new Size(3.0, 3.0), 0.0);
            Imgproc.threshold(grayImage, grayImage, 20.0, 255.0, Imgproc.THRESH_TRIANGLE);

            Imgproc.Canny(grayImage, cannedImage, 75.0, 200.0);
            Imgproc.dilate(cannedImage, dilate, kernel);

            ArrayList<MatOfPoint> contours = new ArrayList<>();
            Mat hierarchy = new Mat();

            Imgproc.findContours(dilate, contours, hierarchy, Imgproc.RETR_TREE, Imgproc.CHAIN_APPROX_SIMPLE);

            Collections.sort(contours, (lhs, rhs) -> Double.compare(Imgproc.contourArea(rhs), Imgproc.contourArea(lhs)));

            hierarchy.release();
            grayImage.release();
            cannedImage.release();
            kernel.release();
            dilate.release();

            return contours;
        }

        public static Corners getCorners(ArrayList<MatOfPoint> contours, Size size) {
            int indexTo;
            contours.size();
            if (contours.size() <= 5) {
                indexTo = contours.size() - 1;
            } else {
                indexTo = 4;
            }

            for (int index = 0; index < contours.size(); index++) {
                if (index <= indexTo) {
                    MatOfPoint2f c2f = new MatOfPoint2f(contours.get(index).toArray());
                    double peri = Imgproc.arcLength(c2f, true);
                    MatOfPoint2f approx = new MatOfPoint2f();
                    Imgproc.approxPolyDP(c2f, approx, 0.03 * peri, true);
                    List<Point> points = approx.toList();
                    MatOfPoint convex = new MatOfPoint();
                    approx.convertTo(convex, CvType.CV_32S);
                    // select biggest 4 angles polygon
                    if (points.size() == 4 && Imgproc.isContourConvex(convex)) {
                        List<Point> foundPoints = sortPoints(points);
                        return new Corners(foundPoints, size);
                    }
                } else {
                    return null;
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
}

class Corners {
    private List<Point> corners;
    private Size size;

    public Corners(List<Point> foundPoints, Size size) {
        this.corners = foundPoints;
        this.size = size;
    }

    public void setCorners(List<Point> newCorners) {
        corners = newCorners;
    }

    public void setSize(Size newSize) {
        size = newSize;
    }

    public List<Point> getCorners() {
        return corners;
    }

    public Size getSize() {
        return size;
    }

    public String toString() {
        return "Corners: " + corners + ", Size: " + size;
    }
}

