import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'int_converter_test.g.dart';

@Collection()
class IntModel {
  IntModel({
    required this.offsettedInt,
    required this.day,
    required this.otherDay,
    required this.nullableDay,
  });

  int id = Isar.autoIncrement;

  @OffsettedIntTypeConverter()
  final int offsettedInt;

  @Index(composite: [CompositeIndex('otherDay')])
  @DaysTypeConverter()
  final Days day;

  @DaysTypeConverter()
  final Days otherDay;

  @NullableDaysTypeConverter()
  @Size32()
  final Days? nullableDay;

  @override
  String toString() {
    return 'IntModel{id: $id, offsettedInt: $offsettedInt, day: $day, otherDay: $otherDay, nullableDay: $nullableDay}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is IntModel &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            offsettedInt == other.offsettedInt &&
            day == other.day &&
            otherDay == other.otherDay &&
            nullableDay == other.nullableDay;
  }
}

class OffsettedIntTypeConverter extends TypeConverter<int, int> {
  const OffsettedIntTypeConverter();

  @override
  int fromIsar(int value) => value - 42;

  @override
  int toIsar(int value) => value + 42;
}

enum Days {
  sunday(0),
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6);

  const Days(this.value);

  final int value;
}

class DaysTypeConverter extends TypeConverter<Days, int> {
  const DaysTypeConverter();

  @override
  Days fromIsar(int value) {
    return Days.values.firstWhere((element) => element.value == value);
  }

  @override
  int toIsar(Days day) => day.value;
}

class NullableDaysTypeConverter extends TypeConverter<Days?, int?> {
  const NullableDaysTypeConverter();

  @override
  Days? fromIsar(int? value) {
    if (value == null) return null;
    return Days.values.firstWhere((element) => element.value == value);
  }

  @override
  int? toIsar(Days? day) => day?.value;
}

void main() {
  group('Int converter', () {
    late Isar isar;

    late IntModel obj0;
    late IntModel obj1;
    late IntModel obj2;
    late IntModel obj3;
    late IntModel obj4;
    late IntModel obj5;
    late IntModel obj6;
    late IntModel obj7;

    setUp(() async {
      isar = await openTempIsar([IntModelSchema]);

      obj0 = IntModel(
        offsettedInt: 0,
        day: Days.wednesday,
        otherDay: Days.sunday,
        nullableDay: null,
      );
      obj1 = IntModel(
        offsettedInt: 24,
        day: Days.saturday,
        otherDay: Days.monday,
        nullableDay: Days.tuesday,
      );
      obj2 = IntModel(
        offsettedInt: 42,
        day: Days.thursday,
        otherDay: Days.tuesday,
        nullableDay: Days.sunday,
      );
      obj3 = IntModel(
        offsettedInt: -1024,
        day: Days.saturday,
        otherDay: Days.wednesday,
        nullableDay: Days.friday,
      );
      obj4 = IntModel(
        offsettedInt: 2048,
        day: Days.monday,
        otherDay: Days.thursday,
        nullableDay: null,
      );
      obj5 = IntModel(
        offsettedInt: -0,
        day: Days.sunday,
        otherDay: Days.friday,
        nullableDay: null,
      );
      obj6 = IntModel(
        offsettedInt: 5673873209,
        day: Days.saturday,
        otherDay: Days.saturday,
        nullableDay: Days.wednesday,
      );
      obj7 = IntModel(
        offsettedInt: 40,
        day: Days.friday,
        otherDay: Days.saturday,
        nullableDay: null,
      );

      await isar.tWriteTxn(
        () => isar.intModels.tPutAll([
          obj0,
          obj1,
          obj2,
          obj3,
          obj4,
          obj5,
          obj6,
          obj7,
        ]),
      );
    });

    tearDown(() => isar.close());

    isarTest('Query by offsettedInt', () async {
      await qEqual(
        isar.intModels
            .filter()
            .offsettedIntBetween(
              0,
              42,
              includeLower: false,
              includeUpper: false,
            )
            .tFindAll(),
        [obj1, obj7],
      );

      await qEqual(
        isar.intModels.filter().offsettedIntLessThan(1).tFindAll(),
        [obj0, obj3, obj5],
      );

      await qEqual(
        isar.intModels.filter().offsettedIntEqualTo(42).tFindAll(),
        [obj2],
      );

      await qEqual(
        isar.intModels.filter().offsettedIntGreaterThan(7).tFindAll(),
        [obj1, obj2, obj4, obj6, obj7],
      );
    });

    isarTest('Query by day', () async {
      await qEqual(
        isar.intModels.filter().dayEqualTo(Days.saturday).tFindAll(),
        [obj1, obj3, obj6],
      );

      await qEqual(
        isar.intModels.filter().dayBetween(Days.monday, Days.friday).tFindAll(),
        [obj0, obj2, obj4, obj7],
      );

      await qEqual(
        isar.intModels.filter().dayLessThan(Days.tuesday).tFindAll(),
        [obj4, obj5],
      );

      await qEqual(
        isar.intModels.filter().dayGreaterThan(Days.wednesday).tFindAll(),
        [obj1, obj2, obj3, obj6, obj7],
      );

      await qEqual(
        isar.intModels
            .filter()
            .dayGreaterThan(Days.monday)
            .and()
            .dayLessThan(Days.friday)
            .and()
            .dayGreaterThan(Days.wednesday)
            .tFindAll(),
        [obj2],
      );
    });

    isarTest('Query by dayOtherDay index', () async {
      await qEqual(
        isar.intModels
            .where()
            .dayOtherDayEqualTo(Days.saturday, Days.saturday)
            .tFindAll(),
        [obj6],
      );

      await qEqual(
        isar.intModels
            .where()
            .dayGreaterThanAnyOtherDay(Days.wednesday)
            .tFindAll(),
        [obj2, obj7, obj1, obj3, obj6],
      );

      await qEqual(
        isar.intModels
            .where()
            .dayEqualToOtherDayNotEqualTo(Days.saturday, Days.wednesday)
            .tFindAll(),
        [obj1, obj6],
      );
    });

    isarTest('Query by nullableDay', () async {
      await qEqual(
        isar.intModels.filter().nullableDayIsNull().tFindAll(),
        [obj0, obj4, obj5, obj7],
      );

      await qEqual(
        isar.intModels
            .filter()
            .nullableDayGreaterThan(Days.wednesday)
            .tFindAll(),
        [obj3],
      );

      await qEqual(
        isar.intModels.filter().nullableDayEqualTo(Days.saturday).tFindAll(),
        [],
      );
    });
  });
}
