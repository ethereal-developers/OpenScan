//
// This file is auto-generated. Please don't modify it!
//
package org.opencv.features2d;

import java.util.ArrayList;
import java.util.List;
import org.opencv.core.Mat;
import org.opencv.core.MatOfKeyPoint;
import org.opencv.features2d.FeatureDetector;
import org.opencv.utils.Converters;

// C++: class javaFeatureDetector
/**
 * @deprecated Please use direct instantiation of Feature2D classes
 */
@Deprecated
public class FeatureDetector {

    protected final long nativeObj;
    protected FeatureDetector(long addr) { nativeObj = addr; }

    public long getNativeObjAddr() { return nativeObj; }

    // internal usage only
    public static FeatureDetector __fromPtr__(long addr) { return new FeatureDetector(addr); }

    private static final int
            GRIDDETECTOR = 1000,
            PYRAMIDDETECTOR = 2000,
            DYNAMICDETECTOR = 3000;


    // C++: enum <unnamed>
    public static final int
            FAST = 1,
            STAR = 2,
            SIFT = 3,
            SURF = 4,
            ORB = 5,
            MSER = 6,
            GFTT = 7,
            HARRIS = 8,
            SIMPLEBLOB = 9,
            DENSE = 10,
            BRISK = 11,
            AKAZE = 12,
            GRID_FAST = GRIDDETECTOR + FAST,
            GRID_STAR = GRIDDETECTOR + STAR,
            GRID_SIFT = GRIDDETECTOR + SIFT,
            GRID_SURF = GRIDDETECTOR + SURF,
            GRID_ORB = GRIDDETECTOR + ORB,
            GRID_MSER = GRIDDETECTOR + MSER,
            GRID_GFTT = GRIDDETECTOR + GFTT,
            GRID_HARRIS = GRIDDETECTOR + HARRIS,
            GRID_SIMPLEBLOB = GRIDDETECTOR + SIMPLEBLOB,
            GRID_DENSE = GRIDDETECTOR + DENSE,
            GRID_BRISK = GRIDDETECTOR + BRISK,
            GRID_AKAZE = GRIDDETECTOR + AKAZE,
            PYRAMID_FAST = PYRAMIDDETECTOR + FAST,
            PYRAMID_STAR = PYRAMIDDETECTOR + STAR,
            PYRAMID_SIFT = PYRAMIDDETECTOR + SIFT,
            PYRAMID_SURF = PYRAMIDDETECTOR + SURF,
            PYRAMID_ORB = PYRAMIDDETECTOR + ORB,
            PYRAMID_MSER = PYRAMIDDETECTOR + MSER,
            PYRAMID_GFTT = PYRAMIDDETECTOR + GFTT,
            PYRAMID_HARRIS = PYRAMIDDETECTOR + HARRIS,
            PYRAMID_SIMPLEBLOB = PYRAMIDDETECTOR + SIMPLEBLOB,
            PYRAMID_DENSE = PYRAMIDDETECTOR + DENSE,
            PYRAMID_BRISK = PYRAMIDDETECTOR + BRISK,
            PYRAMID_AKAZE = PYRAMIDDETECTOR + AKAZE,
            DYNAMIC_FAST = DYNAMICDETECTOR + FAST,
            DYNAMIC_STAR = DYNAMICDETECTOR + STAR,
            DYNAMIC_SIFT = DYNAMICDETECTOR + SIFT,
            DYNAMIC_SURF = DYNAMICDETECTOR + SURF,
            DYNAMIC_ORB = DYNAMICDETECTOR + ORB,
            DYNAMIC_MSER = DYNAMICDETECTOR + MSER,
            DYNAMIC_GFTT = DYNAMICDETECTOR + GFTT,
            DYNAMIC_HARRIS = DYNAMICDETECTOR + HARRIS,
            DYNAMIC_SIMPLEBLOB = DYNAMICDETECTOR + SIMPLEBLOB,
            DYNAMIC_DENSE = DYNAMICDETECTOR + DENSE,
            DYNAMIC_BRISK = DYNAMICDETECTOR + BRISK,
            DYNAMIC_AKAZE = DYNAMICDETECTOR + AKAZE;


    //
    // C++:  void cv::javaFeatureDetector::detect(Mat image, vector_KeyPoint& keypoints, Mat mask = Mat())
    //

