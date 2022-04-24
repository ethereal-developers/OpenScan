import 'package:flutter/material.dart';

class MultiSelector extends StatefulWidget {
  final Map<String, void Function()?> options;
  final int selectedIndex;
  const MultiSelector({Key? key, required this.options, required this.selectedIndex}) : super(key: key);

  @override
  State<MultiSelector> createState() => _MultiSelectorState();
}

class _MultiSelectorState extends State<MultiSelector> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.options.length, (index) {
        if (index == 0) {
          return GestureDetector(
            onTap: widget.options.values.toList()[index],
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomLeft: Radius.circular(5),
                ),
                border: Border.all(
                    color:
                        Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
                color: (widget.selectedIndex == index)
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).primaryColor,
              ),
              height: 35,
              width: 70,
              child: Text(
                widget.options.keys.toList()[index],
                style: TextStyle(
                  color: (widget.selectedIndex == index)
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
              alignment: Alignment.center,
            ),
          );
        } else if (index == widget.options.length - 1) {
          return GestureDetector(
            onTap: widget.options.values.toList()[index],
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                ),
                color: (widget.selectedIndex == index)
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).primaryColor,
              ),
              height: 35,
              width: 70,
              child: Text(
                widget.options.keys.toList()[index],
                style: TextStyle(
                  color: (widget.selectedIndex == index)
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
              alignment: Alignment.center,
            ),
          );
        }
        return GestureDetector(
            onTap: widget.options.values.toList()[index],
          child: Container(
            decoration: BoxDecoration(
              color: (widget.selectedIndex == index)
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).primaryColor,
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              ),
            ),
            height: 35,
            width: 70,
            child: Text(
              widget.options.keys.toList()[index],
              style: TextStyle(
                color: (widget.selectedIndex == index)
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
            alignment: Alignment.center,
          ),
        );
      }),
    );
  }
}
