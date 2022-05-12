import 'package:test/test.dart';
import 'package:isar/isar.dart';

import 'util/common.dart';

part 'converter_test.g.dart';

@Collection()
class ConverterModel {
  @Id()
  int? id;

  @BoolConverter()
  @Index()
  late bool boolValue;

  @IntConverter()
  @Size32()
  @Index()
  late int intValue;

  @IntConverter()
  @Index()
  late int longValue;

  @DoubleConverter()
  @Size32()
  @Index()
  late double floatValue;

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
  bool operator ==(Object other) {
    if (other is ConverterModel) {
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
  final converterObject = ConverterModel()
    ..id = 123
    ..boolValue = true
    ..intValue = 25
    ..floatValue = 17.17
    ..longValue = 123123
    ..doubleValue = 123.123
    ..dateValue = DateTime.fromMillisecondsSinceEpoch(123123)
    ..stringValue = 'five';

  final converterObjectJson = {
    'id': 123,
    'boolValue': 'true',
    'intValue': '25',
    'floatValue': '17.17',
    'longValue': '123123',
    'doubleValue': '123.123',
    'dateValue': '123123000',
    'stringValue': 5,
  };

  group('Converter', () {
    /*isarTest('toIsar()', () async {
      final isar = await openTempIsar([ConverterModelSchema]);

      await isar.writeTxn((isar) async {
        await isar.converterModels.put(_converterObject);
      });

      final json = await isar.converterModels.where().exportJson();
      expect(json[0], _converterObjectJson);

      await isar.close();
    });*/

    isarTest('fromIsar()', () async {
      final isar = await openTempIsar([ConverterModelSchema]);

      await isar.writeTxn((isar) async {
        await isar.converterModels.importJson([converterObjectJson]);
      });

      expect(
        await isar.converterModels.get(123),
        converterObject,
      );

      await isar.close();
    });
  });
}
