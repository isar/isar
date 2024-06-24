import 'package:isar/isar.dart';

part 'collection_a.g.dart';

@collection
class CollectionA {
  Id id;

  @Index()
  int duplicatedId;

  bool boolField;
  bool? nBoolField;

  byte byteField;

  short shortField;
  short? nShortField;

  int intField;
  int? nIntField;

  float floatField;
  float? nFloatField;

  double doubleField;
  double? nDoubleField;

  DateTime dateField;
  DateTime? nDateField;

  @Index()
  String stringField;

  @Index(type: IndexType.hash)
  String? nStringField;

  List<bool> boolList;
  List<bool>? boolNList;
  List<bool?> nBoolList;
  List<bool?>? nBoolNList;

  List<byte> byteList;
  List<byte>? byteNList;

  List<short> shortList;
  List<short>? shortNList;
  List<short?> nShortList;
  List<short?>? nShortNList;

  List<int> intList;
  List<int>? intNList;
  List<int?> nIntList;
  List<int?>? nIntNList;

  List<float> floatList;
  List<float>? floatNList;
  List<float?> nFloatList;
  List<float?>? nFloatNList;

  List<double> doubleList;
  List<double>? doubleNList;
  List<double?> nDoubleList;
  List<double?>? nDoubleNList;

  List<DateTime> dateList;
  List<DateTime>? dateNList;
  List<DateTime?> nDateList;
  List<DateTime?>? nDateNList;

  List<String> stringList;
  List<String>? stringNList;
  List<String?> nStringList;
  List<String?>? nStringNList;

  CollectionA({
    required this.id,
    required this.duplicatedId,
    required this.boolField,
    required this.nBoolField,
    required this.byteField,
    required this.shortField,
    required this.nShortField,
    required this.intField,
    required this.nIntField,
    required this.floatField,
    required this.nFloatField,
    required this.doubleField,
    required this.nDoubleField,
    required this.dateField,
    required this.nDateField,
    required this.stringField,
    required this.nStringField,
    required this.boolList,
    required this.boolNList,
    required this.nBoolList,
    required this.nBoolNList,
    required this.byteList,
    required this.byteNList,
    required this.shortList,
    required this.shortNList,
    required this.nShortList,
    required this.nShortNList,
    required this.intList,
    required this.intNList,
    required this.nIntList,
    required this.nIntNList,
    required this.floatList,
    required this.floatNList,
    required this.nFloatList,
    required this.nFloatNList,
    required this.doubleList,
    required this.doubleNList,
    required this.nDoubleList,
    required this.nDoubleNList,
    required this.dateList,
    required this.dateNList,
    required this.nDateList,
    required this.nDateNList,
    required this.stringList,
    required this.stringNList,
    required this.nStringList,
    required this.nStringNList,
  });
}
