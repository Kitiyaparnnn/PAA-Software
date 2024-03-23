import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:paa/utils/color_config.dart';

class LoadCsvDataScreen extends StatelessWidget {
  final String path;
  final String title;

  const LoadCsvDataScreen({super.key, required this.path, required this.title});

  @override
  Widget build(BuildContext context) {
    Widget rowData(String text) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.13,
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("$title .csv"),
        backgroundColor: ColorCode.themeColor,
        foregroundColor: ColorCode.iconsAppBar,
      ),
      body: FutureBuilder(
        future: loadingCsvData(path),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          // print(snapshot.data.toString());
          return snapshot.hasData
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: snapshot.data!
                          .map(
                            (data) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  rowData(data[0].toString()),
                                  rowData(data[1].toString()),
                                  rowData(data[2].toString()),
                                  rowData(data[3].toString()),
                                  rowData(data[4].toString()),
                                  rowData(data[5].toString()),
                                  rowData(data[6].toString()),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(),
                );
        },
      ),
    );
  }

  Future<List<List<dynamic>>> loadingCsvData(String path) async {
    final csvFile = File(path).openRead();
    return await csvFile
        .transform(utf8.decoder)
        .transform(
          const CsvToListConverter(),
        )
        .toList();
  }
}
