import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:test/test.dart';

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

void main() async {
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
        col.where().fieldEqualTo(2).findAll(),
        [LongModel()..field = 2],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(2).findAll(),
        [LongModel()..field = 2],
      );

      await qEqual(
        col.where().fieldEqualTo(null).findAll(),
        [LongModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(null).findAll(),
        [LongModel()..field = null],
      );

      await qEqual(
        col.where().fieldEqualTo(5).findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(5).findAll(),
        [],
      );
    });

    isarTest('greaterThan()', () async {
      await qEqual(
        col.where().filter().fieldGreaterThan(3).findAll(),
        [LongModel()..field = 4],
      );

      await qEqual(
        col.where().fieldGreaterThan(4).findAll(),
        [],
      );
      await qEqualSet(
        col.where().filter().fieldGreaterThan(4).findAll(),
        [],
      );
    });

    isarTest('lessThan()', () async {
      await qEqual(
        col.where().fieldLessThan(1).findAll(),
        [LongModel()..field = null, LongModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldLessThan(1).findAll(),
        {LongModel()..field = null, LongModel()..field = 0},
      );
    });

    isarTest('between()', () async {
      await qEqual(
        col.where().fieldBetween(1, 3).findAll(),
        [
          LongModel()..field = 1,
          LongModel()..field = 2,
          LongModel()..field = 3
        ],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(1, 3).findAll(),
        {
          LongModel()..field = 1,
          LongModel()..field = 2,
          LongModel()..field = 3
        },
      );

      await qEqual(
        col.where().fieldBetween(null, 0).findAll(),
        [LongModel()..field = null, LongModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(null, 0).findAll(),
        {LongModel()..field = null, LongModel()..field = 0},
      );

      await qEqual(
        col.where().fieldBetween(5, 6).findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldBetween(5, 6).findAll(),
        [],
      );
    });

    isarTest('isNull()', () async {
      await qEqual(
        col.where().fieldIsNull().findAll(),
        [LongModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldIsNull().findAll(),
        [LongModel()..field = null],
      );
    });

    isarTest('isNotNull()', () async {
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
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
