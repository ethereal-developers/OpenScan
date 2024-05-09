import 'package:flutter/material.dart';

class CustomPopupMenuButton extends StatelessWidget {
  final void Function(String) onSelected;
  final Map<String, dynamic>? itemsMap;
  // final Map<>

  CustomPopupMenuButton({required this.onSelected, this.itemsMap});

  @override
  Widget build(BuildContext context) {
    List<MapEntry> items = itemsMap!.entries.toList();

    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: Theme.of(context).primaryColor.withOpacity(0.95),
      elevation: 30,
      offset: Offset.fromDirection(20, 20),
      icon: Icon(Icons.more_vert_rounded),
      itemBuilder: (context) {
        return List.generate(
          items.length,
          (index) => PopupMenuItem(
            value: items[index].key,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(items[index].key),
                SizedBox(width: 14),
                Icon(
                  items[index].value,
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
