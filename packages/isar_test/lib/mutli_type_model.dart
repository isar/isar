import 'dart:typed_data';

import 'package:isar/isar.dart';

@Collection()
class MultiTypeModel {
  int? id;

  bool? boolValue;

  @Size32()
  int? intValue;

  @Size32()
  double? floatValue;

  int? longValue;

  double? doubleValue;

  DateTime? dateTimeValue;

  String? stringValue;

  Uint8List? bytesValue;

  List<bool>? boolList;

  @Size32()
  List<int>? intList;

  @Size32()
  List<double>? floatList;

  List<int>? longList;

  List<double>? doubleList;

  List<DateTime>? dateTimeListValue;

  List<String>? stringList;
}
