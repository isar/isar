import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'filter_float_test.g.dart';

@Collection()
class FloatModel {
  FloatModel();
  Id? id;

  float? field = 0;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is FloatModel && doubleEquals(field, other.field);
}

void main() {
  group('Float filter', () {
    late Isar isar;
    late IsarCollection<FloatModel> col;

    late FloatModel obj0;
    late FloatModel obj1;
    late FloatModel obj2;
    late FloatModel obj3;
    late FloatModel objInf;
    late FloatModel objNull;

    setUp(() async {
      isar = await openTempIsar([FloatModelSchema]);
      col = isar.floatModels;

      obj0 = FloatModel()..field = 0;
      obj1 = FloatModel()..field = 1.1;
      obj2 = FloatModel()..field = 2.2;
      obj3 = FloatModel()..field = 3.3;
      objInf = FloatModel()..field = double.infinity;
      objNull = FloatModel()..field = null;

      await isar.writeTxn(() async {
        await col.putAll([objInf, obj0, obj2, obj1, obj3, objNull]);
      });
    });

    isarTest('.greaterThan()', () async {
      await qEqualSet(
        col.filter().fieldGreaterThan(null).tFindAll(),
        [obj0, obj1, obj2, obj3, objInf],
      );
      await qEqualSet(
        col.filter().fieldGreaterThan(2.2).tFindAll(),
        [obj3, objInf],
      );
      await qEqualSet(
        col.filter().fieldGreaterThan(double.infinity).tFindAll(),
        [],
      );
    });

    isarTest('.lessThan()', () async {
      /*await qEqualSet(
        col.filter().fieldLessThan(1.1).tFindAll(),
        [objNull, obj0],
      );*/
      await qEqualSet(col.filter().fieldLessThan(null).tFindAll(), []);
    });

    isarTest('.between()', () async {
      await qEqualSet(
        col.filter().fieldBetween(1, 3.5).tFindAll(),
        [obj1, obj2, obj3],
      );
      await qEqualSet(col.filter().fieldBetween(5, 6).tFindAll(), []);
    });

    isarTest('.isNull()', () async {
      await qEqual(col.filter().fieldIsNull().tFindAll(), [objNull]);
    });
  });
}
