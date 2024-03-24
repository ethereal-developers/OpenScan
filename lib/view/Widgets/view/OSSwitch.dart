import 'package:flutter/material.dart';

class OSSwitch extends StatefulWidget {
  final List<String> options;
  final Function onPressed;
  const OSSwitch({
    Key? key,
    required this.options,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<OSSwitch> createState() => _OSSwitchState();
}

class _OSSwitchState extends State<OSSwitch> {
  late String selectedIndex;

  BorderRadius? getBorderRadius(index) {
    if (index == 0) {
      return BorderRadius.only(
        topLeft: Radius.circular(5),
        bottomLeft: Radius.circular(5),
      );
    } else if (index == widget.options.length - 1) {
      return BorderRadius.only(
        topRight: Radius.circular(5),
        bottomRight: Radius.circular(5),
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.options[0];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        widget.options.length,
        (index) {
          Function()? onTap = () {
            setState(() {
              selectedIndex = widget.options[index];
            });
            widget.onPressed(selectedIndex);
          };

          return GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: getBorderRadius(index),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                ),
                color: (selectedIndex == widget.options[index])
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).primaryColor,
              ),
              height: 35,
              width: 70,
              child: Text(
                widget.options[index],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: (selectedIndex == widget.options[index])
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
              alignment: Alignment.center,
            ),
          );
        },
      ),
    );
  }
}
