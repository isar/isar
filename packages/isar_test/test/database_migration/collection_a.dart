import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';

part 'collection_a.g.dart';

// This code is exactly the same as the one that is used to
// generate the Isar v3 database file.
// We use it here in order to generate the exact same objects,
// and make sure every data is the same after migration.

@collection
class CollectionA {
  @Id()
  int id;

  // @Index()
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

  @Index(hash: true)
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

  @override
  bool operator ==(Object other) {
    return other is CollectionA &&
        other.id == id &&
        other.duplicatedId == duplicatedId &&
        other.boolField == boolField &&
        other.nBoolField == nBoolField &&
        other.byteField == byteField &&
        other.shortField == shortField &&
        other.nShortField == nShortField &&
        other.intField == intField &&
        other.nIntField == nIntField &&
        doubleEquals(other.floatField, floatField) &&
        doubleEquals(other.nFloatField, nFloatField) &&
        doubleEquals(other.doubleField, doubleField) &&
        doubleEquals(other.nDoubleField, nDoubleField) &&
        other.dateField == dateField &&
        other.nDateField == nDateField &&
        other.stringField == stringField &&
        other.nStringField == nStringField &&
        listEquals(other.boolList, boolList) &&
        listEquals(other.boolNList, boolNList) &&
        listEquals(other.nBoolList, nBoolList) &&
        listEquals(other.nBoolNList, nBoolNList) &&
        listEquals(other.byteList, byteList) &&
        listEquals(other.byteNList, byteNList) &&
        listEquals(other.shortList, shortList) &&
        listEquals(other.shortNList, shortNList) &&
        listEquals(other.nShortList, nShortList) &&
        listEquals(other.nShortNList, nShortNList) &&
        listEquals(other.intList, intList) &&
        listEquals(other.intNList, intNList) &&
        listEquals(other.nIntList, nIntList) &&
        listEquals(other.nIntNList, nIntNList) &&
        doubleListEquals(other.floatList, floatList) &&
        doubleListEquals(other.floatNList, floatNList) &&
        doubleListEquals(other.nFloatList, nFloatList) &&
        doubleListEquals(other.nFloatNList, nFloatNList) &&
        doubleListEquals(other.doubleList, doubleList) &&
        doubleListEquals(other.doubleNList, doubleNList) &&
        doubleListEquals(other.nDoubleList, nDoubleList) &&
        doubleListEquals(other.nDoubleNList, nDoubleNList) &&
        listEquals(other.dateList, dateList) &&
        listEquals(other.dateNList, dateNList) &&
        listEquals(other.nDateList, nDateList) &&
        listEquals(other.nDateNList, nDateNList) &&
        listEquals(other.stringList, stringList) &&
        listEquals(other.stringNList, stringNList) &&
        listEquals(other.nStringList, nStringList) &&
        listEquals(other.nStringNList, nStringNList);
  }
}

// CollectionA
const _boolValues = [false, true];
const _byteValues = [0, 1, 100, 254, 255];
const _shortValues = [-1147483647, 123, -100, 0, 1, 1117483647];
const _intValues = [
  -8113372036854775807,
  -123456,
  -1,
  0,
  2222272036854775807,
];
const _floatValues = <float>[123.5, 3, 0, -442.25, 3213.28];
const _doubleValues = <double>[
  -51235123.154123123,
  0.555123,
  1512351239516239.123412354,
  -41.12561234123,
];
final _dateValues = [
  DateTime(2024, 1, 2, 3, 4, 5, 6, 7),
  DateTime(2011, 3, 15, 3, 22, 12, 1, 31),
  DateTime(1, 4, 30, 2, 22, 13, 7, 13),
];
final _stringValues = [
  'isar',
  'v3',
  'v4',
  'DATABASE',
  r'abcdefghijklmnopqrstuvwxyz0123456789+-/|\~!@#\$%^&*(){}',
];

