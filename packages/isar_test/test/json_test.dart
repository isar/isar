import 'dart:convert';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

import 'user_model.dart';

void main() {
  group('Json', () {
    late Isar isar;
    late IsarCollection<UserModel> col;

    setUp(() async {
      isar = await openTempIsar([UserModelSchema]);
      col = isar.userModels;
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
        final exportedJson = await col.where().build().tExportJson();
        expect(exportedJson, json);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    isarTest('primitive null', () async {
      final json = <Map<String, Object?>>[
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

      final exportedJsonNull = await col.where().build().tExportJson();
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
      final exportedJson =
          await col.where().build().tExportJsonRaw((Uint8List bytes) {
        return jsonDecode(const Utf8Decoder().convert(bytes));
      });
      expect(exportedJson, json);
    });
  });
}
