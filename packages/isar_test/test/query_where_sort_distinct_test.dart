import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:test/test.dart';

part 'query_where_sort_distinct_test.g.dart';

@Collection()
class TestModel {
  int? id;

  @Index()
  int? value;

  @override
  operator ==(other) {
    return other is TestModel && other.id == id && other.value == value;
  }
}

void main() {
  group('Where sort distinct', () {
    late Isar isar;
    late IsarCollection<TestModel> col;

    setUp(() async {
      isar = await openTempIsar([TestModelSchema]);
      col = isar.testModels;

      await isar.writeTxn((isar) async {
        for (var i = 0; i <= 2; i++) {
          var obj = TestModel()..value = i;
          obj.id = await col.put(obj);
        }
        for (var i = 2; i >= 0; i--) {
          var obj = TestModel()..value = i;
          obj.id = await col.put(obj);
        }
        await col.put(TestModel()..value = null);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.any()', () async {
      await qEqual(
        col.where().anyValue().valueProperty().findAll(),
        [null, 0, 0, 1, 1, 2, 2],
      );

      await qEqual(
        col.where(distinct: true).anyValue().valueProperty().findAll(),
        [null, 0, 1, 2],
      );

      await qEqual(
        col.where(sort: Sort.desc).anyValue().valueProperty().findAll(),
        [2, 2, 1, 1, 0, 0, null],
      );

      await qEqual(
        col
            .where(sort: Sort.desc, distinct: true)
            .anyValue()
            .valueProperty()
            .findAll(),
        [2, 1, 0, null],
      );
    });

    isarTest('.notEqualTo()', () async {
      await qEqual(
        col.where().valueNotEqualTo(1).valueProperty().findAll(),
        [null, 0, 0, 2, 2],
      );

      await qEqual(
        col.where(distinct: true).valueNotEqualTo(1).valueProperty().findAll(),
        [null, 0, 2],
      );

      await qEqual(
        col.where(sort: Sort.desc).valueNotEqualTo(1).valueProperty().findAll(),
        [2, 2, 0, 0, null],
      );

      await qEqual(
        col
            .where(sort: Sort.desc, distinct: true)
            .valueNotEqualTo(1)
            .valueProperty()
            .findAll(),
        [2, 0, null],
      );
    });

    isarTest('.isNotNull()', () async {
      await qEqual(
        col.where().valueIsNotNull().valueProperty().findAll(),
        [0, 0, 1, 1, 2, 2],
      );

      await qEqual(
        col.where(distinct: true).valueIsNotNull().valueProperty().findAll(),
        [0, 1, 2],
      );

      await qEqual(
        col.where(sort: Sort.desc).valueIsNotNull().valueProperty().findAll(),
        [2, 2, 1, 1, 0, 0],
      );

      await qEqual(
        col
            .where(sort: Sort.desc, distinct: true)
            .valueIsNotNull()
            .valueProperty()
            .findAll(),
        [2, 1, 0],
      );
    });
  });
}
