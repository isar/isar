import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_date_time_list_test.g.dart';

@collection
class DateTimeModel {
  DateTimeModel(this.id, this.list);

  final int id;

  final List<DateTime?>? list;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is DateTimeModel &&
      id == other.id &&
      listEquals(
        list?.map((e) => e?.toUtc()).toList(),
        other.list?.map((e) => e?.toUtc()).toList(),
      );
}

DateTime local(int year, [int month = 1, int day = 1]) {
  return DateTime(year, month, day);
}

DateTime utc(int year, [int month = 1, int day = 1]) {
  return local(year, month, day).toUtc();
}

void main() {
  group('DateTime list filter', () {
    late Isar isar;
    late IsarCollection<int, DateTimeModel> col;

    late DateTimeModel obj5;
    late DateTimeModel obj1;
    late DateTimeModel obj3;
    late DateTimeModel obj2;
    late DateTimeModel objEmpty;
    late DateTimeModel objNull;

    setUp(() async {
      isar = await openTempIsar([DateTimeModelSchema]);
      col = isar.dateTimeModels;

      obj1 = DateTimeModel(1, [local(2020), utc(2030), local(2020)]);
      obj2 = DateTimeModel(2, [utc(2030), local(2050)]);
      obj3 = DateTimeModel(3, [local(2010), utc(2020)]);
      objEmpty = DateTimeModel(4, []);
      obj5 = DateTimeModel(5, [null]);
      objNull = DateTimeModel(6, null);

      isar.write((isar) {
        col.putAll([obj1, obj2, obj3, objEmpty, obj5, objNull]);
      });
    });

    group('DateTime list filter', () {
      isarTest('.elementGreaterThan()', () {
        expect(
          col.where().listElementGreaterThan(local(2020)).findAll(),
          [obj1, obj2],
        );
        expect(
          col.where().listElementGreaterThan(null).findAll(),
          [obj1, obj2, obj3],
        );
      });

      isarTest('.elementGreaterThanOrEqualTo()', () {
        expect(
          col.where().listElementGreaterThanOrEqualTo(utc(2020)).findAll(),
          [obj1, obj2, obj3],
        );
        expect(
          col.where().listElementGreaterThanOrEqualTo(null).findAll(),
          [obj1, obj2, obj3, obj5],
        );
      });

      isarTest('.elementLessThan()', () {
        expect(
          col.where().listElementLessThan(utc(2020)).findAll(),
          [obj3, obj5],
        );
        expect(col.where().listElementLessThan(null).findAll(), isEmpty);
      });

      isarTest('.elementLessThanOrEqualTo()', () {
        expect(
          col.where().listElementLessThanOrEqualTo(local(2020)).findAll(),
          [obj1, obj3, obj5],
        );
        expect(
          col.where().listElementLessThanOrEqualTo(null).findAll(),
          [obj5],
        );
      });

      isarTest('.elementBetween()', () {
        expect(
          col.where().listElementBetween(utc(2010), utc(2020)).findAll(),
          [obj1, obj3],
        );
        expect(
          col.where().listElementBetween(null, utc(2010)).findAll(),
          [obj3, obj5],
        );
      });

      isarTest('.elementIsNull()', () {
        expect(col.where().listElementIsNull().findAll(), [obj5]);
      });

      isarTest('.elementIsNotNull()', () {
        expect(
          col.where().listElementIsNotNull().findAll(),
          [obj1, obj2, obj3],
        );
      });

      isarTest('.isNull()', () {
        expect(col.where().listIsNull().findAll(), [objNull]);
      });

      isarTest('.isNotNull()', () {
        expect(
          col.where().listIsNotNull().findAll(),
          [obj1, obj2, obj3, objEmpty, obj5],
        );
      });
    });
  });
}
