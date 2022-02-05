import 'dart:convert';

import 'package:test/test.dart';
import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:isar_test/user_model.dart';

void main() {
  group('Json', () {
    late Isar isar;
    late IsarCollection<UserModel> col;

    setUp(() async {
      isar = await openTempIsar([UserModelSchema]);
      col = isar.userModels;
    });

    tearDown(() async {
      await isar.close();
    });

    List<Map<String, dynamic>> generateJson(int count) {
      final json = <Map<String, dynamic>>[];
      for (var i = 0; i < count; i++) {
        json.add({
          'name': 'User Number $i',
          'age': i % 100,
          'admin': i % 3 == 0,
        });
      }
      return json;
    }

    isarTest('big json', () async {
      final json = generateJson(100000);

      await isar.writeTxn((isar) async {
        await col.importJson(json);
      });

      for (var i = 0; i < json.length; i++) {
        json[i]['id'] = Isar.minId + i;
      }
      final exportedJson = await col.where().exportJson();
      expect(exportedJson, json);
    });

    isarTest('primitive null', () async {
      final json = [
        {
          'id': 0,
          'name': null,
          'age': null,
          'admin': true,
        },
        {
          'id': 1,
          'name': 'null user 2',
          'age': null,
          'admin': false,
        }
      ];

      await isar.writeTxn((isar) async {
        await col.importJson(json);
      });

      final exportedJsonNull = await col.where().exportJson();
      expect(exportedJsonNull, json);

      final exportedJsonNonNull =
          await col.where().exportJson(primitiveNull: false);
      expect(exportedJsonNonNull, [
        {
          'id': 0,
          'name': null,
          'age': Isar.minId - 1,
          'admin': true,
        },
        {
          'id': 1,
          'name': 'null user 2',
          'age': Isar.minId - 1,
          'admin': false,
        }
      ]);
    });

    isarTest('raw json', () async {
      final json = generateJson(10000);
      final bytes = const Utf8Encoder().convert(jsonEncode(json));
      await isar.writeTxn((isar) async {
        await col.importJsonRaw(bytes);
      });

      for (var i = 0; i < json.length; i++) {
        json[i]['id'] = Isar.minId + i;
      }
      final exportedJson = await col.where().exportJsonRaw((bytes) {
        return jsonDecode(const Utf8Decoder().convert(bytes));
      });
      expect(exportedJson, json);
    });
  });
}
