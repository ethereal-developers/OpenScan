import 'package:flutter/material.dart';
import 'package:openscan/Utilities/constants.dart';

class CustomPopupMenuButton extends StatelessWidget {
  final Function onSelected;
  final List<String> itemList;
  CustomPopupMenuButton({@required this.onSelected, this.itemList});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: primaryColor.withOpacity(0.95),
      elevation: 30,
      offset: Offset.fromDirection(20, 20),
      icon: Icon(Icons.more_vert),
      itemBuilder: (context) {
        return List.generate(
          3,
          (index) => PopupMenuItem(
            value: itemList[index],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(itemList[index]),
                SizedBox(width: 10),
                Icon(
                  Icons.select_all,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
