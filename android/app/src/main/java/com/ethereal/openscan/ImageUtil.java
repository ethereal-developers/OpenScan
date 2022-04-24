package com.ethereal.openscan;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.util.Log;

import org.opencv.android.OpenCVLoader;
import org.opencv.android.Utils;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.imgproc.Imgproc;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.util.HashMap;
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
        try {
            Bitmap original = BitmapFactory.decodeFile(path);
            int height = original.getHeight();
            int width = original.getWidth();

            imageSizeMap.put("height", height);
            imageSizeMap.put("width",width);
        } catch (Exception e) {
            Log.e(TAG, "Exception while getting image size --> ", e);
        }
        return imageSizeMap;
    }

    public static boolean rotateImage(String path, int degree) {
        Log.d(TAG, "Rotate image called");
        try {
            Bitmap original = BitmapFactory.decodeFile(path);
            Log.d(TAG, "Rotate image called");
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

    private static class DetectDocumentUtil {

    }
}
