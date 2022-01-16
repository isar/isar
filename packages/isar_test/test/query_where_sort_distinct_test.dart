import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:isar_test/int_model.dart';
import 'package:test/test.dart';

void main() {
  group('Where sort distinct', () {
    late Isar isar;
    late IsarCollection<IntModel> col;

    setUp(() async {
      isar = await openTempIsar([IntModelSchema]);
      col = isar.intModels;

      await isar.writeTxn((isar) async {
        for (var i = 0; i <= 2; i++) {
          var obj = IntModel()..field = i;
          obj.id = await col.put(obj);
        }
        for (var i = 2; i >= 0; i--) {
          var obj = IntModel()..field = i;
          obj.id = await col.put(obj);
        }
        await col.put(IntModel()..field = null);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.any()', () async {
      await qEqual(
        col.where().anyField().fieldProperty().findAll(),
        [null, 0, 0, 1, 1, 2, 2],
      );

      await qEqual(
        col.where(distinct: true).anyField().fieldProperty().findAll(),
        [null, 0, 1, 2],
      );

      await qEqual(
        col.where(sort: Sort.desc).anyField().fieldProperty().findAll(),
        [2, 2, 1, 1, 0, 0, null],
      );

      await qEqual(
        col
            .where(sort: Sort.desc, distinct: true)
            .anyField()
            .fieldProperty()
            .findAll(),
        [2, 1, 0, null],
      );
    });

    isarTest('.notEqualTo()', () async {
      await qEqual(
        col.where().fieldNotEqualTo(1).fieldProperty().findAll(),
        [null, 0, 0, 2, 2],
      );

      await qEqual(
        col.where(distinct: true).fieldNotEqualTo(1).fieldProperty().findAll(),
        [null, 0, 2],
      );

      await qEqual(
        col.where(sort: Sort.desc).fieldNotEqualTo(1).fieldProperty().findAll(),
        [2, 2, 0, 0, null],
      );

      await qEqual(
        col
            .where(sort: Sort.desc, distinct: true)
            .fieldNotEqualTo(1)
            .fieldProperty()
            .findAll(),
        [2, 0, null],
      );
    });

    isarTest('.isNotNull()', () async {
      await qEqual(
        col.where().fieldIsNotNull().fieldProperty().findAll(),
        [0, 0, 1, 1, 2, 2],
      );

      await qEqual(
        col.where(distinct: true).fieldIsNotNull().fieldProperty().findAll(),
        [0, 1, 2],
      );

      await qEqual(
        col.where(sort: Sort.desc).fieldIsNotNull().fieldProperty().findAll(),
        [2, 2, 1, 1, 0, 0],
      );

      await qEqual(
        col
            .where(sort: Sort.desc, distinct: true)
            .fieldIsNotNull()
            .fieldProperty()
            .findAll(),
        [2, 1, 0],
      );
    });
  });
}
