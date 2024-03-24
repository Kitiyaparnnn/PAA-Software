import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:paa/models/report_info.dart';
import 'package:paa/my_app.dart';
import 'package:paa/pages/analysisPage/components/graph_calculation.dart';
import 'package:paa/pages/analysisPage/components/pdf_printer.dart';
import 'package:paa/pages/analysisPage/components/report_header.dart';
import 'package:paa/pages/analysisPage/components/rgb_extraction.dart';
import 'package:paa/utils/color_config.dart';
import 'package:paa/utils/text_config.dart';
import 'package:scidart/numdart.dart';

class ColorPickerWidget extends StatefulWidget {
  ColorPickerWidget({super.key, this.imageFile, required this.report});

  final File? imageFile;
  ReportInfo report;

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  String imagePath = "lib/assets/images/example_plate.jpg";
  GlobalKey imageKey = GlobalKey();
  GlobalKey paintKey = GlobalKey();

  double result = 0;
  bool wait = true;
  Uint8List? imageBytes;
  Map<String, List<img.Color>>? colors;
  List<int> red = [];
  List<int> green = [];
  List<int> blue = [];
  List<double> con = [];
  late PolyFit equation;
  double x = 0;
  double y = 0;

// CHANGE THIS FLAG TO TEST BASIC IMAGE, AND SNAPSHOT.
  bool useSnapshot = true;

// based on useSnapshot=true ? paintKey : imageKey ;
// this key is used in this example to keep the code shorter.
  late GlobalKey currentKey;

  final StreamController _stateController = StreamController();
  img.Image? photo;

  @override
  void initState() {
    delay();
    currentKey = useSnapshot ? paintKey : imageKey;
    super.initState();
  }

  delay() async {
    await Future.delayed(const Duration(seconds: 10));
    await extractColors();
    await conStandard();
    wait = false;
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
    List<double> con = [];
    for (double i in widget.report.con[widget.report.evaluate]!) {
      for (int j = 0; j < 5; j++) {
        con.add(i);
      }
    }
    return con = con + con.toList();
  }

  conStandard() async {
    con = widget.report.con[widget.report.evaluate]!;
    List<double> standard = widget.report.calStandard();
    equation = calRsquare(standard, calCon());
    logger.d(equation);
  }

  double calConcentrate(PolyFit equation, Color colorCode) {
    double sample = 0;
    try {
      sample = colorCode.green.toDouble();
      result = equation.predict(sample);
    } catch (e) {
      logger.e('Fail: cal concentrate');
      result = 0;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorCode.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            color: ColorCode.iconsAppBar,
            onPressed: () {
              printScreen(paintKey);
            },
            icon: const Icon(
              Icons.print_rounded,
            ),
          )
        ],
        title: Text('รายงานผลวิเคราะห์', style: StyleText.appBar),
      ),
      body: Column(
        children: [
          reportHeader(widget.report.name, widget.report.evaluate),
          Expanded(
            child: wait
                ? const Center(
                    child: CircularProgressIndicator(
                    semanticsLabel: "loading...",
                  ))
                : StreamBuilder(
                    initialData: Colors.green[500],
                    stream: _stateController.stream,
                    builder: (buildContext, snapshot) {
                      Color selected = Colors.green;
                      if (!(snapshot.data.runtimeType == Color)) {
                        final int a = snapshot.data.a;
                        final r = snapshot.data.r;
                        final g = snapshot.data.g;
                        final b = snapshot.data.b;
                        selected = Color.fromARGB(a, r, g, b);
                      }
                      Color selectedColor = (selected);
                      calConcentrate(equation, selectedColor);
                      return Stack(children: [
                        RepaintBoundary(
                          key: paintKey,
                          child: GestureDetector(
                              onPanDown: (details) {
                                searchPixel(details.globalPosition);
                              },
                              onPanUpdate: (details) {
                                searchPixel(details.globalPosition);
                              },
                              child: Image.file(
                                widget.imageFile!,
                                key: imageKey,
                                height: 500,
                                width: 500,
                                fit: BoxFit.contain,
                              )),
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 30),
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selectedColor,
                                    border: Border.all(
                                        width: 2.0, color: Colors.white),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2))
                                    ]),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 30),
                                child: Column(children: [
                                  Text(
                                      'R:${selectedColor.red}, G:${selectedColor.green}, B:${selectedColor.blue}',
                                      style: StyleText.headerText),
                                  Text(
                                      "Coordinate (x,y) : (${x.toInt()}, ${y.toInt()})",
                                      style: StyleText.normalText),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                      "Concentration of Samples: ${(result * 2).toStringAsFixed(2)} ppm ",
                                      style: StyleText.headerText)
                                ]),
                              )
                            ]),
                        Positioned(
                            left: x - 10,
                            top: y - 22,
                            // height: h.toDouble(),
                            child: const Icon(Icons.push_pin_rounded)),
                      ]);
                    }),
          ),
        ],
      ),
    );
  }

  void searchPixel(Offset globalPosition) async {
    if (photo == null) {
      await (useSnapshot ? loadSnapshotBytes() : loadImageBundleBytes());
    }
    _calculatePixel(globalPosition);
  }

  void _calculatePixel(Offset globalPosition) {
    RenderBox box = currentKey.currentContext?.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(globalPosition);

    double px = localPosition.dx;
    double py = localPosition.dy;

    if (!useSnapshot) {
      double widgetScale = box.size.width / photo!.width;
      px = (px / widgetScale);
      py = (py / widgetScale);
    }

    x = px;
    y = py;

    img.Pixel pixel32 = photo!.getPixelSafe(px.toInt(), py.toInt());
    final u8rgba =
        pixel32.convert(format: img.Format.uint8, numChannels: 4, alpha: 255);
    // int hex = abgrToArgb(u8rgba);

    _stateController.add(u8rgba);
  }

  Future loadImageBundleBytes() async {
    ByteData imageBytes = await rootBundle.load(widget.imageFile!.path);
    setImageBytes(imageBytes);
  }

  Future loadSnapshotBytes() async {
    RenderRepaintBoundary boxPaint =
        paintKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    ui.Image capture = await boxPaint.toImage();
    ByteData? imageBytes =
        await capture.toByteData(format: ui.ImageByteFormat.png);
    setImageBytes(imageBytes!);
    capture.dispose();
  }

  void setImageBytes(ByteData imageBytes) {
    Uint8List values = imageBytes.buffer.asUint8List();

    photo = img.decodeImage(values)!;
  }
}

// image lib uses uses KML color format, convert #AABBGGRR to regular #AARRGGBB
int abgrToArgb(int argbColor) {
  int r = (argbColor >> 16) & 0xFF;
  int b = argbColor & 0xFF;
  return (argbColor & 0xFF00FF00) | (b << 16) | r;
}
