// DO NOT EDIT. Copy of float_filter.dart
// Int -> Long, int -> long, remove @Size32()

import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'filter_long_test.g.dart';

@Collection()
class LongModel {
  @Id()
  int? id;

  @Index()
  int? field = 0;

  @Index(type: IndexType.value)
  List<int>? list;

  @Index(type: IndexType.hash)
  List<int>? hashList;

  LongModel();

  @override
  String toString() {
    return '{field: $field, list: $list}';
  }

  @override
  bool operator ==(other) {
    return (other as LongModel).field == field &&
        listEquals(list, other.list) &&
        listEquals(hashList, other.hashList);
  }
}

void main() {
  testSyncAsync(tests);
}

void tests() async {
  group('Long filter', () {
    late Isar isar;
    late IsarCollection<LongModel> col;

    setUp(() async {
      isar = await openTempIsar([LongModelSchema]);
      col = isar.longModels;

      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          final obj = LongModel()..field = i;
          await col.put(obj);
        }
        await col.put(LongModel()..field = null);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('equalTo()', () async {
      await qEqual(
        col.where().fieldEqualTo(2).tFindAll(),
        [LongModel()..field = 2],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(2).tFindAll(),
        [LongModel()..field = 2],
      );

      await qEqual(
        col.where().fieldEqualTo(null).tFindAll(),
        [LongModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(null).tFindAll(),
        [LongModel()..field = null],
      );

      await qEqual(
        col.where().fieldEqualTo(5).tFindAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(5).tFindAll(),
        [],
      );
    });

    isarTest('greaterThan()', () async {
      await qEqual(
        col.where().filter().fieldGreaterThan(3).tFindAll(),
        [LongModel()..field = 4],
      );

      await qEqual(
        col.where().fieldGreaterThan(4).tFindAll(),
        [],
      );
      await qEqualSet(
        col.where().filter().fieldGreaterThan(4).tFindAll(),
        [],
      );
    });

    isarTest('lessThan()', () async {
      await qEqual(
        col.where().fieldLessThan(1).tFindAll(),
        [LongModel()..field = null, LongModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldLessThan(1).tFindAll(),
        {LongModel()..field = null, LongModel()..field = 0},
      );
    });

    isarTest('between()', () async {
      await qEqual(
        col.where().fieldBetween(1, 3).tFindAll(),
        [
          LongModel()..field = 1,
          LongModel()..field = 2,
          LongModel()..field = 3
        ],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(1, 3).tFindAll(),
        {
          LongModel()..field = 1,
          LongModel()..field = 2,
          LongModel()..field = 3
        },
      );

      await qEqual(
        col.where().fieldBetween(null, 0).tFindAll(),
        [LongModel()..field = null, LongModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(null, 0).tFindAll(),
        {LongModel()..field = null, LongModel()..field = 0},
      );

      await qEqual(
        col.where().fieldBetween(5, 6).tFindAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldBetween(5, 6).tFindAll(),
        [],
      );
    });

    isarTest('isNull()', () async {
      await qEqual(
        col.where().fieldIsNull().tFindAll(),
        [LongModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldIsNull().tFindAll(),
        [LongModel()..field = null],
      );
    });

    isarTest('isNotNull()', () async {
      await qEqualSet(
        col.where().fieldIsNotNull().tFindAll(),
        {
          LongModel()..field = 0,
          LongModel()..field = 1,
          LongModel()..field = 2,
          LongModel()..field = 3,
          LongModel()..field = 4,
        },
      );
    });
  });
}
