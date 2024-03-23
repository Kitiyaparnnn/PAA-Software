//sample
List<int> row0 = [20, 21, 22, 23, 32, 33, 34, 35];
List<int> row1 = List.generate(10, (index) => index + 38);
List<int> row2 = List.generate(10, (index) => index + 50);
List<int> row3 = List.generate(10, (index) => index + 62);
List<int> row4 = List.generate(10, (index) => index + 74);

class Plate {
  var label = ['B', 'C', 'D', 'E', 'F', 'G'];
  var no = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  //standard
  static List<int> pnpStandard = [
    14,
    15,
    16,
    17,
    18,
    19,
    26,
    27,
    28,
    29,
    30,
    31
  ];

  //Phosphate,Nitrate,Potassium
  static List<int>? pnpSample = row0 + row1 + row2 + row3 + row4;
}
