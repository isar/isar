import 'dart:typed_data';

import 'package:isar/isar.dart';

@Collection()
class MultiTypeModel {
  int? id;

  bool? boolValueN;

  bool boolValue = false;

  @Size32()
  int? intValueN;

  @Size32()
  int intValue = 0;

  @Size32()
  double? floatValueN;

  @Size32()
  double floatValue = 0.0;

  int? longValueN;

  int longValue = 0;

  double? doubleValueN;

  double doubleValue = 0.0;

  DateTime? dateTimeValueN;

  DateTime dateTimeValue = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  String? stringValueN;

  String stringValue = '';

  Uint8List? bytesValueN;

  Uint8List bytesValue = Uint8List(0);

  List<bool>? boolListN;

  List<bool> boolList = [];

  @Size32()
  List<int>? intListN;

  @Size32()
  List<int> intList = [];

  @Size32()
  List<double>? floatListN;

  @Size32()
  List<double> floatList = [];

  List<int>? longListN;

  List<int> longList = [];

  List<double>? doubleListN;

  List<double> doubleList = [];

  List<DateTime>? dateTimeListN;

  List<DateTime> dateTimeList = [];

  List<String>? stringListN;

  List<String> stringList = [];
}
