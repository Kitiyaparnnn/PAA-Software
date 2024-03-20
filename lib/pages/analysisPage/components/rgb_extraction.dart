import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:paa/utils/constantConfig.dart';
import 'package:paa/utils/plateConfig.dart';
import '../../../myApp.dart';

Plate plate = Plate();

Color abgrToColor(int argbColor) {
  int r = (argbColor >> 16) & 0xFF;
  int b = argbColor & 0xFF;
  int hex = (argbColor & 0xFF00FF00) | (b << 16) | r;
  return Color(hex);
}

Map<String, List<Color>> extractPixelsColors(Uint8List? bytes) {
  Map<String, List<image_lib.Color>> colorCode = {};

  try {
    // List<int> values = bytes!.buffer.asUint8List();
    image_lib.Image? image = image_lib.decodeImage(bytes!);
    List<image_lib.Color> colorOfStandard = [];
    List<image_lib.Color> colorOfSample = [];
    List<int?> pixels = [];

    int? width = image?.width;
    int? height = image?.height;

    int xChunk = width! ~/ (GridConfig.noOfPixelsPerAxisX);
    int yChunk = height! ~/ (GridConfig.noOfPixelsPerAxisY);

    int left = xChunk - 1;
    int right = xChunk + 1;
    int top = yChunk + 1;
    int down = yChunk - 1;

    int midX = xChunk ~/ 2;
    int midY = yChunk ~/ 2;
    int no = 1;
    midX = midX + 1;
    midY = midY + 1;
    // xChunk = xChunk + 1;
    // yChunk = yChunk + 1;
    for (int j = 1; j < GridConfig.noOfPixelsPerAxisY + 1; j++) {
      for (int i = 1; i < GridConfig.noOfPixelsPerAxisX + 1; i++) {
        // int? pixel;
        //get the 5 points rgb code of each standard plates
        if (Plate.pnpStandard.contains(no)) {
          //get (r,g,b,a)
          logger.i(
              'get rgb: ${image?.getPixelCubic(xChunk * i - midX, yChunk * j - midY)[0]}');
          // Color pixel1 = abgrToColor(
          //     (image?.getPixel(xChunk * i - midX, yChunk * j - midY))! as int);
          // var pixel2 = abgrToColor(
          //     (image?.getPixel(left * i - midX, down * j - midY))! as int);
          // var pixel3 = abgrToColor(
          //     (image?.getPixel(right * i - midX, down * j - midY))! as int);
          // var pixel4 = abgrToColor(
          //     (image?.getPixel(left * i - midX, top * j - midY))! as int);
          // var pixel5 = abgrToColor(
          //     (image?.getPixel(right * i - midX, top * j - midY))! as int);

          image_lib.Color pixel1 =
              image!.getPixelCubic(xChunk * i - midX, yChunk * j - midY);
          image_lib.Color pixel2 =
              image.getPixelCubic(left * i - midX, down * j - midY);
          image_lib.Color pixel3 =
              image.getPixelCubic(right * i - midX, down * j - midY);
          image_lib.Color pixel4 =
              image.getPixelCubic(left * i - midX, top * j - midY);
          image_lib.Color pixel5 =
              image.getPixelCubic(right * i - midX, top * j - midY);

          colorOfStandard.add(pixel1);
          colorOfStandard.add(pixel2);
          colorOfStandard.add(pixel3);
          colorOfStandard.add(pixel4);
          colorOfStandard.add(pixel5);
        }
        //get the rgb code at the middle of each sample plates
        else if (Plate.pnpSample!.contains(no)) {
          // pixel = image?.getPixel(xChunk * i - midX, yChunk * j - midY) as int?;
          image_lib.Color pixel =
              image!.getPixelCubic(xChunk * i - midX, yChunk * j - midY);
          // pixels.add(pixel);
          // Color c = abgrToColor(pixel!);
          colorOfSample.add(pixel);
        }
        no++;
      }
    }
    // print(colorOfStandard.length);
    colorCode[PreferenceKey.standard] = colorOfStandard;
    colorCode[PreferenceKey.sample] = colorOfSample;

    // logger.d(colorOfStandard);
  } catch (e) {
    logger.e('Fail: can not get RGB code from image \nError: $e');
  }

  return colorCode;
}

List<int> getColorValue(List<Color> c, String color) {
  List<int> value = [];

  try {
    if (color == 'red') {
      for (var c in c) {
        value.add(c.red);
      }
    }
    if (color == 'green') {
      for (var c in c) {
        value.add(c.green);
      }
    }
    if (color == 'blue') {
      for (var c in c) {
        value.add(c.blue);
      }
    }
  } catch (e) {
    logger.e('Fail: can not convert hexcode to rgbcode');
  }
  return value;
}
