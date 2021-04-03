import 'dart:convert';

import 'package:test/test.dart';

import 'common.dart';
import 'package:isar_test/isar.g.dart';
import 'package:isar_test/converter_model.dart';

void main() {
  final _converterObject = ConverterModel()
    ..id = 123
    ..boolValue = true
    ..intValue = 25
    ..floatValue = 17.17
    ..longValue = 123123
    ..doubleValue = 123.123
    ..dateValue = DateTime.fromMillisecondsSinceEpoch(123123)
    ..stringValue = 'five';

  final _converterObjectJson = {
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
    isarTest('toIsar()', () async {
      final isar = await openTempIsar();

      await isar.writeTxn((isar) async {
        await isar.converterModels.put(_converterObject);
      });

      final json = await isar.converterModels.jsonMap();
      expect(json[0], _converterObjectJson);

      await isar.close();
    });

    isarTest('fromIsar()', () async {
      final isar = await openTempIsar();

      await isar.writeTxn((isar) async {
        final bytes = Utf8Encoder().convert(jsonEncode([_converterObjectJson]));
        await isar.converterModels.importJson(bytes);
      });

      expect(
        await isar.converterModels.get(123),
        _converterObject,
      );

      await isar.close();
    });
  });
}
