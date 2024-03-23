import 'dart:core';
import 'package:paa/utils/constant_config.dart';
import 'package:paa/utils/plate_config.dart';
import '../my_app.dart';


class ReportInfo {
  String name;
  String evaluate;

  List<int> red;
  List<int> green;
  List<int> blue;
  ReportInfo(this.name, this.evaluate, this.red, this.green, this.blue);

  List<double> standard = [];
  List<double> sample = [];

  //standard concentration
  Map<String, List<double>> con = {
    PreferenceKey.peraceticAcid: [0, 0.15, 0.5, 1, 2.5, 3],
  };

  Plate plate = Plate();
  

  List<double> calStandard() {
    standard = [];
    try {
      if (evaluate == PreferenceKey.peraceticAcid) {
        for (int i = 1; i < 61; i++) {
          standard.add(green[i - 1].toDouble());
        }
      } 
    } catch (e) {
      logger.e('Fail: calculate standard value');
    }
    return standard;
  }

  List<double> calSample() {
    sample = [];
    try {
      if (evaluate == PreferenceKey.peraceticAcid) {
        for (int i = 61; i < green.length + 1; i++) {
          sample.add(green[i - 1].toDouble());
        }
      }
    } catch (e) {
      logger.e('Fail: calculate sample value');
    }
    return sample;
  }
}