    public void detect(Mat image, MatOfKeyPoint keypoints, Mat mask) {
        Mat keypoints_mat = keypoints;
        detect_0(nativeObj, image.nativeObj, keypoints_mat.nativeObj, mask.nativeObj);
    }

    public void detect(Mat image, MatOfKeyPoint keypoints) {
        Mat keypoints_mat = keypoints;
        detect_1(nativeObj, image.nativeObj, keypoints_mat.nativeObj);
    }


    //
    // C++:  void cv::javaFeatureDetector::detect(vector_Mat images, vector_vector_KeyPoint& keypoints, vector_Mat masks = std::vector<Mat>())
    //

    public void detect(List<Mat> images, List<MatOfKeyPoint> keypoints, List<Mat> masks) {
        Mat images_mat = Converters.vector_Mat_to_Mat(images);
        Mat keypoints_mat = new Mat();
        Mat masks_mat = Converters.vector_Mat_to_Mat(masks);
        detect_2(nativeObj, images_mat.nativeObj, keypoints_mat.nativeObj, masks_mat.nativeObj);
        Converters.Mat_to_vector_vector_KeyPoint(keypoints_mat, keypoints);
        keypoints_mat.release();
    }

    public void detect(List<Mat> images, List<MatOfKeyPoint> keypoints) {
        Mat images_mat = Converters.vector_Mat_to_Mat(images);
        Mat keypoints_mat = new Mat();
        detect_3(nativeObj, images_mat.nativeObj, keypoints_mat.nativeObj);
        Converters.Mat_to_vector_vector_KeyPoint(keypoints_mat, keypoints);
        keypoints_mat.release();
    }


    //
    // C++:  bool cv::javaFeatureDetector::empty()
    //

    public boolean empty() {
        return empty_0(nativeObj);
    }


    //
    // C++: static Ptr_javaFeatureDetector cv::javaFeatureDetector::create(int detectorType)
    //

    /**
     * supported: FAST STAR SIFT SURF ORB MSER GFTT HARRIS BRISK AKAZE Grid(XXXX) Pyramid(XXXX) Dynamic(XXXX)
     * not supported: SimpleBlob, Dense
     * @deprecated
     * @param detectorType automatically generated
     * @return automatically generated
     */
    @Deprecated
    public static FeatureDetector create(int detectorType) {
        return FeatureDetector.__fromPtr__(create_0(detectorType));
    }


    //
    // C++:  void cv::javaFeatureDetector::write(String fileName)
    //

    public void write(String fileName) {
        write_0(nativeObj, fileName);
    }


    //
    // C++:  void cv::javaFeatureDetector::read(String fileName)
    //

    public void read(String fileName) {
        read_0(nativeObj, fileName);
    }


    @Override
    protected void finalize() throws Throwable {
        delete(nativeObj);
    }



    // C++:  void cv::javaFeatureDetector::detect(Mat image, vector_KeyPoint& keypoints, Mat mask = Mat())
    private static native void detect_0(long nativeObj, long image_nativeObj, long keypoints_mat_nativeObj, long mask_nativeObj);
    private static native void detect_1(long nativeObj, long image_nativeObj, long keypoints_mat_nativeObj);

    // C++:  void cv::javaFeatureDetector::detect(vector_Mat images, vector_vector_KeyPoint& keypoints, vector_Mat masks = std::vector<Mat>())
    private static native void detect_2(long nativeObj, long images_mat_nativeObj, long keypoints_mat_nativeObj, long masks_mat_nativeObj);
    private static native void detect_3(long nativeObj, long images_mat_nativeObj, long keypoints_mat_nativeObj);

    // C++:  bool cv::javaFeatureDetector::empty()
    private static native boolean empty_0(long nativeObj);

    // C++: static Ptr_javaFeatureDetector cv::javaFeatureDetector::create(int detectorType)
    private static native long create_0(int detectorType);

    // C++:  void cv::javaFeatureDetector::write(String fileName)
    private static native void write_0(long nativeObj, String fileName);

    // C++:  void cv::javaFeatureDetector::read(String fileName)
    private static native void read_0(long nativeObj, String fileName);

    // native support for java finalize()
    private static native void delete(long nativeObj);

}
