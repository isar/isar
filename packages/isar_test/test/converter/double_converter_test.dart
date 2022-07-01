import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'double_converter_test.g.dart';

@Collection()
class DoubleModel {
  DoubleModel(this.value, this.someInt);

  int id = Isar.autoIncrement;

  @ValuesTypeConverter()
  final Values value;

  @Index(composite: [CompositeIndex('value')])
  final int someInt;

  @override
  String toString() {
    return 'DoubleModel{id: $id, value: $value, someInt: $someInt}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoubleModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value &&
          someInt == other.someInt;
}

enum Values {
  first(0),
  second(5123.582134),
  third(584114559420.110239),
  fourth(-5812903859.4583),
  fifth(349.1),
  sixth(-3659.1);

  const Values(this.value);

  final double value;
}

class ValuesTypeConverter extends TypeConverter<Values, double> {
  const ValuesTypeConverter();

  @override
  Values fromIsar(double value) {
    return Values.values.firstWhere((element) => element.value == value);
  }

  @override
  double toIsar(Values value) => value.value;
}

void main() {
  group('Double converter', () {
    late Isar isar;

    late DoubleModel obj0;
    late DoubleModel obj1;
    late DoubleModel obj2;
    late DoubleModel obj3;
    late DoubleModel obj4;

    setUp(() async {
      isar = await openTempIsar([DoubleModelSchema]);

      obj0 = DoubleModel(Values.fifth, 42);
      obj1 = DoubleModel(Values.first, 0);
      obj2 = DoubleModel(Values.sixth, -20);
      obj3 = DoubleModel(Values.first, 12);
      obj4 = DoubleModel(Values.third, 3);

      await isar.tWriteTxn(
        () => isar.doubleModels.tPutAll([obj0, obj1, obj2, obj3, obj4]),
      );
    });

    tearDown(() => isar.close());

    isarTest('Query by value', () async {
      await qEqual(
        isar.doubleModels.filter().valueGreaterThan(Values.first).tFindAll(),
        [obj0, obj4],
      );

      await qEqual(
        isar.doubleModels
            .filter()
            .valueBetween(Values.fourth, Values.second)
            .tFindAll(),
        [obj0, obj1, obj2, obj3],
      );

      await qEqual(
        isar.doubleModels.filter().valueLessThan(Values.fifth).tFindAll(),
        [obj1, obj2, obj3],
      );

      await qEqual(
        isar.doubleModels
            .filter()
            .valueBetween(Values.fourth, Values.fifth)
            .tFindAll(),
        [obj1, obj2, obj3],
      );

      await qEqual(
        isar.doubleModels.filter().valueGreaterThan(Values.third).tFindAll(),
        [],
      );
    });

    isarTest('Query by someIntValue', () async {
      await qEqual(
        isar.doubleModels.where().someIntEqualToAnyValue(42).tFindAll(),
        [obj0],
      );

      await qEqual(
        isar.doubleModels
            .where()
            .someIntEqualToValueGreaterThan(-20, Values.fourth)
            .tFindAll(),
        [obj2],
      );

      // FIXME: TypeConverter is not called on `Values.first` and `Values.fifth`
      //  in the generated code.
      //
      // Current:
      // lower: [someInt, lowerValue],
      // upper: [someInt, upperValue],
      //
      // Should be:
      // lower: [someInt, _doubleModelValuesTypeConverter.toIsar(lowerValue)],
      // upper: [someInt, _doubleModelValuesTypeConverter.toIsar(upperValue)],
      await qEqual(
        isar.doubleModels
            .where()
            .someIntEqualToValueBetween(12, Values.first, Values.fifth)
            .tFindAll(),
        [],
      );

      await qEqual(
        isar.doubleModels
            .where()
            .someIntEqualToValueLessThan(0, Values.first)
            .tFindAll(),
        [],
      );

      await qEqual(
        isar.doubleModels
            .where()
            .someIntEqualToValueLessThan(0, Values.second)
            .tFindAll(),
        [obj1],
      );
    });
  });
}
