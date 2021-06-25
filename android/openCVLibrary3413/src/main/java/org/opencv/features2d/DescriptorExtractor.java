//
// This file is auto-generated. Please don't modify it!
//
package org.opencv.features2d;

import java.util.ArrayList;
import java.util.List;
import org.opencv.core.Mat;
import org.opencv.core.MatOfKeyPoint;
import org.opencv.features2d.DescriptorExtractor;
import org.opencv.utils.Converters;

// C++: class javaDescriptorExtractor
/**
 * @deprecated
 */
@Deprecated
public class DescriptorExtractor {

    protected final long nativeObj;
    protected DescriptorExtractor(long addr) { nativeObj = addr; }

    public long getNativeObjAddr() { return nativeObj; }

    // internal usage only
    public static DescriptorExtractor __fromPtr__(long addr) { return new DescriptorExtractor(addr); }

    private static final int
            OPPONENTEXTRACTOR = 1000;


    // C++: enum <unnamed>
    public static final int
            SIFT = 1,
            SURF = 2,
            ORB = 3,
            BRIEF = 4,
            BRISK = 5,
            FREAK = 6,
            AKAZE = 7,
            OPPONENT_SIFT = OPPONENTEXTRACTOR + SIFT,
            OPPONENT_SURF = OPPONENTEXTRACTOR + SURF,
            OPPONENT_ORB = OPPONENTEXTRACTOR + ORB,
            OPPONENT_BRIEF = OPPONENTEXTRACTOR + BRIEF,
            OPPONENT_BRISK = OPPONENTEXTRACTOR + BRISK,
            OPPONENT_FREAK = OPPONENTEXTRACTOR + FREAK,
            OPPONENT_AKAZE = OPPONENTEXTRACTOR + AKAZE;


    //
    // C++:  void cv::javaDescriptorExtractor::compute(Mat image, vector_KeyPoint& keypoints, Mat descriptors)
    //

    public void compute(Mat image, MatOfKeyPoint keypoints, Mat descriptors) {
        Mat keypoints_mat = keypoints;
        compute_0(nativeObj, image.nativeObj, keypoints_mat.nativeObj, descriptors.nativeObj);
    }


    //
    // C++:  void cv::javaDescriptorExtractor::compute(vector_Mat images, vector_vector_KeyPoint& keypoints, vector_Mat& descriptors)
    //

    public void compute(List<Mat> images, List<MatOfKeyPoint> keypoints, List<Mat> descriptors) {
        Mat images_mat = Converters.vector_Mat_to_Mat(images);
        List<Mat> keypoints_tmplm = new ArrayList<Mat>((keypoints != null) ? keypoints.size() : 0);
        Mat keypoints_mat = Converters.vector_vector_KeyPoint_to_Mat(keypoints, keypoints_tmplm);
        Mat descriptors_mat = new Mat();
        compute_1(nativeObj, images_mat.nativeObj, keypoints_mat.nativeObj, descriptors_mat.nativeObj);
        Converters.Mat_to_vector_vector_KeyPoint(keypoints_mat, keypoints);
        keypoints_mat.release();
        Converters.Mat_to_vector_Mat(descriptors_mat, descriptors);
        descriptors_mat.release();
    }


    //
    // C++:  int cv::javaDescriptorExtractor::descriptorSize()
    //

    public int descriptorSize() {
        return descriptorSize_0(nativeObj);
    }


    //
    // C++:  int cv::javaDescriptorExtractor::descriptorType()
    //

    public int descriptorType() {
        return descriptorType_0(nativeObj);
    }


    //
    // C++:  bool cv::javaDescriptorExtractor::empty()
    //

    public boolean empty() {
        return empty_0(nativeObj);
    }


    //
    // C++: static Ptr_javaDescriptorExtractor cv::javaDescriptorExtractor::create(int extractorType)
    //

    public static DescriptorExtractor create(int extractorType) {
        return DescriptorExtractor.__fromPtr__(create_0(extractorType));
    }


    //
    // C++:  void cv::javaDescriptorExtractor::write(String fileName)
    //

    public void write(String fileName) {
        write_0(nativeObj, fileName);
    }


    //
    // C++:  void cv::javaDescriptorExtractor::read(String fileName)
    //

    public void read(String fileName) {
        read_0(nativeObj, fileName);
    }


    @Override
    protected void finalize() throws Throwable {
        delete(nativeObj);
    }



    // C++:  void cv::javaDescriptorExtractor::compute(Mat image, vector_KeyPoint& keypoints, Mat descriptors)
    private static native void compute_0(long nativeObj, long image_nativeObj, long keypoints_mat_nativeObj, long descriptors_nativeObj);

    // C++:  void cv::javaDescriptorExtractor::compute(vector_Mat images, vector_vector_KeyPoint& keypoints, vector_Mat& descriptors)
    private static native void compute_1(long nativeObj, long images_mat_nativeObj, long keypoints_mat_nativeObj, long descriptors_mat_nativeObj);

    // C++:  int cv::javaDescriptorExtractor::descriptorSize()
    private static native int descriptorSize_0(long nativeObj);

    // C++:  int cv::javaDescriptorExtractor::descriptorType()
    private static native int descriptorType_0(long nativeObj);

    // C++:  bool cv::javaDescriptorExtractor::empty()
    private static native boolean empty_0(long nativeObj);

    // C++: static Ptr_javaDescriptorExtractor cv::javaDescriptorExtractor::create(int extractorType)
    private static native long create_0(int extractorType);

    // C++:  void cv::javaDescriptorExtractor::write(String fileName)
    private static native void write_0(long nativeObj, String fileName);

    // C++:  void cv::javaDescriptorExtractor::read(String fileName)
    private static native void read_0(long nativeObj, String fileName);

    // native support for java finalize()
    private static native void delete(long nativeObj);

}
