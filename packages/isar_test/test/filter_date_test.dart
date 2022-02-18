import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'common.dart';

part 'filter_date_test.g.dart';

@Collection()
class DateTimeModel {
  @Id()
  int? id;

  @Index()
  DateTime? field;

  @Index(type: IndexType.value)
  List<DateTime?>? list;

  @Index(type: IndexType.hash)
  List<DateTime?>? hashList;

  DateTimeModel();

  @override
  bool operator ==(other) {
    if (other is DateTimeModel) {
      return other.field?.toUtc() == field?.toUtc() &&
          listEquals(
            list?.map((e) => e?.toUtc()).toList(),
            other.list?.map((e) => e?.toUtc()).toList(),
          ) &&
          listEquals(
            hashList?.map((e) => e?.toUtc()).toList(),
            other.hashList?.map((e) => e?.toUtc()).toList(),
          );
    }
    return false;
  }

  @override
  String toString() => '{id: $id, field: $field}';
}

DateTime local(int year, [int month = 1, int day = 1]) {
  return DateTime(year, month, day);
}

DateTime utc(int year, [int month = 1, int day = 1]) {
  return local(year, month, day).toUtc();
}

void main() {
  group('Date filter', () {
    late Isar isar;
    late IsarCollection<DateTimeModel> col;

    late DateTimeModel obj1;
    late DateTimeModel obj2;
    late DateTimeModel obj3;
    late DateTimeModel obj4;
    late DateTimeModel obj5;
    late DateTimeModel objNull;

    setUp(() async {
      isar = await openTempIsar([DateTimeModelSchema]);
      col = isar.dateTimeModels;

      obj1 = DateTimeModel()
        ..field = DateTime.now().subtract(const Duration(minutes: 10)).toUtc();
      obj2 = DateTimeModel()..field = DateTime.now();
      obj3 = DateTimeModel()
        ..field = DateTime.now().add(const Duration(minutes: 10)).toUtc();
      obj4 = DateTimeModel()..field = local(2025);
      obj5 = DateTimeModel()..field = local(2026);
      objNull = DateTimeModel()..field = null;

      await isar.writeTxn((isar) async {
        await isar.dateTimeModels
            .putAll([obj4, obj1, obj5, obj3, obj2, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.equalTo()', () async {
      // where clause
      await qEqual(col.where().fieldEqualTo(local(2025)).findAll(), [obj4]);
      await qEqual(col.where().fieldEqualTo(utc(2025)).findAll(), [obj4]);
      await qEqual(col.where().fieldEqualTo(null).findAll(), [objNull]);
      await qEqual(col.where().fieldEqualTo(local(2027)).findAll(), []);

      // filters
      await qEqual(col.filter().fieldEqualTo(local(2025)).findAll(), [obj4]);
      await qEqual(col.filter().fieldEqualTo(utc(2025)).findAll(), [obj4]);
      await qEqual(col.filter().fieldEqualTo(null).findAll(), [objNull]);
      await qEqual(col.filter().fieldEqualTo(local(2027)).findAll(), []);
    });

    isarTest('.greaterThan()', () async {
      // where clause
      await qEqual(col.where().fieldGreaterThan(local(2025)).findAll(), [obj5]);
      await qEqual(col.where().fieldGreaterThan(utc(2025)).findAll(), [obj5]);
      await qEqual(
        col.where().fieldGreaterThan(local(2025), include: true).findAll(),
        [obj4, obj5],
      );
      await qEqual(
        col.where().fieldGreaterThan(utc(2025), include: true).findAll(),
        [obj4, obj5],
      );
      await qEqual(
        col.where().fieldGreaterThan(null).findAll(),
        [obj1, obj2, obj3, obj4, obj5],
      );
      await qEqual(
        col.where().fieldGreaterThan(null, include: true).findAll(),
        [objNull, obj1, obj2, obj3, obj4, obj5],
      );
      await qEqual(col.where().fieldGreaterThan(local(2026)).findAll(), []);

      // filters
      await qEqual(
          col.filter().fieldGreaterThan(local(2025)).findAll(), [obj5]);
      await qEqual(col.filter().fieldGreaterThan(utc(2025)).findAll(), [obj5]);
      await qEqualSet(
        col.filter().fieldGreaterThan(local(2025), include: true).findAll(),
        [obj4, obj5],
      );
      await qEqualSet(
        col.filter().fieldGreaterThan(utc(2025), include: true).findAll(),
        [obj4, obj5],
      );
      await qEqualSet(
        col.filter().fieldGreaterThan(null).findAll(),
        [obj1, obj2, obj3, obj4, obj5],
      );
      await qEqualSet(
        col.filter().fieldGreaterThan(null, include: true).findAll(),
        [objNull, obj1, obj2, obj3, obj4, obj5],
      );
      await qEqual(col.filter().fieldGreaterThan(local(2026)).findAll(), []);
    });

    isarTest('.lessThan()', () async {
      // where clauses
      await qEqual(col.where().fieldLessThan(local(2025)).findAll(),
          [objNull, obj1, obj2, obj3]);
      await qEqual(col.where().fieldLessThan(utc(2025)).findAll(),
          [objNull, obj1, obj2, obj3]);
      await qEqual(col.where().fieldLessThan(null).findAll(), []);
      await qEqual(
        col.where().fieldLessThan(null, include: true).findAll(),
        [objNull],
      );

      // filters
      await qEqualSet(col.where().fieldLessThan(local(2025)).findAll(),
          [objNull, obj1, obj2, obj3]);
      await qEqualSet(col.where().fieldLessThan(utc(2025)).findAll(),
          [objNull, obj1, obj2, obj3]);
      await qEqual(col.where().fieldLessThan(null).findAll(), []);
      await qEqual(
        col.where().fieldLessThan(null, include: true).findAll(),
        [objNull],
      );
    });

    isarTest('.between()', () async {
      // where clauses
      await qEqual(
        col.where().fieldBetween(null, local(2025)).findAll(),
        [objNull, obj1, obj2, obj3, obj4],
      );
      await qEqual(
        col.where().fieldBetween(null, utc(2025)).findAll(),
        [objNull, obj1, obj2, obj3, obj4],
      );
      await qEqual(
        col
            .where()
            .fieldBetween(null, local(2025), includeLower: false)
            .findAll(),
        [obj1, obj2, obj3, obj4],
      );
      await qEqual(
        col
            .where()
            .fieldBetween(null, local(2025), includeUpper: false)
            .findAll(),
        [objNull, obj1, obj2, obj3],
      );
      await qEqual(
        col
            .where()
            .fieldBetween(
              null,
              local(2025),
              includeLower: false,
              includeUpper: false,
            )
            .findAll(),
        [obj1, obj2, obj3],
      );
      await qEqual(
          col.where().fieldBetween(local(2030), local(2035)).findAll(), []);

      // filters
      await qEqualSet(
        col.filter().fieldBetween(null, local(2025)).findAll(),
        [objNull, obj1, obj2, obj3, obj4],
      );
      await qEqualSet(
        col.filter().fieldBetween(null, utc(2025)).findAll(),
        [objNull, obj1, obj2, obj3, obj4],
      );
      await qEqualSet(
        col
            .filter()
            .fieldBetween(null, local(2025), includeLower: false)
            .findAll(),
        [obj1, obj2, obj3, obj4],
      );
      await qEqualSet(
        col
            .filter()
            .fieldBetween(null, local(2025), includeUpper: false)
            .findAll(),
        [objNull, obj1, obj2, obj3],
      );
      await qEqualSet(
        col
            .filter()
            .fieldBetween(
              null,
              local(2025),
              includeLower: false,
              includeUpper: false,
            )
            .findAll(),
        [obj1, obj2, obj3],
      );
      await qEqual(
          col.where().fieldBetween(local(2030), local(2035)).findAll(), []);
    });

    isarTest('.isNull() / .isNotNull()', () async {
      await qEqual(col.where().fieldIsNull().findAll(), [objNull]);
      await qEqual(
        col.where().fieldIsNotNull().findAll(),
        [obj1, obj2, obj3, obj4, obj5],
      );

      await qEqual(col.filter().fieldIsNull().findAll(), [objNull]);
    });
  });
}
