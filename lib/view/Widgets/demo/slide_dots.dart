import 'package:flutter/material.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';

/// Progress dots. The active dot both grows and takes the accent, so the
/// position reads without relying on colour alone.
class SlideDots extends StatelessWidget {
  final bool isActive;

  SlideDots(this.isActive);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: OSMotion.selection,
      curve: OSMotion.standardCurve,
      margin: const EdgeInsets.symmetric(horizontal: OSSpace.xxs),
      height: 8,
      width: isActive ? 22 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : OSColors.chromeControl,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
