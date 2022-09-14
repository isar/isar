import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_date_time_test.g.dart';

@collection
class DateTimeModel {
  DateTimeModel(this.field);
  Id? id;

  DateTime? field;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is DateTimeModel &&
      id == other.id &&
      other.field?.toUtc() == field?.toUtc();

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
  group('DateTime filter', () {
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
      await qEqual(col.filter().fieldEqualTo(local(2010)), [obj1, obj3]);
      await qEqual(col.filter().fieldEqualTo(utc(2010)), [obj1, obj3]);
      await qEqual(col.filter().fieldEqualTo(null), [objNull]);
      await qEqual(col.filter().fieldEqualTo(local(2027)), []);
    });

    isarTest('.greaterThan()', () async {
      await qEqual(col.filter().fieldGreaterThan(local(2010)), [obj2, obj4]);
      await qEqual(
        col.filter().fieldGreaterThan(local(2010), include: true),
        [obj1, obj2, obj3, obj4],
      );
      await qEqual(
        col.filter().fieldGreaterThan(null),
        [obj1, obj2, obj3, obj4],
      );
      await qEqual(
        col.filter().fieldGreaterThan(null, include: true),
        [obj1, obj2, obj3, obj4, objNull],
      );
      await qEqual(col.filter().fieldGreaterThan(local(2050)), []);
    });

    isarTest('.lessThan()', () async {
      await qEqual(
        col.filter().fieldLessThan(local(2020)),
        [obj1, obj3, objNull],
      );
      await qEqual(
        col.filter().fieldLessThan(local(2020), include: true),
        [obj1, obj2, obj3, objNull],
      );
      await qEqual(col.filter().fieldLessThan(null), []);
      await qEqual(col.filter().fieldLessThan(null, include: true), [objNull]);
    });

    isarTest('.between()', () async {
      await qEqual(
        col.filter().fieldBetween(null, local(2010)),
        [obj1, obj3, objNull],
      );
      await qEqual(
        col.filter().fieldBetween(null, local(2020), includeLower: false),
        [obj1, obj2, obj3],
      );
      await qEqual(
        col.filter().fieldBetween(null, local(2020), includeUpper: false),
        [obj1, obj3, objNull],
      );
      await qEqual(col.filter().fieldBetween(local(2030), local(2035)), []);
      await qEqual(col.filter().fieldBetween(local(2020), local(2000)), []);
    });

    isarTest('.isNull()', () async {
      await qEqual(col.filter().fieldIsNull(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqual(col.filter().fieldIsNotNull(), [obj1, obj2, obj3, obj4]);
    });
  });
}
