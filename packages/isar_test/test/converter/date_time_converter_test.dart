import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'date_time_converter_test.g.dart';

@Collection()
class DateTimeModel {
  DateTimeModel({
    required this.dateTime,
    required this.nullableDateTime,
  });

  Id id = Isar.autoIncrement;

  @UnixToDateTimeTypeConverter()
  final DateTime dateTime;

  @UnixToNullableDateTimeTypeConverter()
  final DateTime? nullableDateTime;

  @override
  String toString() {
    return 'DateTimeModel{id: $id, dateTime: $dateTime, nullableDateTime: '
        '$nullableDateTime}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateTimeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dateTime == other.dateTime &&
          nullableDateTime == other.nullableDateTime;
}

class UnixToDateTimeTypeConverter extends TypeConverter<int, DateTime> {
  const UnixToDateTimeTypeConverter();

  @override
  int fromIsar(DateTime date) => date.millisecondsSinceEpoch ~/ 1000;

  @override
  DateTime toIsar(int unixTimestamp) {
    return DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
  }
}

class UnixToNullableDateTimeTypeConverter
    extends TypeConverter<int?, DateTime?> {
  const UnixToNullableDateTimeTypeConverter();

  @override
  int? fromIsar(DateTime? date) {
    if (date == null) return null;
    return date.millisecondsSinceEpoch ~/ 1000;
  }

  @override
  DateTime? toIsar(int? unixTimestamp) {
    if (unixTimestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
  }
}

void main() {
  group('DateTime converter', () {
    late Isar isar;

    late DateTimeModel obj0;
    late DateTimeModel obj1;
    late DateTimeModel obj2;
    late DateTimeModel obj3;
    late DateTimeModel obj4;
    late DateTimeModel obj5;

    setUp(() async {
      isar = await openTempIsar([DateTimeModelSchema]);

      obj0 = DateTimeModel(
        dateTime: DateTime(1980, 1, 12),
        nullableDateTime: DateTime(1992, 7, 21),
      );
      obj1 = DateTimeModel(
        dateTime: DateTime(1500, 3, 27),
        nullableDateTime: null,
      );
      obj2 = DateTimeModel(
        dateTime: DateTime(2100, 6, 2),
        nullableDateTime: null,
      );
      obj3 = DateTimeModel(
        dateTime: DateTime(2010, 12, 13),
        nullableDateTime: DateTime(1942, 3, 3),
      );
      obj4 = DateTimeModel(
        dateTime: DateTime(-42, 5, 22),
        nullableDateTime: null,
      );
      obj5 = DateTimeModel(
        dateTime: DateTime(2003, 6, 24),
        nullableDateTime: DateTime(2200, 3, 10),
      );

      await isar.tWriteTxn(
        () => isar.dateTimeModels.tPutAll([obj0, obj1, obj2, obj3, obj4, obj5]),
      );
    });

    tearDown(() => isar.close());

    isarTest('Query by dateTime', () async {
      await qEqualSet(
        isar.dateTimeModels
            .filter()
            .dateTimeEqualTo(DateTime(2010, 12, 13))
            .tFindAll(),
        [obj3],
      );

      await qEqualSet(
        isar.dateTimeModels
            .filter()
            .dateTimeGreaterThan(DateTime(2000))
            .tFindAll(),
        [obj2, obj3, obj5],
      );

      await qEqualSet(
        isar.dateTimeModels
            .filter()
            .dateTimeBetween(DateTime(1980, 1, 2), DateTime(2005, 1, 2))
            .tFindAll(),
        [obj0, obj5],
      );

      await qEqualSet(
        isar.dateTimeModels.filter().dateTimeLessThan(DateTime(0)).tFindAll(),
        [obj4],
      );
    });

    isarTest('Query by nullableDateTime', () async {
      await qEqualSet(
        isar.dateTimeModels.filter().nullableDateTimeIsNull().tFindAll(),
        [obj1, obj2, obj4],
      );

      await qEqualSet(
        isar.dateTimeModels
            .filter()
            .nullableDateTimeGreaterThan(DateTime(2000))
            .tFindAll(),
        [obj5],
      );

      await qEqualSet(
        isar.dateTimeModels
            .filter()
            .nullableDateTimeLessThan(DateTime(1969))
            .tFindAll(),
        [obj1, obj2, obj3, obj4],
      );

      await qEqualSet(
        isar.dateTimeModels
            .filter()
            .nullableDateTimeBetween(DateTime(1950), DateTime(9999))
            .tFindAll(),
        [obj0, obj5],
      );
    });

    isarTest('Sort by dateTime', () async {
      await qEqual(
        isar.dateTimeModels.where().sortByDateTime().tFindAll(),
        [obj4, obj1, obj0, obj5, obj3, obj2],
      );

      await qEqual(
        isar.dateTimeModels.where().sortByDateTimeDesc().tFindAll(),
        [obj2, obj3, obj5, obj0, obj1, obj4],
      );
    });

    isarTest('Sort by nullableDateTime', () async {
      await qEqual(
        isar.dateTimeModels.where().sortByNullableDateTime().tFindAll(),
        [obj1, obj2, obj4, obj3, obj0, obj5],
      );

      await qEqual(
        isar.dateTimeModels.where().sortByNullableDateTimeDesc().tFindAll(),
        [obj5, obj0, obj3, obj1, obj2, obj4],
      );
    });
  });
}
