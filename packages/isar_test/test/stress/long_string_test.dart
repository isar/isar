import 'dart:math';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'long_string_test.g.dart';

@collection
class StringModel {
  StringModel({
    this.string,
    this.stringList,
  });

  Id? id = Isar.autoIncrement;

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

    isarTest('Single', () async {
      final models = <StringModel>[
        for (var i = 0; i < 100; i++)
          StringModel(
            string: '${_randomStr(50000)}test$i${_randomStr(50000)}',
          ),
      ];
      await isar.tWriteTxn(() async {
        await isar.stringModels.tPutAll(models);
      });

      await qEqual(isar.stringModels.where(), models);

      await qEqual(
        isar.stringModels.filter().stringContains('test75'),
        [models[75]],
      );
      await qEqual(
        isar.stringModels.filter().stringMatches('*test66*'),
        [models[66]],
      );
    });

    isarTest('List', () async {
      final models = <StringModel>[
        for (var i = 0; i < 10; i++)
          StringModel(
            stringList: [
              for (var j = 0; j < 100; j++)
                '${_randomStr(10000)}test${i}_$j${_randomStr(10000)}',
            ],
          ),
      ];
      await isar.tWriteTxn(() async {
        await isar.stringModels.tPutAll(models);
      });

      await qEqual(isar.stringModels.where(), models);
    });
  });
}
