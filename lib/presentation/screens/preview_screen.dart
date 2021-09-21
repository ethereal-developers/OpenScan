import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:openscan/core/theme/appTheme.dart';

class PreviewScreen extends StatefulWidget {
  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([
      SystemUiOverlay.bottom,
      SystemUiOverlay.top,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        backgroundColor: Colors.white,
        body: Container(
          child: PageView.builder(
            itemBuilder: (context, index) {
              return Container(
                color: Colors.grey,
                child: Center(
                  child: Text(index.toString()),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: AppTheme.primaryColor.withOpacity(0.3),
          elevation: 0,
          child: Container(
            height: 56.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icon(Icons.edit),
                Icon(Icons.crop),
                Icon(Icons.delete),
                Icon(Icons.more_vert)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
