import 'dart:typed_data';

import 'package:isar/isar.dart';

part 'mutli_type_model.g.dart';

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

  List<bool> boolList = [];

  List<bool?> boolNList = [];

  List<bool>? boolListN;

  List<bool?>? boolNListN;

  @Size32()
  List<int> intList = [];

  @Size32()
  List<int?> intNList = [];

  @Size32()
  List<int>? intListN;

  @Size32()
  List<int?>? intNListN;

  @Size32()
  List<double> floatList = [];

  @Size32()
  List<double?> floatNList = [];

  @Size32()
  List<double>? floatListN;

  @Size32()
  List<double?>? floatNListN;

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
