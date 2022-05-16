import 'dart:convert';

import 'package:test/test.dart';
import 'package:isar/isar.dart';

import 'util/common.dart';
import 'user_model.dart';
import 'util/sync_async_helper.dart';

void main() {
  testSyncAsync(tests);
}

void tests() {
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

    isarTest(
      'big json',
      () async {
        final json = generateJson(100000);

        await isar.tWriteTxn(() async {
          await col.tImportJson(json);
        });

        for (var i = 0; i < json.length; i++) {
          json[i]['id'] = i + 1;
        }
        final exportedJson = await col.where().exportJson();
        expect(exportedJson, json);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

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

      await isar.tWriteTxn(() async {
        await col.tImportJson(json);
      });

      final exportedJsonNull = await col.where().exportJson();
      expect(exportedJsonNull, json);
    });

    isarTest('raw json', () async {
      final json = generateJson(10000);
      final bytes = const Utf8Encoder().convert(jsonEncode(json));
      await isar.tWriteTxn(() async {
        await col.tImportJsonRaw(bytes);
      });

      for (var i = 0; i < json.length; i++) {
        json[i]['id'] = i + 1;
      }
      final exportedJson = await col.where().exportJsonRaw((bytes) {
        return jsonDecode(const Utf8Decoder().convert(bytes));
      });
      expect(exportedJson, json);
    });
  });
}
