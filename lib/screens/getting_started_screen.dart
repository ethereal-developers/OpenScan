import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/Utilities/slide.dart';
import 'package:openscan/Widgets/slide_dots.dart';
import 'package:openscan/Widgets/slide_item.dart';
import 'package:openscan/screens/home_screen.dart';

class GettingStartedScreen extends StatefulWidget {
  static String route = 'GettingStarted';

  GettingStartedScreen({this.showSkip});

  final bool showSkip;

  @override
  _GettingStartedScreenState createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> {
  int _currentPage = 0;

  _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryColor,
        leading: (!widget.showSkip)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'How to use the app?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: (widget.showSkip)
            ? <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .pushReplacementNamed(HomeScreen.route);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 10, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Center(
                            child: Text(
                          'Skip',
                          style: TextStyle(color: secondaryColor, fontSize: 13),
                        )),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 17,
                          color: secondaryColor,
                        )
                      ],
                    ),
                  ),
                )
              ]
            : null,
      ),
      body: Container(
        color: primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: AlignmentDirectional.bottomCenter,
                  children: <Widget>[
                    Theme(
                      data: Theme.of(context).copyWith(
                        accentColor: primaryColor,
                      ),
                      child: PageView.builder(
                        scrollDirection: Axis.horizontal,
                        onPageChanged: _onPageChanged,
                        itemCount: slideList.length,
                        itemBuilder: (ctx, i) => SlideItem(i),
                      ),
                    ),
                    Stack(
                      alignment: AlignmentDirectional.topStart,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(bottom: 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              for (int i = 0; i < slideList.length; i++)
                                (i == _currentPage)
                                    ? SlideDots(true)
                                    : SlideDots(false)
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
