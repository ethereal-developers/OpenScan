//
// This file is auto-generated. Please don't modify it!
//
package org.opencv.video;

import org.opencv.video.DenseOpticalFlow;
import org.opencv.video.DualTVL1OpticalFlow;

// C++: class DualTVL1OpticalFlow
/**
 * "Dual TV L1" Optical Flow Algorithm.
 *
 * The class implements the "Dual TV L1" optical flow algorithm described in CITE: Zach2007 and
 * CITE: Javier2012 .
 * Here are important members of the class that control the algorithm, which you can set after
 * constructing the class instance:
 *
 * <ul>
 *   <li>
 *    member double tau
 *     Time step of the numerical scheme.
 *   </li>
 * </ul>
 *
 * <ul>
 *   <li>
 *    member double lambda
 *     Weight parameter for the data term, attachment parameter. This is the most relevant
 *     parameter, which determines the smoothness of the output. The smaller this parameter is,
 *     the smoother the solutions we obtain. It depends on the range of motions of the images, so
 *     its value should be adapted to each image sequence.
 *   </li>
 * </ul>
 *
 * <ul>
 *   <li>
 *    member double theta
 *     Weight parameter for (u - v)\^2, tightness parameter. It serves as a link between the
 *     attachment and the regularization terms. In theory, it should have a small value in order
 *     to maintain both parts in correspondence. The method is stable for a large range of values
 *     of this parameter.
 *   </li>
 * </ul>
 *
 * <ul>
 *   <li>
 *    member int nscales
 *     Number of scales used to create the pyramid of images.
 *   </li>
 * </ul>
 *
 * <ul>
 *   <li>
 *    member int warps
 *     Number of warpings per scale. Represents the number of times that I1(x+u0) and grad(
 *     I1(x+u0) ) are computed per scale. This is a parameter that assures the stability of the
 *     method. It also affects the running time, so it is a compromise between speed and
 *     accuracy.
 *   </li>
 * </ul>
 *
 * <ul>
 *   <li>
 *    member double epsilon
 *     Stopping criterion threshold used in the numerical scheme, which is a trade-off between
 *     precision and running time. A small value will yield more accurate solutions at the
 *     expense of a slower convergence.
 *   </li>
 * </ul>
 *
 * <ul>
 *   <li>
 *    member int iterations
 *     Stopping criterion iterations number used in the numerical scheme.
 *   </li>
 * </ul>
 *
 * C. Zach, T. Pock and H. Bischof, "A Duality Based Approach for Realtime TV-L1 Optical Flow".
 * Javier Sanchez, Enric Meinhardt-Llopis and Gabriele Facciolo. "TV-L1 Optical Flow Estimation".
 */
public class DualTVL1OpticalFlow extends DenseOpticalFlow {

    protected DualTVL1OpticalFlow(long addr) { super(addr); }

    // internal usage only
    public static DualTVL1OpticalFlow __fromPtr__(long addr) { return new DualTVL1OpticalFlow(addr); }

    //
    // C++:  double cv::DualTVL1OpticalFlow::getTau()
    //

