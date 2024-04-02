import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paa/my_app.dart';
import 'package:paa/models/report_info.dart';
import 'package:paa/pages/analysisPage/components/crop_plate_generator.dart';
import 'package:paa/pages/analysisPage/components/csv_genterator.dart';
import 'package:paa/pages/analysisPage/components/graph_calculation.dart';
import 'package:paa/pages/analysisPage/components/pdf_printer.dart';
import 'package:paa/pages/analysisPage/components/report_header.dart';
import 'package:paa/pages/analysisPage/components/rgb_extraction.dart';
import 'package:paa/utils/color_config.dart';
import 'package:paa/utils/constant_config.dart';
import 'package:paa/utils/plate_config.dart';
import 'package:paa/utils/text_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scidart/numdart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:image/image.dart' as image_lib;

class AllAnalysisPage extends StatefulWidget {
  AllAnalysisPage({super.key, this.imageFile, required this.report});

  final File? imageFile;
  ReportInfo report;

  @override
  State<AllAnalysisPage> createState() => _AllAnalysisPageState();
}

class _AllAnalysisPageState extends State<AllAnalysisPage> {
  final GlobalKey<State<StatefulWidget>> _printKey = GlobalKey();
  bool waiting = true;

  Map<String, List<image_lib.Color>>? colors;
  List<int> red = [];
  List<int> green = [];
  List<int> blue = [];

  late PolyFit equation;
  List<double> result = [];

  Uint8List? imageBytes;
  List<File> stdFile = [];
  List<File> smpFile = [];

  List<double> con = [];
  Plate plate = Plate();

  late double minimum;
  late double maximum;

  @override
  void initState() {
    delay();
    logger.d({
      'report name: ${widget.report.name}',
      'report evaluate: ${widget.report.evaluate}'
    });
    super.initState();
  }

  delay() async {
    await Future.delayed(const Duration(seconds: 10));
    await extractColors();
    await conStandard();
    await cropImage();
    minimum = widget.report.calSample().reduce(min);
    maximum = widget.report.calSample().reduce(max);
    waiting = false;
    setState(() {});
  }

  Future<Uint8List> _readFileByte(File? filePath) async {
    File audioFile = filePath!;
    Uint8List bytes =
        (await rootBundle.load('lib/assets/images/example_plate.jpg'))
            .buffer
            .asUint8List();
    await audioFile.readAsBytes().then((value) {
      bytes = Uint8List.fromList(value);
      logger.i('reading of bytes is completed');
    }).catchError((onError) {
      logger.e('Exception Error while reading audio from path:$onError');
    });
    return bytes;
  }

  Future<void> extractColors() async {
    imageBytes = await _readFileByte(widget.imageFile);

    //extract the RGB code from the image
    colors = await compute(extractPixelsColors, imageBytes);

    //separate each color code
    colors!.forEach((key, value) {
      red.addAll(getColorValue(colors![key]!, 'red'));
      green.addAll(getColorValue(colors![key]!, 'green'));
      blue.addAll(getColorValue(colors![key]!, 'blue'));
    });

    //put the color code into the model (including standard & sample)
    widget.report.red = red;
    widget.report.green = green;
    widget.report.blue = blue;

    logger.i('green code: #${green.length}');
  }

  calCon() {
    //set up the concentration value to equal to the green code
    List<double> con = [];
    for (double i in widget.report.con[widget.report.evaluate]!) {
      for (int j = 0; j < 5; j++) {
        con.add(i);
      }
    }
    return con = con + con.toList();
  }

  conStandard() async {
    //get the concentration of the standard plates
    con = widget.report.con[widget.report.evaluate]!;
    //get the green code from the model
    List<double> standard = widget.report.calStandard();
    //create the equaltion
    equation = calRsquare(standard, calCon());
    logger.d(equation);
  }

  cropImage() async {
    var file = await cropSquare(widget.imageFile!, false);
    var length = file.length;
    logger.i('#cropPerImage: $length');
    file = selectImage(file);
    stdFile = file[0];
    smpFile = file[1];
  }

  selectImage(List<File> file) {
    List<File> std = [];
    List<File> smp = [];
    for (int i = 1; i < file.length + 1; i++) {
      if (Plate.pnpStandard.contains(i)) {
        std.add(file[i - 1]);
      } else if (Plate.pnpSample!.contains(i)) {
        smp.add(file[i - 1]);
      }
    }
    logger.i('#cropedImageUse: ${std.length + smp.length}');
    return [std, smp];
  }

  List<ChartData> calScatter(String type) {
    result = calConcentrate(equation, widget.report.calSample());
    logger.i('#calScatter complete: ${result.length}');
    return getData(
        type == PreferenceKey.standard ? calCon() : result,
        type == PreferenceKey.standard
            ? widget.report.calStandard()
            : widget.report.calSample());
  }

  List<ChartData> calLine() {
    // var zero = -equation.coefficient(0) / equation.coefficient(1);
    // print(zero);
    List<double> sample = [for (double i = minimum; i <= maximum; i++) i];
    result = calConcentrate(equation, sample);

    logger.i('#calLine complete');
    return getData(result, sample);
  }

