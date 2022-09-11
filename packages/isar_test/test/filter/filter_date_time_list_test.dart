import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_date_time_list_test.g.dart';

@collection
class DateTimeModel {
  DateTimeModel(this.list);
  Id? id;

  List<DateTime?>? list;

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
    late IsarCollection<DateTimeModel> col;

    late DateTimeModel obj1;
    late DateTimeModel obj2;
    late DateTimeModel obj3;
    late DateTimeModel obj4;
    late DateTimeModel objEmpty;
    late DateTimeModel objNull;

    setUp(() async {
      isar = await openTempIsar([DateTimeModelSchema]);
      col = isar.dateTimeModels;

      obj1 = DateTimeModel([null]);
      obj2 = DateTimeModel([local(2020), utc(2030), local(2020)]);
      obj3 = DateTimeModel([local(2010), utc(2020)]);
      obj4 = DateTimeModel([utc(2030), local(2050)]);
      objEmpty = DateTimeModel([]);
      objNull = DateTimeModel(null);

      await isar.writeTxn(() async {
        await col.putAll([obj2, obj4, obj3, objEmpty, obj1, objNull]);
      });
    });

    group('DateTime list filter', () {
      isarTest('.elementGreaterThan()', () async {
        await qEqual(
          col.filter().listElementGreaterThan(local(2020)),
          [obj2, obj4],
        );
        await qEqual(
          col.filter().listElementGreaterThan(utc(2020), include: true),
          [obj2, obj4, obj3],
        );
        await qEqual(
          col.filter().listElementGreaterThan(null),
          [obj2, obj4, obj3],
        );
        await qEqual(
          col.filter().listElementGreaterThan(null, include: true),
          [obj2, obj4, obj3, obj1],
        );
      });

      isarTest('.elementLessThan()', () async {
        await qEqual(col.filter().listElementLessThan(utc(2020)), [obj3, obj1]);
        await qEqual(
          col.filter().listElementLessThan(local(2020), include: true),
          [obj2, obj3, obj1],
        );
        await qEqual(col.filter().listElementLessThan(null), []);
        await qEqual(
          col.filter().listElementLessThan(null, include: true),
          [obj1],
        );
      });

      isarTest('.elementBetween()', () async {
        await qEqual(
          col.filter().listElementBetween(utc(2010), utc(2020)),
          [obj2, obj3],
        );
        await qEqual(
          col.filter().listElementBetween(
                utc(2010),
                utc(2020),
                includeUpper: false,
              ),
          [obj3],
        );
        await qEqual(
          col.filter().listElementBetween(null, utc(2010)),
          [obj3, obj1],
        );
        await qEqual(
          col.filter().listElementBetween(
                null,
                utc(2010),
                includeLower: false,
              ),
          [obj3],
        );
        await qEqual(
          col.filter().listElementBetween(
                null,
                utc(2010),
                includeUpper: false,
              ),
          [obj1],
        );
      });

      isarTest('.elementIsNull()', () async {
        await qEqual(col.filter().listElementIsNull(), [obj1]);
      });

      isarTest('.elementIsNotNull()', () async {
        await qEqual(col.filter().listElementIsNotNull(), [obj2, obj4, obj3]);
      });

      isarTest('.isNull()', () async {
        await qEqual(col.filter().listIsNull(), [objNull]);
      });

      isarTest('.isNotNull()', () async {
        await qEqual(
          col.filter().listIsNotNull(),
          [obj2, obj4, obj3, objEmpty, obj1],
        );
      });
    });
  });
}
