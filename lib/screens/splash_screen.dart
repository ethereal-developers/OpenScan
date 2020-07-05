import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/screens/getting_started_screen.dart';
import 'package:openscan/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  static String route = 'SplashScreen';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool visitingFlag;

  getFlag() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    visitingFlag = preferences.getBool("alreadyVisited") ?? false;
    preferences.setBool('alreadyVisited', true);
  }

  @override
  void initState() {
    super.initState();
    getFlag();
    Timer(Duration(seconds: 1), () {
      (!visitingFlag)
          ? Navigator.of(context).pushReplacementNamed(HomeScreen.route)
          : Navigator.of(context)
              .pushReplacementNamed(GettingStartedScreen.route);
    });
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
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
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
                  fontSize: 11,
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
