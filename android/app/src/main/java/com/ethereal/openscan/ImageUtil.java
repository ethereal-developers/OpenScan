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
import org.opencv.core.Core;

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
    private static final double CANNY_LOW_THRESHOLD = 50.0;
    private static final double CANNY_HIGH_THRESHOLD = 150.0;
    private static final double APPROX_POLY_EPSILON = 0.02;
    private static final Size GAUSSIAN_KERNEL_SIZE = new Size(5.0, 5.0);
    private static final Size MORPH_KERNEL_SIZE = new Size(3.0, 3.0);
    private static final double MIN_AREA_RATIO = 0.1;
    private static final double MAX_AREA_RATIO = 0.95;

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

            // Enhance the result
            Mat enhanced = enhanceDocument(resultDoc);

            Bitmap cropped = Bitmap.createBitmap(maxWidth, maxHeight, Bitmap.Config.ARGB_8888);
            Utils.matToBitmap(enhanced, cropped);

            // Save the result
            try (FileOutputStream stream = new FileOutputStream(destPath)) {
                cropped.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                return true;
            } catch (IOException e) {
                Log.e(TAG, "Failed to save cropped image", e);
                return false;
            } finally {
                cropped.recycle();
                enhanced.release();
            }
        } catch (Exception e) {
            Log.e(TAG, "Error during perspective crop", e);
            return false;
        } finally {
            original.recycle();
        }
    }

    private static Mat enhanceDocument(Mat document) {
        Mat enhanced = new Mat();
        
        // Convert to grayscale
        Mat gray = new Mat();
        Imgproc.cvtColor(document, gray, Imgproc.COLOR_BGR2GRAY);
        
        // Apply bilateral filter for edge-preserving smoothing
        Mat smoothed = new Mat();
        Imgproc.bilateralFilter(gray, smoothed, 9, 75, 75);
        
        // Apply adaptive thresholding
        Mat binary = new Mat();
        Imgproc.adaptiveThreshold(smoothed, binary, 255, 
            Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C, Imgproc.THRESH_BINARY, 11, 2);
        
        // Apply morphological operations for noise removal
        Mat kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, new Size(3, 3));
        Mat morph = new Mat();
        Imgproc.morphologyEx(binary, morph, Imgproc.MORPH_CLOSE, kernel);
        
        // Convert back to color
        Imgproc.cvtColor(morph, enhanced, Imgproc.COLOR_GRAY2BGR);
        
        // Clean up
        gray.release();
        smoothed.release();
        binary.release();
        kernel.release();
        morph.release();
        
        return enhanced;
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
        Log.d(TAG, "Starting document detection for path: " + path);
        Mat src = Imgcodecs.imread(path);
        if (src.empty()) {
            Log.e(TAG, "Failed to read image for document detection");
            return null;
        }

        try {
            Log.d(TAG, "Preprocessing image");
            // Preprocess image
            Mat preprocessed = preprocessImage(src);
            
            Log.d(TAG, "Finding contours");
            // Find contours
            ArrayList<MatOfPoint> contours = findContours(preprocessed);
            Log.d(TAG, "Found " + contours.size() + " contours");
            
            // Find the best document corners
            Log.d(TAG, "Finding best document corners");
            Corners corners = getCorners(contours, src.size());
            Log.d(TAG, "Document corners found: " + (corners != null));
            
            // Clean up
            preprocessed.release();
            
            return corners;
        } finally {
            src.release();
        }
    }

    private static Mat preprocessImage(Mat src) {
        Log.d(TAG, "Starting image preprocessing");
        Mat processed = new Mat();
        
        // Convert to grayscale
        Mat gray = new Mat();
        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY);
        
        // Apply Gaussian blur
        Mat blurred = new Mat();
        Imgproc.GaussianBlur(gray, blurred, GAUSSIAN_KERNEL_SIZE, 0);
        
        // Apply Canny edge detection
        Mat edges = new Mat();
        Imgproc.Canny(blurred, edges, CANNY_LOW_THRESHOLD, CANNY_HIGH_THRESHOLD);
        
        // Apply morphological operations
        Mat kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, MORPH_KERNEL_SIZE);
        Imgproc.morphologyEx(edges, processed, Imgproc.MORPH_CLOSE, kernel);
        
        // Clean up
        gray.release();
        blurred.release();
        edges.release();
        kernel.release();
        
        Log.d(TAG, "Image preprocessing completed");
        return processed;
    }

    private static ArrayList<MatOfPoint> findContours(Mat src) {
        Log.d(TAG, "Finding contours");
        ArrayList<MatOfPoint> contours = new ArrayList<>();
        Mat hierarchy = new Mat();
        
        Imgproc.findContours(src, contours, hierarchy, Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE);
        
        hierarchy.release();
        Log.d(TAG, "Found " + contours.size() + " contours");
        return contours;
    }

    private static Corners getCorners(ArrayList<MatOfPoint> contours, Size size) {
        Log.d(TAG, "Finding best document corners from " + contours.size() + " contours");
        double maxArea = 0;
        MatOfPoint maxContour = null;
        
        // Find the largest contour
        for (MatOfPoint contour : contours) {
            double area = Imgproc.contourArea(contour);
            if (area > maxArea) {
                maxArea = area;
                maxContour = contour;
            }
        }
        
        if (maxContour == null) {
            Log.d(TAG, "No suitable contour found");
            return null;
        }
        
        // Check if the contour area is within reasonable bounds
        double totalArea = size.width * size.height;
        double areaRatio = maxArea / totalArea;
        
        Log.d(TAG, "Largest contour area ratio: " + areaRatio);
        
        if (areaRatio < MIN_AREA_RATIO || areaRatio > MAX_AREA_RATIO) {
            Log.d(TAG, "Contour area ratio outside acceptable bounds");
            return null;
        }
        
        // Approximate the contour to a polygon
        MatOfPoint2f contour2f = new MatOfPoint2f(maxContour.toArray());
        double peri = Imgproc.arcLength(contour2f, true);
        MatOfPoint2f approx = new MatOfPoint2f();
        
        try {
            Imgproc.approxPolyDP(contour2f, approx, APPROX_POLY_EPSILON * peri, true);
            List<Point> points = approx.toList();
            
            // Check if we have exactly 4 points
            if (points.size() != 4) {
                Log.d(TAG, "Contour has " + points.size() + " points, expected 4");
                return null;
            }
            
            // Sort points in clockwise order
            List<Point> sortedPoints = sortPoints(points);
            Log.d(TAG, "Successfully found 4 document corners");
            return new Corners(sortedPoints, size);
        } finally {
            contour2f.release();
            approx.release();
        }
    }

    private static List<Point> sortPoints(List<Point> points) {
        // Sort points by their sum (x + y)
        points.sort((p1, p2) -> Double.compare(p1.x + p1.y, p2.x + p2.y));
        
        // Get the top-left point
        Point topLeft = points.get(0);
        
        // Sort remaining points by their angle relative to top-left
        points.subList(1, points.size()).sort((p1, p2) -> {
            double angle1 = Math.atan2(p1.y - topLeft.y, p1.x - topLeft.x);
            double angle2 = Math.atan2(p2.y - topLeft.y, p2.x - topLeft.x);
            return Double.compare(angle1, angle2);
        });
        
        return points;
    }

    public static List<Point> detectDocumentCorners(String imagePath) {
        Log.d(TAG, "Starting document detection for path: " + imagePath);
        try {
            // Read the image
            Mat source = Imgcodecs.imread(imagePath);
            if (source.empty()) {
                Log.e(TAG, "Failed to load image");
                return null;
            }
            Log.d(TAG, "Image loaded successfully. Size: " + source.size());

            // Preprocess the image
            Log.d(TAG, "Preprocessing image");
            Mat gray = new Mat();
            Imgproc.cvtColor(source, gray, Imgproc.COLOR_BGR2GRAY);
            Mat blur = new Mat();
            Imgproc.GaussianBlur(gray, blur, new Size(5, 5), 0);
            Mat edges = new Mat();
            Imgproc.Canny(blur, edges, 75, 200);
            Log.d(TAG, "Preprocessing completed");

            // Find contours
            Log.d(TAG, "Finding contours");
            List<MatOfPoint> contours = new ArrayList<>();
            Mat hierarchy = new Mat();
            Imgproc.findContours(edges, contours, hierarchy, Imgproc.RETR_LIST, Imgproc.CHAIN_APPROX_SIMPLE);
            Log.d(TAG, "Found " + contours.size() + " contours");

            // Find the best document corners
            Log.d(TAG, "Finding best document corners");
            List<Point> bestCorners = null;
            double maxArea = 0;

            for (MatOfPoint contour : contours) {
                double area = Imgproc.contourArea(contour);
                if (area > maxArea) {
                    MatOfPoint2f approxCurve = new MatOfPoint2f();
                    MatOfPoint2f contour2f = new MatOfPoint2f(contour.toArray());
                    double epsilon = 0.02 * Imgproc.arcLength(contour2f, true);
                    Imgproc.approxPolyDP(contour2f, approxCurve, epsilon, true);

                    if (approxCurve.total() == 4) {
                        Point[] corners = approxCurve.toArray();
                        bestCorners = Arrays.asList(corners);
                        maxArea = area;
                        Log.d(TAG, "Found potential document with area: " + area);
                    }
                }
            }

            if (bestCorners != null) {
                Log.d(TAG, "Document corners found: " + bestCorners);
                return bestCorners;
            } else {
                Log.w(TAG, "No suitable document corners found");
                return null;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in detectDocumentCorners: " + e.getMessage(), e);
            return null;
        }
    }

    public static String enhanceDocument(String imagePath, String filterType) {
        Log.d(TAG, "Starting document enhancement with filter: " + filterType);
        try {
            Mat source = Imgcodecs.imread(imagePath);
            if (source.empty()) {
                Log.e(TAG, "Failed to load image for enhancement");
                return imagePath;
            }

            Mat result;
            switch (filterType) {
                case "adaptive_threshold":
                    result = applyAdaptiveThreshold(source);
                    break;
                case "otsu_threshold":
                    result = applyOtsuThreshold(source);
                    break;
                case "edge_enhancement":
                    result = applyEdgeEnhancement(source);
                    break;
                case "contrast_enhancement":
                    result = applyContrastEnhancement(source);
                    break;
                default:
                    Log.w(TAG, "Unknown filter type: " + filterType);
                    return imagePath;
            }

            String outputPath = imagePath.replace(".jpg", "_" + filterType + "_enhanced.jpg");
            boolean success = Imgcodecs.imwrite(outputPath, result);
            result.release();
            source.release();

            if (!success) {
                Log.e(TAG, "Failed to save enhanced image");
                return imagePath;
            }

            Log.d(TAG, "Document enhancement completed successfully");
            return outputPath;
        } catch (Exception e) {
            Log.e(TAG, "Error in enhanceDocument: " + e.getMessage(), e);
            return imagePath;
        }
    }

    private static Mat applyAdaptiveThreshold(Mat source) {
        Mat gray = new Mat();
        Imgproc.cvtColor(source, gray, Imgproc.COLOR_BGR2GRAY);
        
        Mat result = new Mat();
        Imgproc.adaptiveThreshold(
            gray, result, 255.0,
            Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C,
            Imgproc.THRESH_BINARY, 11, 2.0
        );
        
        gray.release();
        return result;
    }

    private static Mat applyOtsuThreshold(Mat source) {
        Mat gray = new Mat();
        Imgproc.cvtColor(source, gray, Imgproc.COLOR_BGR2GRAY);
        
        Mat result = new Mat();
        Imgproc.threshold(gray, result, 0.0, 255.0, Imgproc.THRESH_BINARY + Imgproc.THRESH_OTSU);
        
        gray.release();
        return result;
    }

    private static Mat applyEdgeEnhancement(Mat source) {
        Mat gray = new Mat();
        Imgproc.cvtColor(source, gray, Imgproc.COLOR_BGR2GRAY);
        
        Mat edges = new Mat();
        Imgproc.Canny(gray, edges, 50.0, 150.0);
        
        Mat result = new Mat();
        Core.addWeighted(gray, 1.5, edges, 0.5, 0.0, result);
        
        gray.release();
        edges.release();
        return result;
    }

    private static Mat applyContrastEnhancement(Mat source) {
        Mat result = new Mat();
        double alpha = 1.3; // Contrast control
        double beta = 10.0; // Brightness control
        
        Core.convertScaleAbs(source, result, alpha, beta);
        return result;
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

