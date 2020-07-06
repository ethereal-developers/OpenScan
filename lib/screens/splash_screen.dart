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
  bool visitingFlag = false;

  Future<void> getFlag() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (preferences.getBool("alreadyVisited") == null) {
      visitingFlag = false;
    } else {
      visitingFlag = true;
    }
    await preferences.setBool('alreadyVisited', true);
  }

  Timer getTimerWid() {
    return Timer(Duration(seconds: 1), () {
      (visitingFlag)
          ? Navigator.of(context).pushReplacementNamed(HomeScreen.route)
          : Navigator.of(context)
              .pushReplacementNamed(GettingStartedScreen.route);
    });
  }

  getFlagInfo() async {
    await getFlag();
  }

  @override
  void initState() {
    super.initState();
    getFlagInfo();
    getTimerWid();
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
