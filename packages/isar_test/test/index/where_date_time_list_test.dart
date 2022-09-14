import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'where_date_time_list_test.g.dart';

@collection
class DateTimeModel {
  DateTimeModel({
    required this.values,
    required this.nullableValues,
    required this.valuesNullable,
    required this.nullableValuesNullable,
  })  : hash = values,
        nullableHash = nullableValues,
        hashNullable = valuesNullable,
        nullableHashNullable = nullableValuesNullable;

  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  List<DateTime> values;

  @Index(type: IndexType.value)
  List<DateTime?> nullableValues;

  @Index(type: IndexType.value)
  List<DateTime>? valuesNullable;

  @Index(type: IndexType.value)
  List<DateTime?>? nullableValuesNullable;

  @Index(type: IndexType.hash)
  List<DateTime> hash;

  @Index(type: IndexType.hash)
  List<DateTime?> nullableHash;

  @Index(type: IndexType.hash)
  List<DateTime>? hashNullable;

  @Index(type: IndexType.hash)
  List<DateTime?>? nullableHashNullable;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is DateTimeModel &&
      id == other.id &&
      dateTimeListEquals(values, other.values) &&
      dateTimeListEquals(nullableValues, other.nullableValues) &&
      dateTimeListEquals(valuesNullable, other.valuesNullable) &&
      dateTimeListEquals(
        nullableValuesNullable,
        other.nullableValuesNullable,
      ) &&
      dateTimeListEquals(hash, other.hash) &&
      dateTimeListEquals(nullableHash, other.nullableHash) &&
      dateTimeListEquals(hashNullable, other.hashNullable) &&
      dateTimeListEquals(nullableHashNullable, other.nullableHashNullable);

  @override
  String toString() {
    return '''DateTimeModel{id: $id, values: $values, nullableValues: $nullableValues, valuesNullable: $valuesNullable, nullableValuesNullable: $nullableValuesNullable, hash: $hash, nullableHash: $nullableHash, hashNullable: $hashNullable, nullableHashNullable: $nullableHashNullable}''';
  }
}

