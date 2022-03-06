import 'package:flutter/material.dart';
import 'package:openscan/view/Widgets/demo/slide_dots.dart';
import 'package:openscan/view/Widgets/demo/slide_item.dart';
import 'package:openscan/view/extensions.dart';
import 'package:openscan/view/screens/home_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DemoScreen extends StatefulWidget {
  static String route = 'GettingStarted';

  DemoScreen({this.showSkip});

  final bool? showSkip;

  @override
  _DemoScreenState createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  int _currentPage = 0;
  bool isDone = false;

  _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      if (index == slideList.length - 1) {
        setState(() {
          isDone = true;
        });
      } else {
        setState(() {
          isDone = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        leading: (!widget.showSkip!)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          AppLocalizations.of(context)!.tutorial_title,
          style: TextStyle().appBarStyle,
        ),
        actions: widget.showSkip!
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
                            (isDone) ? AppLocalizations.of(context)!.done : AppLocalizations.of(context)!.skip,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 17,
                              fontWeight: (isDone)
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        (isDone)
                            ? Container(
                                width: 15,
                              )
                            : Icon(
                                Icons.arrow_forward_ios,
                                size: 17,
                                color: Theme.of(context).colorScheme.secondary,
                              )
                      ],
                    ),
                  ),
                )
              ]
            : null,
      ),
      body: Container(
        color: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: AlignmentDirectional.bottomCenter,
                  children: <Widget>[
                    PageView.builder(
                      scrollDirection: Axis.horizontal,
                      onPageChanged: _onPageChanged,
                      itemCount: slideList.length,
                      itemBuilder: (ctx, i) {
                        return SlideItem(i);
                      },
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
