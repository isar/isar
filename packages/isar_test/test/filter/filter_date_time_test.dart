import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_date_time_test.g.dart';

@collection
class DateTimeModel {
  DateTimeModel(this.id, this.field);

  final int id;

  DateTime? field;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is DateTimeModel &&
      id == other.id &&
      other.field?.toUtc() == field?.toUtc();
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
    late IsarCollection<int, DateTimeModel> col;

    late DateTimeModel obj1;
    late DateTimeModel obj2;
    late DateTimeModel obj3;
    late DateTimeModel obj4;
    late DateTimeModel objNull;

    setUp(() {
      isar = openTempIsar([DateTimeModelSchema]);
      col = isar.dateTimeModels;

      obj1 = DateTimeModel(1, local(2010));
      obj2 = DateTimeModel(2, local(2020));
      obj3 = DateTimeModel(3, local(2010));
      obj4 = DateTimeModel(4, utc(2040));
      objNull = DateTimeModel(5, null);

      isar.writeTxn((isar) {
        isar.dateTimeModels.putAll([obj1, obj2, obj3, obj4, objNull]);
      });
    });

    isarTest('.equalTo()', () {
      expect(col.where().fieldEqualTo(local(2010)).findAll(), [obj1, obj3]);
      expect(col.where().fieldEqualTo(utc(2010)).findAll(), [obj1, obj3]);
      expect(col.where().fieldEqualTo(null).findAll(), [objNull]);
      expect(col.where().fieldEqualTo(local(2027)).findAll(), isEmpty);
    });

    isarTest('.greaterThan()', () {
      expect(col.where().fieldGreaterThan(local(2010)).findAll(), [obj2, obj4]);
      expect(
        col.where().fieldGreaterThan(local(2010), include: true).findAll(),
        [obj1, obj2, obj3, obj4],
      );
      expect(
        col.where().fieldGreaterThan(null).findAll(),
        [obj1, obj2, obj3, obj4],
      );
      expect(
        col.where().fieldGreaterThan(null, include: true).findAll(),
        [obj1, obj2, obj3, obj4, objNull],
      );
      expect(col.where().fieldGreaterThan(local(2050)).findAll(), isEmpty);
    });

    isarTest('.lessThan()', () {
      expect(
        col.where().fieldLessThan(local(2020)).findAll(),
        [obj1, obj3, objNull],
      );
      expect(
        col.where().fieldLessThan(local(2020), include: true).findAll(),
        [obj1, obj2, obj3, objNull],
      );
      expect(col.where().fieldLessThan(null).findAll(), isEmpty);
      expect(
        col.where().fieldLessThan(null, include: true).findAll(),
        [objNull],
      );
    });

    isarTest('.between()', () {
      expect(
        col.where().fieldBetween(null, local(2010)).findAll(),
        [obj1, obj3, objNull],
      );
      expect(
        col
            .where()
            .fieldBetween(null, local(2020), includeLower: false)
            .findAll(),
        [obj1, obj2, obj3],
      );
      expect(
        col
            .where()
            .fieldBetween(null, local(2020), includeUpper: false)
            .findAll(),
        [obj1, obj3, objNull],
      );
      expect(
        col.where().fieldBetween(local(2030), local(2035)).findAll(),
        isEmpty,
      );
      expect(
        col.where().fieldBetween(local(2020), local(2000)).findAll(),
        isEmpty,
      );
    });

    isarTest('.isNull()', () {
      expect(col.where().fieldIsNull().findAll(), [objNull]);
    });

    isarTest('.isNotNull()', () {
      expect(col.where().fieldIsNotNull().findAll(), [obj1, obj2, obj3, obj4]);
    });
  });
}