  Widget _showChart() {
    return Center(
      child: waiting
          ? const CircularProgressIndicator(
              color: Colors.green,
            )
          : SizedBox(
              height: 400,
              //Initialize chart
              child: SfCartesianChart(
                tooltipBehavior: TooltipBehavior(
                    enable: true,
                    tooltipPosition: TooltipPosition.pointer,
                    borderColor: Colors.green.shade400,
                    borderWidth: 5,
                    color: Colors.green),
                title: const ChartTitle(
                  text: 'Standard Linear Regression',
                  textStyle: TextStyle(fontSize: 12),
                ),
                primaryXAxis: widget.report.evaluate ==
                        PreferenceKey.peraceticAcid
                    ? const NumericAxis(minimum: 0, interval: 1, maximum: 4)
                    : const NumericAxis(minimum: 0, interval: 0.5, maximum: 5),
                legend: const Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                    overflowMode: LegendItemOverflowMode.wrap),
                primaryYAxis: NumericAxis(
                    minimum: minimum, maximum: maximum, interval: 5),
                series: <CartesianSeries>[
                  ScatterSeries<ChartData, double>(
                      name: "standard plates",
                      color: Colors.blue,
                      legendItemText: PreferenceKey.standard,
                      enableTooltip: true,
                      dataSource: calScatter(PreferenceKey.standard),
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y),
                  LineSeries<ChartData, double>(
                      name: "standard line",
                      color: Colors.amber,
                      legendItemText:
                          'y = ${equation.coefficient(1).toStringAsFixed(3)}x+${equation.coefficient(0).toStringAsFixed(3)} (R^2 =${equation.R2().toStringAsFixed(3)})',
                      enableTooltip: true,
                      dataSource: calLine(),
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y),
                  ScatterSeries<ChartData, double>(
                      name: "sample plates",
                      color: Colors.orange,
                      legendItemText: PreferenceKey.sample,
                      enableTooltip: true,
                      dataSource: calScatter(PreferenceKey.sample),
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y),
                ],
              ),
            ),
    );
  }

  List<List<String>> smp = [];

  Widget _showResult() {
    con = con + con;

    int i = 0;
    int j = 0;
    int n = 0;

    return stdFile.isEmpty
        ? const SizedBox(
            height: 10,
          )
        : GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
                childAspectRatio: 1 / 1.5),
            itemCount: stdFile.length + smpFile.length,
            itemBuilder: (BuildContext ctx, index) {
              String title = '';
              String concentrate = '';
              String rgbCode = '';

              if (index < Plate.pnpStandard.length) {
                title = 'Std';
                concentrate = con[i].toStringAsFixed(2);
                rgbCode = widget.report.standard[i * 5].toStringAsFixed(0);
                i++;
              } else {
                var additionSmpPlateNo = [8, 9, 10, 11, 8, 9, 10, 11];
                var number = index % 10;
                if (number == 0) n++;
                if (index < 20) {
                  if (index == 16) n++;
                  title = plate.label[n] + additionSmpPlateNo[j].toString();
                } else {
                  title = plate.label[n] + plate.no[number].toString();
                }

                concentrate = (result[j] * 2).toStringAsFixed(2);
                rgbCode = widget.report.sample[j].toStringAsFixed(0);
                smp.add([
                  title,
                  "SMP",
                  "${widget.report.red[60 + j]}",
                  "${widget.report.green[60 + j]}",
                  "${widget.report.blue[60 + j]}",
                  concentrate
                ]);
                j++;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$title=$concentrate', style: StyleText.resultText),
                  Image.file(
                    index < Plate.pnpStandard.length
                        ? stdFile[index]
                        : smpFile[j - 1],
                    fit: BoxFit.contain,
                    height: 40,
                    width: 50,
                  ),
                  Text(
                    rgbCode,
                    style: StyleText.resultText,
                  )
                ],
              );
            },
          );
  }

  _showExportButton() {
    return waiting
        ? const SizedBox()
        : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        textStyle: StyleText.normalText,
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    onPressed: () {
                      generateCsv();
                    },
                    icon: const Icon(
                      Icons.file_upload,
                    ),
                    label: const Text('CSV')),
              ),
            ],
          );
  }

  Future generateCsv() async {
    List<List<String>> std = [];
    int j = 0;
    while (j < widget.report.standard.length) {
      List label = ['B', 'C'];
      int x = j ~/ 5;
      for (int i = 0; i < 5; i++) {
        std.add([
          "${x < 6 ? label[0] : label[1]}${plate.no[x % 6]}",
          "STD",
          "${widget.report.red[j]}",
          "${widget.report.green[j]}",
          "${widget.report.blue[j]}",
          con[x].toStringAsFixed(2)
        ]);
        j++;
      }
    }

    List<List<String>> data = [
          ["well_index", "STD/SMP", "R", "G", "B", "concentration\n(µg/mL)"]
        ] +
        std.toList() +
        smp.toList();
    String csvData = const ListToCsvConverter().convert(data);
    final String directory = (await getExternalStorageDirectory())!.path;
    final path = "$directory/m-css-${widget.report.name}-${DateTime.now()}.csv";
    final File file = File(path);
    await file.writeAsString(csvData);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return LoadCsvDataScreen(title: widget.report.name, path: path);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var report = widget.report;

    return Scaffold(
        key: UniqueKey(),
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              color: ColorCode.iconsAppBar,
              onPressed: () {
                printScreen(_printKey);
              },
              icon: const Icon(
                Icons.print_rounded,
              ),
            )
          ],
          title: Text(PreferenceKey.reportHeader, style: StyleText.appBar),
        ),
        body: SingleChildScrollView(
          child: RepaintBoundary(
            key: _printKey,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  reportHeader(report.name, report.evaluate),
                  _showChart(),
                  _showExportButton(),
                  Container(child: _showResult()),
                ],
              ),
            ),
          ),
        ));
  }
}
