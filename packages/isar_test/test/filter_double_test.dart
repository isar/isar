// DO NOT EDIT. Copy of float_filter.dart
// Float -> Double, float -> double

import 'package:isar/isar.dart';
import 'common.dart';
import 'package:test/test.dart';

part 'filter_double_test.g.dart';

@Collection()
class DoubleModel {
  @Id()
  int? id;

  @Index()
  double? field = 0;

  @Index(type: IndexType.value)
  List<double?>? list;

  DoubleModel();

  @override
  String toString() {
    return '{id: $id, field: $field, list: $list}';
  }

  @override
  bool operator ==(other) {
    final otherModel = other as DoubleModel;
    if ((other.field == null) != (field == null)) {
      return false;
    } else if (id != other.id) {
      return false;
    } else if (field != null && (otherModel.field! - field!).abs() > 0.001) {
      return false;
    } else if (!doubleListEquals(list, other.list)) {
      return false;
    }

    return true;
  }
}

void main() {
  group('Double filter', () {
    late Isar isar;
    late IsarCollection<DoubleModel> col;

    late DoubleModel obj0;
    late DoubleModel obj1;
    late DoubleModel obj2;
    late DoubleModel obj3;
    late DoubleModel objInf;
    late DoubleModel objNull;

    setUp(() async {
      isar = await openTempIsar([DoubleModelSchema]);
      col = isar.doubleModels;

      obj0 = DoubleModel()..field = 0;
      obj1 = DoubleModel()..field = 1.1;
      obj2 = DoubleModel()..field = 2.2;
      obj3 = DoubleModel()..field = 3.3;
      objInf = DoubleModel()..field = double.infinity;
      objNull = DoubleModel()..field = null;

      await isar.writeTxn((isar) async {
        await col.putAll([objInf, obj0, obj2, obj1, obj3, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.greaterThan()', () async {
      // where clauses
      await qEqual(
        col.where().fieldGreaterThan(null).findAll(),
        [obj0, obj1, obj2, obj3, objInf],
      );
      await qEqual(col.where().fieldGreaterThan(2.2).findAll(), [obj3, objInf]);
      await qEqual(col.where().fieldGreaterThan(double.infinity).findAll(), []);

      // filters
      await qEqualSet(
        col.filter().fieldGreaterThan(null).findAll(),
        [obj0, obj1, obj2, obj3, objInf],
      );
      await qEqualSet(
        col.filter().fieldGreaterThan(2.2).findAll(),
        [obj3, objInf],
      );
      await qEqualSet(
          col.filter().fieldGreaterThan(double.infinity).findAll(), []);
    });

    isarTest('.lessThan()', () async {
      await qEqual(col.where().fieldLessThan(1.1).findAll(), [objNull, obj0]);
      await qEqual(col.where().fieldLessThan(null).findAll(), []);

      await qEqualSet(
        col.filter().fieldLessThan(1.1).findAll(),
        [objNull, obj0],
      );
      await qEqualSet(col.filter().fieldLessThan(null).findAll(), []);
    });

    isarTest('.between()', () async {
      // where clauses
      await qEqual(
        col.where().fieldBetween(1.0, 3.5).findAll(),
        [obj1, obj2, obj3],
      );
      await qEqual(col.where().fieldBetween(5, 6).findAll(), []);

      // filters
      await qEqualSet(
        col.filter().fieldBetween(1.0, 3.5).findAll(),
        [obj1, obj2, obj3],
      );
      await qEqualSet(col.filter().fieldBetween(5, 6).findAll(), []);
    });

    isarTest('.isNull() / .isNotNull()', () async {
      await qEqual(col.where().fieldIsNull().findAll(), [objNull]);
      await qEqual(
        col.where().fieldIsNotNull().findAll(),
        [obj0, obj1, obj2, obj3, objInf],
      );

      await qEqual(col.filter().fieldIsNull().findAll(), [objNull]);
    });
  });

  group('Double list filter', () {
    late Isar isar;
    late IsarCollection<DoubleModel> col;

    late DoubleModel objEmpty;
    late DoubleModel obj1;
    late DoubleModel obj2;
    late DoubleModel obj3;
    late DoubleModel objNull;

    setUp(() async {
      isar = await openTempIsar([DoubleModelSchema]);
      col = isar.doubleModels;

      objEmpty = DoubleModel()..list = [];
      obj1 = DoubleModel()..list = [1.1, 3.3];
      obj2 = DoubleModel()..list = [null];
      obj3 = DoubleModel()..list = [null, double.negativeInfinity];
      objNull = DoubleModel()..list = null;

      await isar.writeTxn((isar) async {
        await col.putAll([objEmpty, obj1, obj3, obj2, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.anyGreaterThan() / .anyLessThan()', () async {
      // where clauses
      await qEqualSet(col.where().listAnyGreaterThan(1.1).findAll(), [obj1]);
      await qEqualSet(col.where().listAnyGreaterThan(4).findAll(), []);
      await qEqualSet(col.where().listAnyLessThan(1.1).findAll(), [obj2, obj3]);
      await qEqualSet(col.where().listAnyLessThan(null).findAll(), []);

      // filters
      await qEqualSet(col.filter().listAnyGreaterThan(1.1).findAll(), [obj1]);
      await qEqualSet(col.filter().listAnyGreaterThan(4).findAll(), []);
      await qEqualSet(
        col.filter().listAnyLessThan(1.1).findAll(),
        [obj2, obj3],
      );
      await qEqualSet(col.filter().listAnyLessThan(null).findAll(), []);
    });

    isarTest('.anyBetween()', () async {
      // where clauses
      await qEqualSet(col.where().listAnyBetween(1, 5).findAll(), [obj1]);
      await qEqualSet(col.where().listAnyBetween(5.0, 10.0).findAll(), []);

      // filters
      await qEqualSet(col.filter().listAnyBetween(1, 5).findAll(), [obj1]);
      await qEqualSet(col.filter().listAnyBetween(5.0, 10.0).findAll(), []);
    });

    isarTest('.anyIsNull() / .anyIsNotNull()', () async {
      // where clauses
      await qEqualSet(col.where().listAnyIsNull().findAll(), [obj2, obj3]);
      await qEqualSet(col.where().listAnyIsNotNull().findAll(), [obj1, obj3]);

      // filters
      await qEqualSet(col.filter().listAnyIsNull().findAll(), [obj2, obj3]);
    });
  });
}
