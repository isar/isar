import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'where_date_time_test.g.dart';

@Collection()
class DateTimeModel {
  DateTimeModel(this.field);
  Id? id;

  @Index()
  DateTime? field;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is DateTimeModel && other.field?.toUtc() == field?.toUtc();

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
  group('Where DateTime', () {
    late Isar isar;
    late IsarCollection<DateTimeModel> col;

    late DateTimeModel obj1;
    late DateTimeModel obj2;
    late DateTimeModel obj3;
    late DateTimeModel obj4;
    late DateTimeModel objNull;

    setUp(() async {
      isar = await openTempIsar([DateTimeModelSchema]);
      col = isar.dateTimeModels;

      obj1 = DateTimeModel(local(2010));
      obj2 = DateTimeModel(local(2020));
      obj3 = DateTimeModel(local(2010));
      obj4 = DateTimeModel(utc(2040));
      objNull = DateTimeModel(null);

      await isar.writeTxn(() async {
        await isar.dateTimeModels.putAll([obj1, obj2, obj3, obj4, objNull]);
      });
    });

    isarTest('.equalTo()', () async {
      await qEqual(
        col.where().fieldEqualTo(local(2010)).tFindAll(),
        [obj1, obj3],
      );
      await qEqual(
        col.where().fieldEqualTo(utc(2010)).tFindAll(),
        [obj1, obj3],
      );
      await qEqual(col.where().fieldEqualTo(null).tFindAll(), [objNull]);
      await qEqual(col.where().fieldEqualTo(local(2027)).tFindAll(), []);
    });

    isarTest('.notEqualTo()', () async {
      await qEqual(
        col.where().fieldNotEqualTo(local(2010)).tFindAll(),
        [objNull, obj2, obj4],
      );
      await qEqual(
        col.where().fieldNotEqualTo(utc(2010)).tFindAll(),
        [objNull, obj2, obj4],
      );
      await qEqual(
        col.where().fieldNotEqualTo(null).tFindAll(),
        [obj1, obj3, obj2, obj4],
      );
      await qEqual(
        col.where().fieldNotEqualTo(local(2027)).tFindAll(),
        [objNull, obj1, obj3, obj2, obj4],
      );
    });

    isarTest('.greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(local(2010)).tFindAll(),
        [obj2, obj4],
      );
      await qEqual(
        col.where().fieldGreaterThan(local(2010), include: true).tFindAll(),
        [obj1, obj3, obj2, obj4],
      );
      await qEqual(
        col.where().fieldGreaterThan(null).tFindAll(),
        [obj1, obj3, obj2, obj4],
      );
      await qEqual(
        col.where().fieldGreaterThan(null, include: true).tFindAll(),
        [objNull, obj1, obj3, obj2, obj4],
      );
      await qEqual(col.where().fieldGreaterThan(local(2050)).tFindAll(), []);
    });

    isarTest('.lessThan()', () async {
      await qEqual(
        col.where().fieldLessThan(local(2020)).tFindAll(),
        [objNull, obj1, obj3],
      );
      await qEqual(
        col.where().fieldLessThan(local(2020), include: true).tFindAll(),
        [objNull, obj1, obj3, obj2],
      );
      await qEqual(col.where().fieldLessThan(null).tFindAll(), []);
      await qEqual(
        col.where().fieldLessThan(null, include: true).tFindAll(),
        [objNull],
      );
    });

    isarTest('.between()', () async {
      await qEqual(
        col.where().fieldBetween(null, local(2010)).tFindAll(),
        [objNull, obj1, obj3],
      );
      await qEqual(
        col
            .where()
            .fieldBetween(null, local(2020), includeLower: false)
            .tFindAll(),
        [obj1, obj3, obj2],
      );
      await qEqual(
        col
            .where()
            .fieldBetween(null, local(2020), includeUpper: false)
            .tFindAll(),
        [objNull, obj1, obj3],
      );
      await qEqual(
        col.where().fieldBetween(local(2030), local(2035)).tFindAll(),
        [],
      );
      await qEqual(
        col.where().fieldBetween(local(2020), local(2000)).tFindAll(),
        [],
      );
    });

    isarTest('.isNull()', () async {
      await qEqual(col.where().fieldIsNull().tFindAll(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqual(
        col.where().fieldIsNotNull().tFindAll(),
        [obj1, obj3, obj2, obj4],
      );
    });
  });
}
