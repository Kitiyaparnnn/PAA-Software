import 'dart:io';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paa/models/report_info.dart';
import 'package:paa/my_app.dart';
import 'package:paa/pages/analysisPage/all_analysis_page.dart';
import 'package:paa/pages/analysisPage/tap_analysis_page.dart';
import 'package:paa/pages/inputPage/components/input_decoration.dart';

import 'package:paa/utils/color_config.dart';
import 'package:paa/utils/constant_config.dart';
import 'package:paa/utils/plate_config.dart';
import 'package:paa/utils/text_config.dart';
import 'package:path_provider/path_provider.dart';

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController reportName = TextEditingController();
  String dropdownValue = PreferenceKey.inputForm;
  File? imageFile;
  File? _image;
  ReportInfo report = ReportInfo('', PreferenceKey.peraceticAcid, [], [], []);

  @override
  void initState() {
    FlutterNativeSplash.remove();
    super.initState();
    reportName.clear();
    // report.evaluate = dropdownValue;
  }

  void _showImageDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "อัพโหลดรูปภาพจาก",
              style: StyleText.headerText,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    await _getFromCamera();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "กล้อง",
                        style: TextStyle(color: Colors.grey),
                      )
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await _getFromGallery();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.image,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "แกลลอรี่",
                        style: TextStyle(color: Colors.grey),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  Future<void> _getFromGallery() async {
    XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxHeight: 1080, maxWidth: 1080);
    if (pickedFile != null) {
      _cropImage(pickedFile.path);
    }
  }

  Future<void> _getFromCamera() async {
    XFile? pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.camera, maxHeight: 1080, maxWidth: 1080);
    if (pickedFile != null) {
      _cropImage(pickedFile.path);
    }
  }

  void _cropImage(filePath) async {
    File? croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        maxHeight: 1080,
        maxWidth: 1080,
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio16x9
        ],
        androidUiSettings: const AndroidUiSettings(
          cropGridRowCount: 7,
          cropGridColumnCount: 11,
        ));

    if (croppedFile != null) {
      _saveImage();
      setState(() {
        imageFile = File(croppedFile.path);
      });
    }
  }

  Future _saveImage() async {
    Directory imagePath = await getApplicationDocumentsDirectory();
    String path = imagePath.path;
    File newImage = await imageFile!.copy('$path/image1.png');
    setState(() {
      _image = newImage;
    });
    logger.i('imagePath: $_image');
  }

  Widget _checkBox(String evaluate, int index) {
    Widget? isIcon;
    if (evaluate == 'Peratic Acid') {
      //standard
      if (Plate.pnpStandard.contains(index)) {
        isIcon = const Icon(
          Icons.check_circle_outline_outlined,
          color: Colors.green,
        );
      }
      //sample
      if (Plate.pnpSample!.contains(index)) {
        isIcon = const Icon(
          Icons.check_circle_outline_outlined,
          color: Colors.red,
        );
      }
    }

    return Container(
      height: 2.5,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: isIcon,
    );
  }

  Widget _analyzTap() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          textStyle: StyleText.normalText,
          minimumSize: const Size.fromHeight(50),
          backgroundColor: ColorCode.buttonsColor),
      onPressed: () {
        imageFile == null || report.evaluate == PreferenceKey.inputForm
            ? BotToast.showText(text: PreferenceKey.noti)
            : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) =>
                        const TapAnalysisPage()));
      },
      child: Text(PreferenceKey.analyzTap, style: StyleText.buttonText),
    );
  }

  Widget _analyzAll() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          textStyle: StyleText.normalText,
          minimumSize: const Size.fromHeight(50),
          backgroundColor: ColorCode.buttonsColor),
      onPressed: () {
        imageFile == null
            ? BotToast.showText(text: PreferenceKey.noti)
            : Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => AllAnalysisPage(
                    report: report,
                    imageFile: _image,
                  ),
                ),
              );
      },
      child: Text(PreferenceKey.analyzAll, style: StyleText.buttonText),
    );
  }

  Widget _inputReportName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(PreferenceKey.nameTitle, style: StyleText.headerText),
        const SizedBox(
          height: 5,
        ),
        TextFormField(
          controller: reportName,
          onChanged: (context) => setState(() {
            report.name = context;
          }),
          cursorColor: Colors.green,
          decoration: InputDecorations.inputDec(hintText: 'example'),
          style: StyleText.normalText,
        ),
        const SizedBox(
          height: 10,
        ),
        Text(PreferenceKey.evaluateTitle, style: StyleText.headerText),
        const SizedBox(
          height: 5,
        ),
        TextFormField(
          readOnly: true,
          decoration: InputDecorations.inputDec(hintText: ''),
          initialValue: PreferenceKey.inputForm,
          style: StyleText.normalText,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PAA v.1", style: StyleText.appBar),
        backgroundColor: Colors.green,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        _inputReportName(),
                        const SizedBox(
                          height: 10,
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    PreferenceKey.imageTitle,
                                    style: StyleText.headerText,
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        textStyle: StyleText.normalText,
                                        backgroundColor:
                                            ColorCode.buttonsColor),
                                    onPressed: _showImageDialog,
                                    child: Text(
                                      imageFile == null
                                          ? "อัพโหลดรูปภาพ"
                                          : "เปลี่ยนรูปภาพ",
                                      style: StyleText.buttonText,
                                    ),
                                  )
                                ],
                              ),
                              Container(
                                height: MediaQuery.of(context).size.width,
                                // constraints: BoxConstraints(
                                //   maxWidth: MediaQuery.of(context).size.width,
                                //   maxHeight: 252,
                                // ),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.rectangle,
                                ),
                                child: Stack(
                                  children: [
                                    imageFile != null
                                        ? Image.file(imageFile!,
                                            width: double.infinity,
                                            height: 240,
                                            semanticLabel: "96-well plates",
                                            fit: BoxFit.cover)
                                        : Center(
                                            widthFactor: double.infinity,
                                            heightFactor: double.infinity,
                                            child: Text(
                                              "",
                                              style: StyleText.normalText,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                    GridView.count(
                                      shrinkWrap: true,
                                      // physics: NeverScrollableScrollPhysics(),
                                      crossAxisCount: 12,
                                      children: List.generate(
                                          96,
                                          (index) => _checkBox(
                                              dropdownValue, index + 1)),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                        // const SizedBox(
                        //   height: 10,
                        // ),
                        // _analyzTap(),
                        const SizedBox(
                          height: 10,
                        ),
                        _analyzAll()
                      ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
