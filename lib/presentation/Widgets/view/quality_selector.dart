import 'package:flutter/material.dart';
import 'package:openscan/core/constants.dart';

class QualitySelector extends StatefulWidget {
  final int imageQuality;
  final Function qualitySelected;
  const QualitySelector({
    this.imageQuality,
    this.qualitySelected,
  });

  @override
  _QualitySelectorState createState() => _QualitySelectorState();
}

class _QualitySelectorState extends State<QualitySelector> {
  int quality;

  @override
  void initState() {
    super.initState();
    quality = widget.imageQuality;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 10),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Export Quality',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Select export quality:'),
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (quality != 1) {
                    quality = 1;
                    setState(() {});
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                    ),
                    border: Border.all(color: secondaryColor.withOpacity(0.5)),
                    color: (quality == 1) ? secondaryColor : primaryColor,
                  ),
                  height: 35,
                  width: 70,
                  child: Text(
                    'Low',
                    style: TextStyle(
                      color: (quality == 1) ? primaryColor : secondaryColor,
                    ),
                  ),
                  alignment: Alignment.center,
                ),
              ),
              SizedBox(
                width: 1,
              ),
              GestureDetector(
                onTap: () {
                  if (quality != 2) {
                    quality = 2;
                    setState(() {});
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: (quality == 2) ? secondaryColor : primaryColor,
                    border: Border.all(
                      color: secondaryColor.withOpacity(0.5),
                    ),
                  ),
                  height: 35,
                  width: 70,
                  child: Text(
                    'Medium',
                    style: TextStyle(
                      color: (quality == 2) ? primaryColor : secondaryColor,
                    ),
                  ),
                  alignment: Alignment.center,
                ),
              ),
              SizedBox(
                width: 1,
              ),
              GestureDetector(
                onTap: () {
                  if (quality != 3) {
                    quality = 3;
                    setState(() {});
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                    border: Border.all(
                      color: secondaryColor.withOpacity(0.5),
                    ),
                    color: (quality == 3) ? secondaryColor : primaryColor,
                  ),
                  height: 35,
                  width: 70,
                  child: Text(
                    'High',
                    style: TextStyle(
                      color: (quality == 3) ? primaryColor : secondaryColor,
                    ),
                  ),
                  alignment: Alignment.center,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  widget.qualitySelected(quality);
                },
                child: Text(
                  'Done',
                  style: TextStyle(color: secondaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
