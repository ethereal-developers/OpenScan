import 'package:flutter/material.dart';
import 'package:openscan/Utilities/constants.dart';

class CustomFAB extends StatefulWidget {
  final Function onPressed;
  final Function onPressedQuick;

  CustomFAB({
    this.onPressed,
    this.onPressedQuick,
  });

  @override
  _CustomFABState createState() => _CustomFABState();
}

class _CustomFABState extends State<CustomFAB>
    with SingleTickerProviderStateMixin {
  AnimationController animationController;
  Animation degOneTranslationAnimation,
      degTwoTranslationAnimation,
      degThreeTranslationAnimation,
      degFourTranslationAnimation;
  Animation rotationAnimation;

  double getRadiansFromDegree(double degree) {
    double unitRadian = 57.295779513;
    return degree / unitRadian;
  }

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250),);
//    degOneTranslationAnimation = TweenSequence([
//      TweenSequenceItem<double>(tween: Tween<double >(begin: 0.0,end: 1.2), weight: 75.0),
//      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.2,end: 1.0), weight: 25.0),
//    ]).animate(animationController);
    degTwoTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.4), weight: 55.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.4, end: 1.0), weight: 45.0),
    ]).animate(animationController);
    degThreeTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.75), weight: 35.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.75, end: 1.0), weight: 65.0),
    ]).animate(animationController);
    degFourTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 1.7), weight: 50.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.7, end: 1.0), weight: 50.0),
    ]).animate(animationController);
    rotationAnimation = Tween<double>(begin: 180.0, end: 0.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut));
    super.initState();
    animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: <Widget>[
        IgnorePointer(
          child: Container(
            height: 150.0,
            width: 150.0,
          ),
        ),
//                    Transform.translate(
//                      offset: Offset.fromDirection(getRadiansFromDegree(270),
//                          degOneTranslationAnimation.value * 100),
//                      child: Transform(
//                        transform: Matrix4.rotationZ(
//                            getRadiansFromDegree(rotationAnimation.value))
//                          ..scale(degOneTranslationAnimation.value),
//                        alignment: Alignment.center,
//                        child: CircularButton(
//                          color: Colors.blue,
//                          width: 50,
//                          height: 50,
//                          icon: Icon(
//                            Icons.add,
//                            color: Colors.white,
//                          ),
//                          onClick: () {
//                            print('First Button');
//                          },
//                        ),
//                      ),
//                    ),
        Transform.translate(
          offset: Offset.fromDirection(getRadiansFromDegree(250),
              degTwoTranslationAnimation.value * 100),
          child: Transform(
            transform:
                Matrix4.rotationZ(getRadiansFromDegree(rotationAnimation.value))
                  ..scale(degTwoTranslationAnimation.value),
            alignment: Alignment.center,
            child: CircularButton(
              color: Colors.black,
              width: 50,
              height: 50,
              icon: Icon(
                Icons.camera_enhance,
                color: primaryColor,
              ),
              onClick: widget.onPressedQuick,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset.fromDirection(getRadiansFromDegree(195),
              degThreeTranslationAnimation.value * 100),
          child: Transform(
            transform:
                Matrix4.rotationZ(getRadiansFromDegree(rotationAnimation.value))
                  ..scale(degThreeTranslationAnimation.value),
            alignment: Alignment.center,
            child: CircularButton(
              color: Colors.orangeAccent,
              width: 50,
              height: 50,
              icon: Icon(
                Icons.camera_alt,
                color: primaryColor,
              ),
              onClick: widget.onPressed,
            ),
          ),
        ),
        Transform(
          transform:
              Matrix4.rotationZ(getRadiansFromDegree(rotationAnimation.value)),
          alignment: Alignment.center,
          child: CircularButton(
            color: secondaryColor,
            width: 60,
            height: 60,
            icon: Icon(
              Icons.camera,
              color: primaryColor,
              size: degFourTranslationAnimation.value * 25,
            ),
            onClick: () {
              if (animationController.isCompleted) {
                animationController.reverse();
              } else {
                animationController.forward();
              }
            },
          ),
        )
      ],
    );
  }
}

class CircularButton extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Icon icon;
  final Function onClick;

  CircularButton(
      {this.color, this.width, this.height, this.icon, this.onClick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: secondaryColor,
        shape: BoxShape.circle,
      ),
      width: width,
      height: height,
      child: IconButton(
        icon: icon,
        color: primaryColor,
        enableFeedback: true,
        onPressed: onClick,
      ),
    );
  }
}
