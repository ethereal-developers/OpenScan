import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  static String route = 'SplashScreen';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      Duration(seconds: 1),
      () => Navigator.of(context).pushReplacementNamed(HomeScreen.route),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Spacer(
              flex: 7,
            ),
            CircleAvatar(
              backgroundColor: primaryColor,
              child: new Container(
                child: Image.asset('assets/scan_g.jpeg'),
              ),
              radius: 130,
            ),
            Spacer(),
            RichText(
              text: TextSpan(
                text: 'Open',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                      text: 'Scan', style: TextStyle(color: secondaryColor))
                ],
              ),
            ),
            Spacer(
              flex: 10,
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Made with ❤ in India',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
