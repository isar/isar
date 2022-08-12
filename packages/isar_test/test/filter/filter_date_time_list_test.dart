import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'filter_date_time_list_test.g.dart';

@Collection()
class DateTimeModel {
  DateTimeModel(this.list);
  Id? id;

  List<DateTime?>? list;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is DateTimeModel &&
      listEquals(
        list?.map((e) => e?.toUtc()).toList(),
        other.list?.map((e) => e?.toUtc()).toList(),
      );

  @override
  String toString() {
    // TODO: implement toString
    return '$list';
  }
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
    late DateTimeModel objEmpty;
    late DateTimeModel objNull;

    setUp(() async {
      isar = await openTempIsar([DateTimeModelSchema]);
      col = isar.dateTimeModels;

      obj1 = DateTimeModel([utc(2010), local(2020)]);
      obj2 = DateTimeModel([local(2020), utc(2030), local(2020)]);
      obj3 = DateTimeModel([local(2010), utc(2020)]);
      obj4 = DateTimeModel([utc(2030), local(2050)]);
      objEmpty = DateTimeModel([]);
      objNull = DateTimeModel(null);

      await isar.writeTxn(() async {
        await col.putAll([obj2, obj4, obj3, objEmpty, obj1, objNull]);
      });
    });

    tearDown(() => isar.close(deleteFromDisk: true));

    group('DateTime list filter', () {
      isarTest('.elementGreaterThan()', () async {
        await qEqual(
          col.filter().listElementGreaterThan(local(2020)).tFindAll(),
          [obj2, obj4],
        );
        await qEqual(
          col
              .filter()
              .listElementGreaterThan(utc(2020), include: true)
              .tFindAll(),
          [obj2, obj4, obj3, obj1],
        );
        await qEqual(
          col.filter().listElementGreaterThan(null).tFindAll(),
          [obj2, obj4, obj3, obj1],
        );
        await qEqual(
          col.filter().listElementGreaterThan(null, include: true).tFindAll(),
          [obj2, obj4, obj3, obj1, objNull],
        );
      });

      isarTest('.elementLessThan()', () {});

      isarTest('.elementBetween()', () {});

      isarTest('.isNull()', () {});
    });
  });
}
