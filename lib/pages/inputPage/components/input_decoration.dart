import 'package:flutter/material.dart';
import 'package:paa/utils/color_config.dart';

class InputDecorations {
  static InputDecoration inputDec({required String hintText}) =>
      InputDecoration(
        hintText: hintText,
        fillColor: ColorCode.themeColor,
        focusColor: ColorCode.themeColor,
        hoverColor: ColorCode.themeColor,
        alignLabelWithHint: true,
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: ColorCode.themeColor, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: ColorCode.themeColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(8),
      );
}
