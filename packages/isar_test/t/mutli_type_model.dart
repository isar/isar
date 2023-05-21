import 'dart:typed_data';

import 'package:isar/isar.dart';

part 'mutli_type_model.g.dart';

@collection
class MultiTypeModel {
  Id? id;

  bool? boolValueN;

  bool boolValue = false;

  short? intValueN;

  short intValue = 0;

  float? floatValueN;

  float floatValue = 0;

  int? longValueN;

  int longValue = 0;

  double? doubleValueN;

  double doubleValue = 0;

  DateTime? dateTimeValueN;

  DateTime dateTimeValue = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  String? stringValueN;

  String stringValue = '';

  List<bool> boolList = [];

  List<bool?> boolNList = [];

  List<bool>? boolListN;

  List<bool?>? boolNListN;

  List<byte>? byteListN;

  List<byte> byteList = Uint8List(0);

  List<short> intList = [];

  List<short?> intNList = [];

  List<short>? intListN;

  List<short?>? intNListN;

  List<float> floatList = [];

  List<float?> floatNList = [];

  List<float>? floatListN;

  List<float?>? floatNListN;

  List<int> longList = [];

  List<int?> longNList = [];

  List<int>? longListN;

  List<int?>? longNListN;

  List<double> doubleList = [];

  List<double?> doubleNList = [];

  List<double>? doubleListN;

  List<double?>? doubleNListN;

  List<DateTime> dateTimeList = [];

  List<DateTime?> dateTimeNList = [];

  List<DateTime>? dateTimeListN;

  List<DateTime?>? dateTimeNListN;

  List<String> stringList = [];

  List<String?> stringNList = [];

  List<String>? stringListN;

  List<String?>? stringNListN;
}
