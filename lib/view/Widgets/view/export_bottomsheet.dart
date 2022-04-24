import 'package:flutter/material.dart';
import 'package:openscan/view/Widgets/view/multi_selector.dart';
import 'package:openscan/view/extensions.dart';

class ExportBottomSheet extends StatelessWidget {
  const ExportBottomSheet({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      builder: (context) {
        return Container(
          color: Theme.of(context).primaryColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    20, 15, 20, 10),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Export Document as: ',
                      style: TextStyle().appBarStyle,
                    ),
                    MultiSelector(
                      options: {
                        'PDF': () {},
                        'Image': () {}
                      },
                      selectedIndex: 0,
                    ),
                  ],
                ),
              ),
              Divider(
                thickness: 0.2,
                indent: 8,
                endIndent: 8,
                color: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }
}