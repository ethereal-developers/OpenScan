import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openscan/view/screens/demo_screen.dart';
import 'package:openscan/view/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  static String route = 'SplashScreen';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool visitingFlag = false;
  bool databaseFlag = false;

  void getFlag() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (preferences.getBool("alreadyVisited") != null) {
      visitingFlag = true;
    }
    await preferences.setBool('alreadyVisited', true);
    if (preferences.getBool("database") != null) {
      databaseFlag = true;
    }
    await preferences.setBool('database', true);
  }

  void getTimerWid() {
    Timer(
      Duration(milliseconds: 500),
      () {
        (visitingFlag)
            ? Navigator.of(context).pushReplacementNamed(HomeScreen.route)
            : Navigator.of(context).pushReplacementNamed(DemoScreen.route);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getFlag();
    getTimerWid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Spacer(
              flex: 7,
            ),
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
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
                      text: 'Scan',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary))
                ],
              ),
            ),
            Spacer(
              flex: 10,
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Made with ❤ from India',
                style: TextStyle(
                  fontSize: 13,
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
