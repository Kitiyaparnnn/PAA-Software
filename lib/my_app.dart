import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:paa/pages/inputPage/input_page.dart';
import 'package:paa/utils/color_config.dart';


final logger = Logger(
  printer: PrettyPrinter(),
);

final loggerNoStack = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      Logger.level = Level.all;
    } else {
      Logger.level = Level.debug;
    }
    return FutureBuilder(
        future: Init.instance.initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: SafeArea(
                child: Scaffold(
                  body: Container(
                    color: ColorCode.themeColor,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: ColorCode.iconsAppBar,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "modern-css by Kitiyaporn T.",
            builder: BotToastInit(),
            navigatorObservers: [BotToastNavigatorObserver()],
            home: const InputPage(),
            theme: ThemeData(
                textTheme: GoogleFonts.sarabunTextTheme()),
          );
        });
  }
}

class Init {
  Init._();

  static final instance = Init._();

  Future initialize() async {
    await Future.delayed(const Duration(seconds: 3));
  }
}
