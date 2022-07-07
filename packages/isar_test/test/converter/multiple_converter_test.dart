import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';

part 'multiple_converter_test.g.dart';

@Collection()
class MultiConverterModel {
  MultiConverterModel({
    required this.id,
    required this.boolValue,
    required this.intValue,
    required this.longValue,
    required this.floatValue,
    required this.doubleValue,
    required this.dateValue,
    required this.stringValue,
  });

  Id? id;

  @BoolConverter()
  @Index()
  late bool boolValue;

  @IntConverter()
  @Index()
  late short intValue;

  @IntConverter()
  @Index()
  late int longValue;

  @DoubleConverter()
  @Index()
  late float floatValue;

  @DoubleConverter()
  @Index()
  late double doubleValue;

  @DateConverter()
  @Index()
  late DateTime dateValue;

  @StringConverter()
  @Index()
  late String stringValue;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    if (other is MultiConverterModel) {
      return boolValue == other.boolValue &&
          intValue == other.intValue &&
          longValue == other.longValue &&
          floatValue == other.floatValue &&
          doubleValue == other.doubleValue &&
          dateValue == other.dateValue &&
          stringValue == other.stringValue;
    } else {
      return false;
    }
  }
}

class BoolConverter extends TypeConverter<bool, String> {
  const BoolConverter();

  @override
  bool fromIsar(String object) {
    return object == 'true';
  }

  @override
  String toIsar(bool object) {
    return object.toString();
  }
}

class IntConverter extends TypeConverter<int, String> {
  const IntConverter();

  @override
  int fromIsar(String object) {
    return int.parse(object);
  }

  @override
  String toIsar(int object) {
    return object.toString();
  }
}

class DoubleConverter extends TypeConverter<double, String> {
  const DoubleConverter();

  @override
  double fromIsar(String object) {
    return double.parse(object);
  }

  @override
  String toIsar(double object) {
    return object.toString();
  }
}

class DateConverter extends TypeConverter<DateTime, String> {
  const DateConverter();

  @override
  DateTime fromIsar(String object) {
    return DateTime.fromMicrosecondsSinceEpoch(int.parse(object));
  }

  @override
  String toIsar(DateTime object) {
    return object.microsecondsSinceEpoch.toString();
  }
}

class StringConverter extends TypeConverter<String, int> {
  const StringConverter();

  @override
  String fromIsar(int object) {
    return object == 5 ? 'five' : 'something';
  }

  @override
  int toIsar(String object) {
    return object == 'five' ? 5 : 10;
  }
}

void main() {
  final converterObject = MultiConverterModel(
    id: 123,
    boolValue: true,
    intValue: 25,
    floatValue: 17.17,
    longValue: 123123,
    doubleValue: 123.123,
    dateValue: DateTime.fromMillisecondsSinceEpoch(123123),
    stringValue: 'five',
  );

  final converterObjectJson = <String, Object>{
    'id': 123,
    'boolValue': 'true',
    'intValue': '25',
    'floatValue': '17.17',
    'longValue': '123123',
    'doubleValue': '123.123',
    'dateValue': '123123000',
    'stringValue': 5,
  };

  group('Multiple converter', () {
    isarTest('toIsar()', () async {
      final isar = await openTempIsar([MultiConverterModelSchema]);

      await isar.writeTxn(() async {
        await isar.multiConverterModels.put(converterObject);
      });

      final json = await isar.multiConverterModels.where().exportJson();
      expect(json[0], converterObjectJson);

      await isar.close();
    });

    isarTest('fromIsar()', () async {
      final isar = await openTempIsar([MultiConverterModelSchema]);

      await isar.writeTxn(() async {
        await isar.multiConverterModels.importJson([converterObjectJson]);
      });

      expect(
        await isar.multiConverterModels.get(123),
        converterObject,
      );

      await isar.close();
    });
  });
}
