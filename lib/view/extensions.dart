import 'package:flutter/material.dart';

extension TextStyles on TextStyle {
  TextStyle get appBarStyle => copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );
}
