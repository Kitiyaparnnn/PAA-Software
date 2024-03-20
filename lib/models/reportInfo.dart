import 'dart:core';
import 'package:paa/utils/constantConfig.dart';
import '../MyApp.dart';
import '../utils/PlateConfig.dart';

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
    // print(Plate.pnpStandard);
    standard = [];
    // print(this.evaluate);
    try {
      if (evaluate == PreferenceKey.peraceticAcid) {
        for (int i = 1; i < 51; i++) {
          standard.add(green[i - 1].toDouble());
        }
      } 
    } catch (e) {
      logger.e('Fail: calculate standard value');
    }
    // print(standard);
    return standard;
  }

  List<double> calSample() {
    // print(Plate.php);
    sample = [];
    try {
      if (evaluate == PreferenceKey.peraceticAcid) {
        for (int i = 51; i < green.length + 1; i++) {
          sample.add(green[i - 1].toDouble());
        }
      }
    } catch (e) {
      logger.e('Fail: calculate sample value');
    }
    // print(sample);
    return sample;
  }
}