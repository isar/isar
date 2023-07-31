import 'dart:math';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'long_string_test.g.dart';

@collection
class StringModel {
  StringModel({
    required this.id,
    this.string,
    this.stringList,
  });

  int id;

  String? string;

  List<String>? stringList;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is StringModel &&
      string == other.string &&
      listEquals(stringList, other.stringList);
}

String _randomStr(int length) {
  final rand = Random();
  final runes = <int>[];
  for (var i = 0; i < length; i++) {
    runes.add(0x10000 + rand.nextInt(0x10000));
  }
  return String.fromCharCodes(runes);
}

void main() {
  group('Long String', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([StringModelSchema]);
    });

    isarTest('Single', () {
      final models = <StringModel>[
        for (var i = 0; i < 100; i++)
          StringModel(
            id: i,
            string: '${_randomStr(50000)}test$i${_randomStr(50000)}',
          ),
      ];
      isar.write((isar) {
        isar.stringModels.putAll(models);
      });

      expect(isar.stringModels.where().findAll(), models);

      expect(
        isar.stringModels.where().stringContains('test75').findAll(),
        [models[75]],
      );
      expect(
        isar.stringModels.where().stringMatches('*test66*').findAll(),
        [models[66]],
      );
    });

    isarTest('List', () {
      final models = <StringModel>[
        for (var i = 0; i < 10; i++)
          StringModel(
            id: i,
            stringList: [
              for (var j = 0; j < 100; j++)
                '${_randomStr(10000)}test${i}_$j${_randomStr(10000)}',
            ],
          ),
      ];
      isar.write((isar) {
        isar.stringModels.putAll(models);
      });

      expect(isar.stringModels.where().findAll(), models);
    });
  });
}