List<CollectionA> generateCollectionAObjects() {
  final objects = <CollectionA>[];

  int objectIndex = 0;
  for (int boolIndex = 0; boolIndex < _boolValues.length; boolIndex++) {
    final boolValue = _boolValues[boolIndex];
    final nBoolValue = boolIndex % 3 == 0
        ? null
        : _boolValues[(boolIndex + 1) % _boolValues.length];

    for (int byteIndex = 0; byteIndex < _byteValues.length; byteIndex++) {
      final byteValue = _byteValues[byteIndex];

      for (int shortIndex = 0; shortIndex < _shortValues.length; shortIndex++) {
        final shortValue = _shortValues[shortIndex];
        final nShortValue = shortIndex % 3 == 0
            ? null
            : _shortValues[(shortIndex + 1) % _shortValues.length];

        for (int intIndex = 0; intIndex < _intValues.length; intIndex++) {
          final intValue = _intValues[intIndex];
          final nIntValue = intIndex % 3 == 0
              ? null
              : _intValues[(intIndex + 1) % _intValues.length];

          for (int floatIndex = 0;
              floatIndex < _floatValues.length;
              floatIndex++) {
            final floatValue = _floatValues[floatIndex];
            final nFloatValue = floatIndex % 3 == 0
                ? null
                : _floatValues[(floatIndex + 1) % _floatValues.length];

            for (int doubleIndex = 0;
                doubleIndex < _doubleValues.length;
                doubleIndex++) {
              final doubleValue = _doubleValues[doubleIndex];
              final nDoubleValue = doubleIndex % 3 == 0
                  ? null
                  : _doubleValues[(doubleIndex + 1) % _doubleValues.length];

              for (int dateIndex = 0;
                  dateIndex < _dateValues.length;
                  dateIndex++) {
                final dateValue = _dateValues[dateIndex];
                final nDateValue = dateIndex % 3 == 0
                    ? null
                    : _dateValues[(dateIndex + 1) % _dateValues.length];

                for (int stringIndex = 0;
                    stringIndex < _stringValues.length;
                    stringIndex++) {
                  final stringValue = _stringValues[stringIndex];
                  final nStringValue = stringIndex % 3 == 0
                      ? null
                      : _stringValues[(stringIndex + 1) % _stringValues.length];

                  objects.add(
                    CollectionA(
                      id: objectIndex + 1,
                      duplicatedId: objectIndex + 1,
                      boolField: boolValue,
                      nBoolField: nBoolValue,
                      byteField: byteValue,
                      shortField: shortValue,
                      nShortField: nShortValue,
                      intField: intValue,
                      nIntField: nIntValue,
                      floatField: floatValue,
                      nFloatField: nFloatValue,
                      doubleField: doubleValue,
                      nDoubleField: nDoubleValue,
                      dateField: dateValue,
                      nDateField: nDateValue,
                      stringField: stringValue,
                      nStringField: nStringValue,
                      boolList: _getListValues(_boolValues, objectIndex),
                      boolNList: _getNListValues(_boolValues, objectIndex),
                      nBoolList: _getListNValues(_boolValues, objectIndex),
                      nBoolNList: _getNListNValues(_boolValues, objectIndex),
                      byteList: _getListValues(_byteValues, objectIndex),
                      byteNList: _getNListValues(_byteValues, objectIndex),
                      shortList: _getListValues(_byteValues, objectIndex),
                      shortNList: _getNListValues(_byteValues, objectIndex),
                      nShortList: _getListNValues(_byteValues, objectIndex),
                      nShortNList: _getNListNValues(_byteValues, objectIndex),
                      intList: _getListValues(_intValues, objectIndex),
                      intNList: _getNListValues(_intValues, objectIndex),
                      nIntList: _getListNValues(_intValues, objectIndex),
                      nIntNList: _getNListNValues(_intValues, objectIndex),
                      floatList: _getListValues(_floatValues, objectIndex),
                      floatNList: _getNListValues(_floatValues, objectIndex),
                      nFloatList: _getListNValues(_floatValues, objectIndex),
                      nFloatNList: _getNListNValues(_floatValues, objectIndex),
                      doubleList: _getListValues(_doubleValues, objectIndex),
                      doubleNList: _getNListValues(_doubleValues, objectIndex),
                      nDoubleList: _getListNValues(_doubleValues, objectIndex),
                      nDoubleNList:
                          _getNListNValues(_doubleValues, objectIndex),
                      dateList: _getListValues(_dateValues, objectIndex),
                      dateNList: _getNListValues(_dateValues, objectIndex),
                      nDateList: _getListNValues(_dateValues, objectIndex),
                      nDateNList: _getNListNValues(_dateValues, objectIndex),
                      stringList: _getListValues(_stringValues, objectIndex),
                      stringNList: _getNListValues(_stringValues, objectIndex),
                      nStringList: _getListNValues(_stringValues, objectIndex),
                      nStringNList:
                          _getNListNValues(_stringValues, objectIndex),
                    ),
                  );

                  objectIndex++;
                }
              }
            }
          }
        }
      }
    }
  }

  return objects;
}

List<T> _getListValues<T>(List<T> values, int objectIndex) {
  final length = objectIndex % 5;

  final multi = values.length ~/ 2 + 1;

  return [
    for (int i = 0; i < length; i++) values[(i * multi) % values.length],
  ];
}

List<T>? _getNListValues<T>(List<T> values, int objectIndex) {
  final length = (objectIndex % 6) - 1;
  if (length == -1) {
    return null;
  }

  final multi = values.length ~/ 2 + 1;

  return [
    for (int i = 0; i < length; i++) values[(i * multi) % values.length],
  ];
}

List<T?> _getListNValues<T>(List<T> values, int objectIndex) {
  final length = objectIndex % 7;

  final multi = values.length ~/ 2;

  return [
    for (int i = 0; i < length; i++)
      if ((i * multi) % (values.length + 1) == 0)
        null
      else
        values[(i * multi) % values.length],
  ];
}

List<T?>? _getNListNValues<T>(List<T> values, int objectIndex) {
  final length = (objectIndex % 13) - 1;
  if (length == -1) {
    return null;
  }

  final multi = values.length ~/ 2;

  return [
    for (int i = 0; i < length; i++)
      if ((i * multi) % (values.length + 1) == 0)
        null
      else
        values[(i * multi) % values.length],
  ];
}