    /**
     * SEE: setTau
     * @return automatically generated
     */
    public double getTau() {
        return getTau_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setTau(double val)
    //

    /**
     *  getTau SEE: getTau
     * @param val automatically generated
     */
    public void setTau(double val) {
        setTau_0(nativeObj, val);
    }


    //
    // C++:  double cv::DualTVL1OpticalFlow::getLambda()
    //

    /**
     * SEE: setLambda
     * @return automatically generated
     */
    public double getLambda() {
        return getLambda_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setLambda(double val)
    //

    /**
     *  getLambda SEE: getLambda
     * @param val automatically generated
     */
    public void setLambda(double val) {
        setLambda_0(nativeObj, val);
    }


    //
    // C++:  double cv::DualTVL1OpticalFlow::getTheta()
    //

    /**
     * SEE: setTheta
     * @return automatically generated
     */
    public double getTheta() {
        return getTheta_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setTheta(double val)
    //

    /**
     *  getTheta SEE: getTheta
     * @param val automatically generated
     */
    public void setTheta(double val) {
        setTheta_0(nativeObj, val);
    }


    //
    // C++:  double cv::DualTVL1OpticalFlow::getGamma()
    //

    /**
     * SEE: setGamma
     * @return automatically generated
     */
    public double getGamma() {
        return getGamma_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setGamma(double val)
    //

    /**
     *  getGamma SEE: getGamma
     * @param val automatically generated
     */
    public void setGamma(double val) {
        setGamma_0(nativeObj, val);
    }


    //
    // C++:  int cv::DualTVL1OpticalFlow::getScalesNumber()
    //

    /**
     * SEE: setScalesNumber
     * @return automatically generated
     */
    public int getScalesNumber() {
        return getScalesNumber_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setScalesNumber(int val)
    //

    /**
     *  getScalesNumber SEE: getScalesNumber
     * @param val automatically generated
     */
    public void setScalesNumber(int val) {
        setScalesNumber_0(nativeObj, val);
    }


    //
    // C++:  int cv::DualTVL1OpticalFlow::getWarpingsNumber()
    //

    /**
     * SEE: setWarpingsNumber
     * @return automatically generated
     */
    public int getWarpingsNumber() {
        return getWarpingsNumber_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setWarpingsNumber(int val)
    //

    /**
     *  getWarpingsNumber SEE: getWarpingsNumber
     * @param val automatically generated
     */
    public void setWarpingsNumber(int val) {
        setWarpingsNumber_0(nativeObj, val);
    }


    //
    // C++:  double cv::DualTVL1OpticalFlow::getEpsilon()
    //

    /**
     * SEE: setEpsilon
     * @return automatically generated
     */
    public double getEpsilon() {
        return getEpsilon_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setEpsilon(double val)
    //

    /**
     *  getEpsilon SEE: getEpsilon
     * @param val automatically generated
     */
    public void setEpsilon(double val) {
        setEpsilon_0(nativeObj, val);
    }


    //
    // C++:  int cv::DualTVL1OpticalFlow::getInnerIterations()
    //

    /**
     * SEE: setInnerIterations
     * @return automatically generated
     */
    public int getInnerIterations() {
        return getInnerIterations_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setInnerIterations(int val)
    //

    /**
     *  getInnerIterations SEE: getInnerIterations
     * @param val automatically generated
     */
    public void setInnerIterations(int val) {
        setInnerIterations_0(nativeObj, val);
    }


    //
    // C++:  int cv::DualTVL1OpticalFlow::getOuterIterations()
    //

    /**
     * SEE: setOuterIterations
     * @return automatically generated
     */
    public int getOuterIterations() {
        return getOuterIterations_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setOuterIterations(int val)
    //

    /**
     *  getOuterIterations SEE: getOuterIterations
     * @param val automatically generated
     */
    public void setOuterIterations(int val) {
        setOuterIterations_0(nativeObj, val);
    }


    //
    // C++:  bool cv::DualTVL1OpticalFlow::getUseInitialFlow()
    //

    /**
     * SEE: setUseInitialFlow
     * @return automatically generated
     */
    public boolean getUseInitialFlow() {
        return getUseInitialFlow_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setUseInitialFlow(bool val)
    //

    /**
     *  getUseInitialFlow SEE: getUseInitialFlow
     * @param val automatically generated
     */
    public void setUseInitialFlow(boolean val) {
        setUseInitialFlow_0(nativeObj, val);
    }


    //
    // C++:  double cv::DualTVL1OpticalFlow::getScaleStep()
    //

    /**
     * SEE: setScaleStep
     * @return automatically generated
     */
    public double getScaleStep() {
        return getScaleStep_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setScaleStep(double val)
    //

    /**
     *  getScaleStep SEE: getScaleStep
     * @param val automatically generated
     */
    public void setScaleStep(double val) {
        setScaleStep_0(nativeObj, val);
    }


    //
    // C++:  int cv::DualTVL1OpticalFlow::getMedianFiltering()
    //

    /**
     * SEE: setMedianFiltering
     * @return automatically generated
     */
    public int getMedianFiltering() {
        return getMedianFiltering_0(nativeObj);
    }


    //
    // C++:  void cv::DualTVL1OpticalFlow::setMedianFiltering(int val)
    //

    /**
     *  getMedianFiltering SEE: getMedianFiltering
     * @param val automatically generated
     */
    public void setMedianFiltering(int val) {
        setMedianFiltering_0(nativeObj, val);
    }


    //
    // C++: static Ptr_DualTVL1OpticalFlow cv::DualTVL1OpticalFlow::create(double tau = 0.25, double lambda = 0.15, double theta = 0.3, int nscales = 5, int warps = 5, double epsilon = 0.01, int innnerIterations = 30, int outerIterations = 10, double scaleStep = 0.8, double gamma = 0.0, int medianFiltering = 5, bool useInitialFlow = false)
    //

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @param lambda automatically generated
     * @param theta automatically generated
     * @param nscales automatically generated
     * @param warps automatically generated
     * @param epsilon automatically generated
     * @param innnerIterations automatically generated
     * @param outerIterations automatically generated
     * @param scaleStep automatically generated
     * @param gamma automatically generated
     * @param medianFiltering automatically generated
     * @param useInitialFlow automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations, int outerIterations, double scaleStep, double gamma, int medianFiltering, boolean useInitialFlow) {
        return DualTVL1OpticalFlow.__fromPtr__(create_0(tau, lambda, theta, nscales, warps, epsilon, innnerIterations, outerIterations, scaleStep, gamma, medianFiltering, useInitialFlow));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @param lambda automatically generated
     * @param theta automatically generated
     * @param nscales automatically generated
     * @param warps automatically generated
     * @param epsilon automatically generated
     * @param innnerIterations automatically generated
     * @param outerIterations automatically generated
     * @param scaleStep automatically generated
     * @param gamma automatically generated
     * @param medianFiltering automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations, int outerIterations, double scaleStep, double gamma, int medianFiltering) {
        return DualTVL1OpticalFlow.__fromPtr__(create_1(tau, lambda, theta, nscales, warps, epsilon, innnerIterations, outerIterations, scaleStep, gamma, medianFiltering));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @param lambda automatically generated
     * @param theta automatically generated
     * @param nscales automatically generated
     * @param warps automatically generated
     * @param epsilon automatically generated
     * @param innnerIterations automatically generated
     * @param outerIterations automatically generated
     * @param scaleStep automatically generated
     * @param gamma automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations, int outerIterations, double scaleStep, double gamma) {
        return DualTVL1OpticalFlow.__fromPtr__(create_2(tau, lambda, theta, nscales, warps, epsilon, innnerIterations, outerIterations, scaleStep, gamma));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @param lambda automatically generated
     * @param theta automatically generated
     * @param nscales automatically generated
     * @param warps automatically generated
     * @param epsilon automatically generated
     * @param innnerIterations automatically generated
     * @param outerIterations automatically generated
     * @param scaleStep automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations, int outerIterations, double scaleStep) {
        return DualTVL1OpticalFlow.__fromPtr__(create_3(tau, lambda, theta, nscales, warps, epsilon, innnerIterations, outerIterations, scaleStep));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @param lambda automatically generated
     * @param theta automatically generated
     * @param nscales automatically generated
     * @param warps automatically generated
     * @param epsilon automatically generated
     * @param innnerIterations automatically generated
     * @param outerIterations automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations, int outerIterations) {
        return DualTVL1OpticalFlow.__fromPtr__(create_4(tau, lambda, theta, nscales, warps, epsilon, innnerIterations, outerIterations));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @param lambda automatically generated
     * @param theta automatically generated
     * @param nscales automatically generated
     * @param warps automatically generated
     * @param epsilon automatically generated
     * @param innnerIterations automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations) {
        return DualTVL1OpticalFlow.__fromPtr__(create_5(tau, lambda, theta, nscales, warps, epsilon, innnerIterations));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @param lambda automatically generated
     * @param theta automatically generated
     * @param nscales automatically generated
     * @param warps automatically generated
     * @param epsilon automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau, double lambda, double theta, int nscales, int warps, double epsilon) {
        return DualTVL1OpticalFlow.__fromPtr__(create_6(tau, lambda, theta, nscales, warps, epsilon));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @param lambda automatically generated
     * @param theta automatically generated
     * @param nscales automatically generated
     * @param warps automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau, double lambda, double theta, int nscales, int warps) {
        return DualTVL1OpticalFlow.__fromPtr__(create_7(tau, lambda, theta, nscales, warps));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @param lambda automatically generated
     * @param theta automatically generated
     * @param nscales automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau, double lambda, double theta, int nscales) {
        return DualTVL1OpticalFlow.__fromPtr__(create_8(tau, lambda, theta, nscales));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @param lambda automatically generated
     * @param theta automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau, double lambda, double theta) {
        return DualTVL1OpticalFlow.__fromPtr__(create_9(tau, lambda, theta));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @param lambda automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau, double lambda) {
        return DualTVL1OpticalFlow.__fromPtr__(create_10(tau, lambda));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @param tau automatically generated
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create(double tau) {
        return DualTVL1OpticalFlow.__fromPtr__(create_11(tau));
    }

    /**
     * Creates instance of cv::DualTVL1OpticalFlow
     * @return automatically generated
     */
    public static DualTVL1OpticalFlow create() {
        return DualTVL1OpticalFlow.__fromPtr__(create_12());
    }


    @Override
    protected void finalize() throws Throwable {
        delete(nativeObj);
    }



    // C++:  double cv::DualTVL1OpticalFlow::getTau()
    private static native double getTau_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setTau(double val)
    private static native void setTau_0(long nativeObj, double val);

    // C++:  double cv::DualTVL1OpticalFlow::getLambda()
    private static native double getLambda_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setLambda(double val)
    private static native void setLambda_0(long nativeObj, double val);

    // C++:  double cv::DualTVL1OpticalFlow::getTheta()
    private static native double getTheta_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setTheta(double val)
    private static native void setTheta_0(long nativeObj, double val);

    // C++:  double cv::DualTVL1OpticalFlow::getGamma()
    private static native double getGamma_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setGamma(double val)
    private static native void setGamma_0(long nativeObj, double val);

    // C++:  int cv::DualTVL1OpticalFlow::getScalesNumber()
    private static native int getScalesNumber_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setScalesNumber(int val)
    private static native void setScalesNumber_0(long nativeObj, int val);

    // C++:  int cv::DualTVL1OpticalFlow::getWarpingsNumber()
    private static native int getWarpingsNumber_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setWarpingsNumber(int val)
    private static native void setWarpingsNumber_0(long nativeObj, int val);

    // C++:  double cv::DualTVL1OpticalFlow::getEpsilon()
    private static native double getEpsilon_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setEpsilon(double val)
    private static native void setEpsilon_0(long nativeObj, double val);

    // C++:  int cv::DualTVL1OpticalFlow::getInnerIterations()
    private static native int getInnerIterations_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setInnerIterations(int val)
    private static native void setInnerIterations_0(long nativeObj, int val);

    // C++:  int cv::DualTVL1OpticalFlow::getOuterIterations()
    private static native int getOuterIterations_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setOuterIterations(int val)
    private static native void setOuterIterations_0(long nativeObj, int val);

    // C++:  bool cv::DualTVL1OpticalFlow::getUseInitialFlow()
    private static native boolean getUseInitialFlow_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setUseInitialFlow(bool val)
    private static native void setUseInitialFlow_0(long nativeObj, boolean val);

    // C++:  double cv::DualTVL1OpticalFlow::getScaleStep()
    private static native double getScaleStep_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setScaleStep(double val)
    private static native void setScaleStep_0(long nativeObj, double val);

    // C++:  int cv::DualTVL1OpticalFlow::getMedianFiltering()
    private static native int getMedianFiltering_0(long nativeObj);

    // C++:  void cv::DualTVL1OpticalFlow::setMedianFiltering(int val)
    private static native void setMedianFiltering_0(long nativeObj, int val);

    // C++: static Ptr_DualTVL1OpticalFlow cv::DualTVL1OpticalFlow::create(double tau = 0.25, double lambda = 0.15, double theta = 0.3, int nscales = 5, int warps = 5, double epsilon = 0.01, int innnerIterations = 30, int outerIterations = 10, double scaleStep = 0.8, double gamma = 0.0, int medianFiltering = 5, bool useInitialFlow = false)
    private static native long create_0(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations, int outerIterations, double scaleStep, double gamma, int medianFiltering, boolean useInitialFlow);
    private static native long create_1(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations, int outerIterations, double scaleStep, double gamma, int medianFiltering);
    private static native long create_2(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations, int outerIterations, double scaleStep, double gamma);
    private static native long create_3(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations, int outerIterations, double scaleStep);
    private static native long create_4(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations, int outerIterations);
    private static native long create_5(double tau, double lambda, double theta, int nscales, int warps, double epsilon, int innnerIterations);
    private static native long create_6(double tau, double lambda, double theta, int nscales, int warps, double epsilon);
    private static native long create_7(double tau, double lambda, double theta, int nscales, int warps);
    private static native long create_8(double tau, double lambda, double theta, int nscales);
    private static native long create_9(double tau, double lambda, double theta);
    private static native long create_10(double tau, double lambda);
    private static native long create_11(double tau);
    private static native long create_12();

    // native support for java finalize()
    private static native void delete(long nativeObj);

}