void main() {
  group('Where DateTime list', () {
    late Isar isar;

    late DateTimeModel obj1;
    late DateTimeModel obj2;
    late DateTimeModel obj3;
    late DateTimeModel obj4;
    late DateTimeModel obj5;
    late DateTimeModel obj6;

    setUp(() async {
      isar = await openTempIsar([DateTimeModelSchema]);

      obj1 = DateTimeModel(
        values: [DateTime(2001), DateTime(2002), DateTime(2003).toUtc()],
        nullableValues: [DateTime(2001), null, DateTime(2003).toUtc()],
        valuesNullable: [DateTime(2001)],
        nullableValuesNullable: [DateTime(2001), null, null],
      );
      obj2 = DateTimeModel(
        values: [DateTime(2002), DateTime(2004).toUtc()],
        nullableValues: [
          DateTime(2002),
          DateTime(2003),
          DateTime(2003).toUtc(),
        ],
        valuesNullable: null,
        nullableValuesNullable: null,
      );
      obj3 = DateTimeModel(
        values: [],
        nullableValues: [],
        valuesNullable: [],
        nullableValuesNullable: [],
      );
      obj4 = DateTimeModel(
        values: [DateTime(2001), DateTime(2005), DateTime(2006)],
        nullableValues: [DateTime(2004), DateTime(2005)],
        valuesNullable: [DateTime(2004), DateTime(2005), DateTime(2006)],
        nullableValuesNullable: [null, null, null],
      );
      obj5 = DateTimeModel(
        values: [
          DateTime(2003),
          DateTime(2004),
          DateTime(2005),
          DateTime(2006),
          DateTime(2007),
        ],
        nullableValues: [
          null,
          DateTime(2003),
          DateTime(2004),
          DateTime(2005),
          DateTime(2006),
        ],
        valuesNullable: [DateTime(2001)],
        nullableValuesNullable: null,
      );
      obj6 = DateTimeModel(
        values: [DateTime(0)],
        nullableValues: [
          DateTime(0),
          DateTime(2002),
          DateTime(2005),
          DateTime(2006),
        ],
        valuesNullable: [DateTime(2004), DateTime(2005), DateTime(0)],
        nullableValuesNullable: [
          null,
          DateTime(0),
          DateTime(2003),
          DateTime(2005),
        ],
      );

      await isar.tWriteTxn(
        () => isar.dateTimeModels.tPutAll([obj1, obj2, obj3, obj4, obj5, obj6]),
      );
    });

    isarTest('.equalTo()', () async {
      await qEqualSet(
        isar.dateTimeModels.where().hashEqualTo([
          DateTime(2001),
          DateTime(2002),
          DateTime(2003).toUtc(),
        ]),
        [obj1],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .hashEqualTo([DateTime(2002), DateTime(2004).toUtc()]),
        [obj2],
      );
      await qEqualSet(
        isar.dateTimeModels.where().hashEqualTo([]),
        [obj3],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .hashEqualTo([DateTime(2001), DateTime(2005), DateTime(2006)]),
        [obj4],
      );
      await qEqualSet(
        isar.dateTimeModels.where().hashEqualTo(
          [
            DateTime(2003),
            DateTime(2004),
            DateTime(2005),
            DateTime(2006),
            DateTime(2007),
          ],
        ),
        [obj5],
      );
      await qEqualSet(
        isar.dateTimeModels.where().hashEqualTo([DateTime(0)]),
        [obj6],
      );
      await qEqualSet(
        isar.dateTimeModels.where().hashEqualTo([DateTime(2042)]),
        [],
      );

      await qEqualSet(
        isar.dateTimeModels.where().nullableHashEqualTo([
          DateTime(2001),
          null,
          DateTime(2003).toUtc(),
        ]),
        [obj1],
      );
      await qEqualSet(
        isar.dateTimeModels.where().nullableHashEqualTo([
          DateTime(2002),
          DateTime(2003),
          DateTime(2003).toUtc(),
        ]),
        [obj2],
      );
      await qEqualSet(
        isar.dateTimeModels.where().nullableHashEqualTo([]),
        [obj3],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableHashEqualTo([DateTime(2004), DateTime(2005)]),
        [obj4],
      );
      await qEqualSet(
        isar.dateTimeModels.where().nullableHashEqualTo([
          null,
          DateTime(2003),
          DateTime(2004),
          DateTime(2005),
          DateTime(2006),
        ]),
        [obj5],
      );
      await qEqualSet(
        isar.dateTimeModels.where().nullableHashEqualTo([
          DateTime(0),
          DateTime(2002),
          DateTime(2005),
          DateTime(2006),
        ]),
        [obj6],
      );

      await qEqualSet(
        isar.dateTimeModels.where().hashNullableEqualTo([DateTime(2001)]),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.dateTimeModels.where().hashNullableEqualTo([]),
        [obj3],
      );
      await qEqualSet(
        isar.dateTimeModels.where().hashNullableEqualTo([
          DateTime(2004),
          DateTime(2005),
          DateTime(2006),
        ]),
        [obj4],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .hashNullableEqualTo([DateTime(2004), DateTime(2005), DateTime(0)]),
        [obj6],
      );

      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableHashNullableEqualTo([DateTime(2001), null, null]),
        [obj1],
      );
      await qEqualSet(
        isar.dateTimeModels.where().nullableHashNullableEqualTo([]),
        [obj3],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableHashNullableEqualTo([null, null, null]),
        [obj4],
      );
      await qEqualSet(
        isar.dateTimeModels.where().nullableHashNullableEqualTo([
          null,
          DateTime(0),
          DateTime(2003),
          DateTime(2005),
        ]),
        [obj6],
      );
    });

    isarTest('.elementEqualTo()', () async {
      await qEqualSet(
        isar.dateTimeModels.where().valuesElementEqualTo(DateTime(0)),
        [obj6],
      );
      await qEqualSet(
        isar.dateTimeModels.where().valuesElementEqualTo(DateTime(2001)),
        [obj1, obj4],
      );
      await qEqualSet(
        isar.dateTimeModels.where().valuesElementEqualTo(DateTime(2002)),
        [obj1, obj2],
      );
      await qEqualSet(
        isar.dateTimeModels.where().valuesElementEqualTo(DateTime(2003)),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.dateTimeModels.where().valuesElementEqualTo(DateTime(2004)),
        [obj2, obj5],
      );
      await qEqualSet(
        isar.dateTimeModels.where().valuesElementEqualTo(DateTime(2005)),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.dateTimeModels.where().valuesElementEqualTo(DateTime(2006)),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.dateTimeModels.where().valuesElementEqualTo(DateTime(2007)),
        [obj5],
      );
      await qEqualSet(
        isar.dateTimeModels.where().valuesElementEqualTo(DateTime(2042)),
        [],
      );

      await qEqualSet(
        isar.dateTimeModels.where().nullableValuesElementEqualTo(DateTime(0)),
        [obj6],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesElementEqualTo(DateTime(2001)),
        [obj1],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesElementEqualTo(DateTime(2002)),
        [obj2, obj6],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesElementEqualTo(DateTime(2003)),
        [obj1, obj2, obj5],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesElementEqualTo(DateTime(2004)),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesElementEqualTo(DateTime(2005)),
        [obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesElementEqualTo(DateTime(2006)),
        [obj5, obj6],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesElementEqualTo(DateTime(2042)),
        [],
      );

      await qEqualSet(
        isar.dateTimeModels.where().valuesNullableElementEqualTo(DateTime(0)),
        [obj6],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .valuesNullableElementEqualTo(DateTime(2001)),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .valuesNullableElementEqualTo(DateTime(2004)),
        [obj4, obj6],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .valuesNullableElementEqualTo(DateTime(2005)),
        [obj4, obj6],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .valuesNullableElementEqualTo(DateTime(2006)),
        [obj4],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .valuesNullableElementEqualTo(DateTime(2042)),
        [],
      );

      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesNullableElementEqualTo(DateTime(0)),
        [obj6],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesNullableElementEqualTo(DateTime(2001)),
        [obj1],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesNullableElementEqualTo(DateTime(2003)),
        [obj6],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesNullableElementEqualTo(DateTime(2005)),
        [obj6],
      );
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesNullableElementEqualTo(DateTime(2042)),
        [],
      );
    });

    isarTest('.elementIsNull()', () async {
      await qEqualSet(
        isar.dateTimeModels.where().nullableValuesElementIsNull(),
        [obj1, obj5],
      );

      await qEqualSet(
        isar.dateTimeModels.where().nullableValuesNullableElementIsNull(),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.elementIsNotNull()', () async {
      await qEqualSet(
        isar.dateTimeModels.where().nullableValuesElementIsNotNull(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.dateTimeModels.where().nullableValuesNullableElementIsNotNull(),
        [obj1, obj6],
      );
    });

    isarTest('.elementGreaterThan()', () async {
      await qEqualSet(
        isar.dateTimeModels.where().valuesElementGreaterThan(DateTime(2003)),
        [obj2, obj4, obj5],
      );

      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesElementGreaterThan(DateTime(2003)),
        [obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.dateTimeModels
            .where()
            .valuesNullableElementGreaterThan(DateTime(2003)),
        [obj4, obj6],
      );

      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesNullableElementGreaterThan(DateTime(2003)),
        [obj6],
      );
    });

    isarTest('.elementLessThan()', () async {
      await qEqualSet(
        isar.dateTimeModels.where().valuesElementLessThan(DateTime(2003)),
        [obj1, obj2, obj4, obj6],
      );

      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesElementLessThan(DateTime(2003)),
        [obj1, obj2, obj5, obj6],
      );

      await qEqualSet(
        isar.dateTimeModels
            .where()
            .valuesNullableElementLessThan(DateTime(2003)),
        [obj1, obj5, obj6],
      );

      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesNullableElementLessThan(DateTime(2003)),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.elementBetween()', () async {
      await qEqualSet(
        isar.dateTimeModels
            .where()
            .valuesElementBetween(DateTime(2002), DateTime(2004)),
        [obj1, obj2, obj5],
      );

      await qEqualSet(
        isar.dateTimeModels
            .where()
            .nullableValuesElementBetween(DateTime(2002), DateTime(2004)),
        [obj1, obj2, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.dateTimeModels
            .where()
            .valuesNullableElementBetween(DateTime(2002), DateTime(2004)),
        [obj4, obj6],
      );

      await qEqualSet(
        isar.dateTimeModels.where().nullableValuesNullableElementBetween(
              DateTime(2002),
              DateTime(2004),
            ),
        [obj6],
      );
    });

    // FIXME/TODO: Should `.lengthXXX()` / `.isEmpty` be implemented on
    // `values` indexes?

    isarTest('.isNull()', () async {
      // FIXME: `.isNull()` is not generated on `List<DateTime>?`
      // await qEqualSet(
      //   isar.dateTimeModels.where().valuesNullableIsNull(),
      //   [obj2],
      // );

      // FIXME: `.isNull()` is not generated on `List<DateTime?>?`
      // await qEqualSet(
      //   isar.dateTimeModels.where().nullableValuesNullableIsNull(),
      //   [obj2, obj5],
      // );

      await qEqualSet(
        isar.dateTimeModels.where().hashNullableIsNull(),
        [obj2],
      );

      await qEqualSet(
        isar.dateTimeModels.where().nullableHashNullableIsNull(),
        [obj2, obj5],
      );
    });

    isarTest('.isNotNull()', () async {
      // FIXME: `.isNotNull()` is not generated on `List<DateTime>?`
      // await qEqualSet(
      //   isar.dateTimeModels.where().valuesNullableIsNotNull(),
      //   [obj1, obj3, obj4, obj5, obj6],
      // );

      // FIXME: `.isNotNull()` is not generated on List<DateTime?>?
      // await qEqualSet(
      //   isar.dateTimeModels.where().nullableValuesNullableIsNotNull(),
      //   [obj1, obj3, obj4, obj6],
      // );

      await qEqualSet(
        isar.dateTimeModels.where().hashNullableIsNotNull(),
        [obj1, obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.dateTimeModels.where().nullableHashNullableIsNotNull(),
        [obj1, obj3, obj4, obj6],
      );
    });
  });
}
