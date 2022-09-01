import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/matchers.dart';
import '../util/sync_async_helper.dart';

part 'where_string_list_test.g.dart';

@collection
class StringModel {
  StringModel({
    required this.values,
    required this.nullableValues,
    required this.valuesNullable,
    required this.nullableValuesNullable,
  })  : hash = values,
        nullableHash = nullableValues,
        hashNullable = valuesNullable,
        nullableHashNullable = nullableValuesNullable,
        hashes = values,
        nullableHashes = nullableValues,
        hashesNullable = valuesNullable,
        nullableHashesNullable = nullableValuesNullable;

  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  List<String> values;

  @Index(type: IndexType.value)
  List<String?> nullableValues;

  @Index(type: IndexType.value)
  List<String>? valuesNullable;

  @Index(type: IndexType.value)
  List<String?>? nullableValuesNullable;

  @Index(type: IndexType.hash)
  List<String> hash;

  @Index(type: IndexType.hash)
  List<String?> nullableHash;

  @Index(type: IndexType.hash)
  List<String>? hashNullable;

  @Index(type: IndexType.hash)
  List<String?>? nullableHashNullable;

  @Index(type: IndexType.hashElements)
  List<String> hashes;

  @Index(type: IndexType.hashElements)
  List<String?> nullableHashes;

  @Index(type: IndexType.hashElements)
  List<String>? hashesNullable;

  @Index(type: IndexType.hashElements)
  List<String?>? nullableHashesNullable;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listEquals(values, other.values) &&
          listEquals(nullableValues, other.nullableValues) &&
          listEquals(valuesNullable, other.valuesNullable) &&
          listEquals(nullableValuesNullable, other.nullableValuesNullable) &&
          listEquals(hash, other.hash) &&
          listEquals(nullableHash, other.nullableHash) &&
          listEquals(hashNullable, other.hashNullable) &&
          listEquals(nullableHashNullable, other.nullableHashNullable) &&
          listEquals(hashes, other.hashes) &&
          listEquals(nullableHashes, other.nullableHashes) &&
          listEquals(hashesNullable, other.hashesNullable) &&
          listEquals(nullableHashesNullable, other.nullableHashesNullable);

  @override
  String toString() {
    return '''StringModel{id: $id, values: $values, nullableValues: $nullableValues, valuesNullable: $valuesNullable, nullableValuesNullable: $nullableValuesNullable, hash: $hash, nullableHash: $nullableHash, hashNullable: $hashNullable, nullableHashNullable: $nullableHashNullable, hashes: $hashes, nullableHashes: $nullableHashes, hashesNullable: $hashesNullable, nullableHashesNullable: $nullableHashesNullable}''';
  }
}

void main() {
  group('Where String list', () {
    late Isar isar;

    late StringModel obj1;
    late StringModel obj2;
    late StringModel obj3;
    late StringModel obj4;
    late StringModel obj5;
    late StringModel obj6;

    setUp(() async {
      isar = await openTempIsar([StringModelSchema]);

      obj1 = StringModel(
        values: ['strings 1', 'strings 2', 'strings 3'],
        nullableValues: ['nullable strings 1', null, 'nullable strings 3'],
        valuesNullable: ['strings nullable 1'],
        nullableValuesNullable: ['nullable strings nullable 1', null, null],
      );
      obj2 = StringModel(
        values: ['strings 2', 'strings 4'],
        nullableValues: [
          'nullable strings 2',
          'nullable strings 3',
          'nullable strings 3',
        ],
        valuesNullable: null,
        nullableValuesNullable: null,
      );
      obj3 = StringModel(
        values: [],
        nullableValues: [],
        valuesNullable: [],
        nullableValuesNullable: [],
      );
      obj4 = StringModel(
        values: ['strings 1', 'strings 5', 'strings 6'],
        nullableValues: ['nullable strings 4', 'nullable strings 5'],
        valuesNullable: [
          'strings nullable 4',
          'strings nullable 5',
          'strings nullable 6',
        ],
        nullableValuesNullable: [null, null, null],
      );
      obj5 = StringModel(
        values: [
          'strings 3',
          'strings 4',
          'strings 5',
          'strings 6',
          'strings 7',
        ],
        nullableValues: [
          null,
          'nullable strings 3',
          'nullable strings 4',
          'nullable strings 5',
          'nullable strings 6',
        ],
        valuesNullable: ['strings nullable 1'],
        nullableValuesNullable: null,
      );
      obj6 = StringModel(
        values: [''],
        nullableValues: [
          '',
          'nullable strings 2',
          'nullable strings 5',
          'nullable strings 6',
        ],
        valuesNullable: ['strings nullable 4', 'strings nullable 5', ''],
        nullableValuesNullable: [
          null,
          '',
          'nullable strings nullable 3',
          'nullable strings nullable 5',
        ],
      );

      await isar.tWriteTxn(
        () => isar.stringModels.tPutAll([obj1, obj2, obj3, obj4, obj5, obj6]),
      );
    });

    isarTest('.elementEqualTo()', () async {
      await qEqualSet(
        isar.stringModels.where().valuesElementEqualTo('strings 1'),
        [obj1, obj4],
      );
      await qEqualSet(
        isar.stringModels.where().valuesElementEqualTo('strings 2'),
        [obj1, obj2],
      );
      await qEqualSet(
        isar.stringModels.where().valuesElementEqualTo('strings 3'),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.stringModels.where().valuesElementEqualTo('strings 4'),
        [obj2, obj5],
      );
      await qEqualSet(
        isar.stringModels.where().valuesElementEqualTo('strings 5'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.where().valuesElementEqualTo('strings 6'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.where().valuesElementEqualTo('strings 7'),
        [obj5],
      );
      await qEqualSet(
        isar.stringModels.where().valuesElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesElementEqualTo('nullable strings 1'),
        [obj1],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesElementEqualTo('nullable strings 2'),
        [obj2, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesElementEqualTo('nullable strings 3'),
        [obj1, obj2, obj5],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesElementEqualTo('nullable strings 4'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesElementEqualTo('nullable strings 5'),
        [obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesElementEqualTo('nullable strings 6'),
        [obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.where().nullableValuesElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .valuesNullableElementEqualTo('strings nullable 1'),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .valuesNullableElementEqualTo('strings nullable 4'),
        [obj4, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .valuesNullableElementEqualTo('strings nullable 5'),
        [obj4, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .valuesNullableElementEqualTo('strings nullable 6'),
        [obj4],
      );
      await qEqualSet(
        isar.stringModels.where().valuesNullableElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.where().nullableValuesNullableElementEqualTo(
              'nullable strings nullable 1',
            ),
        [obj1],
      );
      await qEqualSet(
        isar.stringModels.where().nullableValuesNullableElementEqualTo(
              'nullable strings nullable 3',
            ),
        [obj6],
      );
      await qEqualSet(
        isar.stringModels.where().nullableValuesNullableElementEqualTo(
              'nullable strings nullable 5',
            ),
        [obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesNullableElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.where().hashesElementEqualTo('strings 1'),
        [obj1, obj4],
      );
      await qEqualSet(
        isar.stringModels.where().hashesElementEqualTo('strings 2'),
        [obj1, obj2],
      );
      await qEqualSet(
        isar.stringModels.where().hashesElementEqualTo('strings 3'),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.stringModels.where().hashesElementEqualTo('strings 4'),
        [obj2, obj5],
      );
      await qEqualSet(
        isar.stringModels.where().hashesElementEqualTo('strings 5'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.where().hashesElementEqualTo('strings 6'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.where().hashesElementEqualTo('strings 7'),
        [obj5],
      );
      await qEqualSet(
        isar.stringModels.where().hashesElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesElementEqualTo('nullable strings 1'),
        [obj1],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesElementEqualTo('nullable strings 2'),
        [obj2, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesElementEqualTo('nullable strings 3'),
        [obj1, obj2, obj5],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesElementEqualTo('nullable strings 4'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesElementEqualTo('nullable strings 5'),
        [obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesElementEqualTo('nullable strings 6'),
        [obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.where().nullableHashesElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .hashesNullableElementEqualTo('strings nullable 1'),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .hashesNullableElementEqualTo('strings nullable 4'),
        [obj4, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .hashesNullableElementEqualTo('strings nullable 5'),
        [obj4, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .hashesNullableElementEqualTo('strings nullable 6'),
        [obj4],
      );
      await qEqualSet(
        isar.stringModels.where().hashesNullableElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.where().nullableHashesNullableElementEqualTo(
              'nullable strings nullable 1',
            ),
        [obj1],
      );
      await qEqualSet(
        isar.stringModels.where().nullableHashesNullableElementEqualTo(
              'nullable strings nullable 3',
            ),
        [obj6],
      );
      await qEqualSet(
        isar.stringModels.where().nullableHashesNullableElementEqualTo(
              'nullable strings nullable 5',
            ),
        [obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesNullableElementEqualTo('non existing'),
        [],
      );
    });

    isarTest('.elementStartWith()', () async {
      await qEqualSet(
        isar.stringModels.where().valuesElementStartsWith('strings'),
        [obj1, obj2, obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.where().valuesElementStartsWith('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.where().nullableValuesElementStartsWith('nullable'),
        [obj1, obj2, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesElementStartsWith('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.where().valuesNullableElementStartsWith('strings'),
        [obj1, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.where().valuesNullableElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesNullableElementStartsWith('nullable'),
        [obj1, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesNullableElementStartsWith('non existing'),
        [],
      );

      // FIXME: hashElements indexes not working properly with
      // `elementStartsWith`.
      // Should the method be generated? I don't think `startsWith` is suppose
      // to work on a hashed value.
      // Does not return values when supposed to, and returns values when not
      // supposed to
      await qEqualSet(
        isar.stringModels.where().hashesElementStartsWith('strings'),
        [obj1, obj2, obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.where().hashesElementStartsWith('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.where().nullableHashesElementStartsWith('nullable'),
        [obj1, obj2, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesElementStartsWith('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.where().hashesNullableElementStartsWith('strings'),
        [obj1, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.where().hashesNullableElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesNullableElementStartsWith('nullable'),
        [obj1, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesNullableElementStartsWith('non existing'),
        [],
      );
    });

    isarTest('.elementIsNull()', () async {
      // FIXME: method `elementIsNull()` not generated on `List<String?>`
      // but are generated on `List<String>?`, which shouldn't, since element
      // is not nullable
      // await qEqualSet(
      //   isar.stringModels.where().nullableValuesElementIsNull(),
      //   [obj1, obj5],
      // );

      await qEqualSet(
        isar.stringModels.where().nullableValuesNullableElementIsNull(),
        [obj1, obj4, obj6],
      );

      // FIXME: method `elementIsNull()` not generated on `List<String?>`
      // but are generated on `List<String>?`, which shouldn't, since element
      // is not nullable
      // await qEqualSet(
      //   isar.stringModels.where().nullableHashesElementIsNull(),
      //   [obj1, obj5],
      // );

      await qEqualSet(
        isar.stringModels.where().nullableHashesNullableElementIsNull(),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.elementIsNotNull()', () async {
      // FIXME: method `elementIsNotNull()` not generated on `List<String?>`
      // but are generated on `List<String>?`, which shouldn't, since element
      // is not nullable
      // await qEqualSet(
      //   isar.stringModels.filter().nullableValuesElementIsNotNull(),
      //   [obj1, obj2, obj4, obj5, obj6],
      // );

      await qEqualSet(
        isar.stringModels.where().nullableValuesNullableElementIsNotNull(),
        [obj1, obj6],
      );

      // FIXME: method `elementIsNotNull()` not generated on `List<String?>`
      // but are generated on `List<String>?`, which shouldn't, since element
      // is not nullable
      // await qEqualSet(
      //   isar.stringModels.filter().nullableHashesElementIsNotNull(),
      //   [obj1, obj2, obj4, obj5, obj6],
      // );

      await qEqualSet(
        isar.stringModels.where().nullableHashesNullableElementIsNotNull(),
        [obj1, obj6],
      );
    });

    isarTest('.elementGreaterThan()', () async {
      await qEqualSet(
        isar.stringModels.where().valuesElementGreaterThan('strings 3'),
        [obj2, obj4, obj5],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesElementGreaterThan('nullable strings 3'),
        [obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .valuesNullableElementGreaterThan('strings nullable 3'),
        [obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().nullableValuesNullableElementGreaterThan(
              'nullable strings nullable 3',
            ),
        [obj6],
      );

      // FIXME: hashElements indexes not working properly with
      // `elementGreaterThan`.
      // Should the method be generated?
      await qEqualSet(
        isar.stringModels.where().hashesElementGreaterThan('strings 3'),
        [obj2, obj4, obj5],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesElementGreaterThan('nullable strings 3'),
        [obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .hashesNullableElementGreaterThan('strings nullable 3'),
        [obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().nullableHashesNullableElementGreaterThan(
              'nullable strings nullable 3',
            ),
        [obj6],
      );
    });

    isarTest('.elementLessThan()', () async {
      await qEqualSet(
        isar.stringModels.where().valuesElementLessThan('strings 3'),
        [obj1, obj2, obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .nullableValuesElementLessThan('nullable strings 3'),
        [obj1, obj2, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .valuesNullableElementLessThan('strings nullable 3'),
        [obj1, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().nullableValuesNullableElementLessThan(
              'nullable strings nullable 3',
            ),
        [obj1, obj4, obj6],
      );

      // FIXME: hashElements indexes not working properly with
      // `elementLessThan`.
      // Should the method be generated?
      await qEqualSet(
        isar.stringModels.where().hashesElementLessThan('strings 3'),
        [obj1, obj2, obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .nullableHashesElementLessThan('nullable strings 3'),
        [obj1, obj2, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels
            .where()
            .hashesNullableElementLessThan('strings nullable 3'),
        [obj1, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().nullableHashesNullableElementLessThan(
              'nullable strings nullable 3',
            ),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.elementBetween()', () async {
      await qEqualSet(
        isar.stringModels
            .where()
            .valuesElementBetween('strings 2', 'strings 4'),
        [obj1, obj2, obj5],
      );

      await qEqualSet(
        isar.stringModels.where().nullableValuesElementBetween(
              'nullable strings 2',
              'nullable strings 4',
            ),
        [obj1, obj2, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().valuesNullableElementBetween(
              'strings nullable 2',
              'strings nullable 4',
            ),
        [obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().nullableValuesNullableElementBetween(
              'nullable strings nullable 2',
              'nullable strings nullable 4',
            ),
        [obj6],
      );

      // FIXME: hashElements indexes not working properly with
      // `elementBetween`.
      // Should the method be generated?
      await qEqualSet(
        isar.stringModels
            .where()
            .hashesElementBetween('strings 2', 'strings 4'),
        [obj1, obj2, obj5],
      );

      await qEqualSet(
        isar.stringModels.where().nullableHashesElementBetween(
              'nullable strings 2',
              'nullable strings 4',
            ),
        [obj1, obj2, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().hashesNullableElementBetween(
              'strings nullable 2',
              'strings nullable 4',
            ),
        [obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().nullableHashesNullableElementBetween(
              'nullable strings nullable 2',
              'nullable strings nullable 4',
            ),
        [obj6],
      );
    });

    // TODO(Jtplouffe): `.elementIsEmpty()` not yet implemented on indexes
    /*
    isarTest('.elementIsEmpty()', () async {
      await qEqualSet(
        isar.stringModels.where().valuesElementIsEmpty(),
        [obj6],
      );

      await qEqualSet(
        isar.stringModels.where().nullableValuesElementIsEmpty(),
        [obj6],
      );

      await qEqualSet(
        isar.stringModels.where().valuesNullableElementIsEmpty(),
        [obj6],
      );

      await qEqualSet(
        isar.stringModels.where().nullableValuesNullableElementIsEmpty(),
        [obj6],
      );
    });
    */

    // TODO(Jtplouffe): `.elementIsEmpty()` not yet implemented on indexes
    /*
    isarTest('.elementIsNotEmpty()', () async {
      await qEqualSet(
        isar.stringModels.where().valuesElementIsNotEmpty(),
        [obj1, obj2, obj4, obj5],
      );

      await qEqualSet(
        isar.stringModels.where().nullableValuesElementIsNotEmpty(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().valuesNullableElementIsNotEmpty(),
        [obj1, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().nullableValuesNullableElementIsNotEmpty(),
        [obj1, obj6],
      );
    });
    */

    // FIXME: Should `.lengthXXX()` / `.isEmpty` be implemented on `values`
    //  and `hashElements` indexes?

    isarTest('.isNull()', () async {
      // FIXME: `.isNull()` is not generated on type List<String>?
      // await qEqualSet(
      //   isar.stringModels.where().valuesNullableIsNull(),
      //   [obj2],
      // );

      // FIXME: `.isNull()` is not generated on type List<String?>?
      // await qEqualSet(
      //   isar.stringModels.where().nullableValuesNullableIsNull(),
      //   [obj2, obj5],
      // );

      // FIXME: empty array also returned (obj2 & obj3 instead of only obj2)
      await qEqualSet(
        isar.stringModels.where().hashNullableIsNull(),
        [obj2],
      );

      await qEqualSet(
        isar.stringModels.where().nullableHashNullableIsNull(),
        [obj2, obj5],
      );

      // FIXME: `.isNull()` is not generated on type List<String>?
      // await qEqualSet(
      //   isar.stringModels.where().hashesNullableIsNull(),
      //   [obj2],
      // );

      // FIXME: `.isNull()` is not generated on type List<String?>?
      // await qEqualSet(
      //   isar.stringModels.where().nullableHashesNullableIsNull(),
      //   [obj2, obj5],
      // );
    });

    isarTest('.isNotNull()', () async {
      // FIXME: `.isNotNull()` is not generated on type List<String>?
      // await qEqualSet(
      //   isar.stringModels.where().valuesNullableIsNotNull(),
      //   [obj1, obj3, obj4, obj5, obj6],
      // );

      // FIXME: `.isNotNull()` is not generated on type List<String?>?
      // await qEqualSet(
      //   isar.stringModels.where().nullableValuesNullableIsN(),
      //   [obj1, obj3, obj4, obj6],
      // );

      // FIXME: Returning wrong values
      await qEqualSet(
        isar.stringModels.where().hashNullableIsNotNull(),
        [obj1, obj3, obj4, obj5, obj6],
      );

      // FIXME: Returning wrong values
      await qEqualSet(
        isar.stringModels.where().nullableHashNullableIsNotNull(),
        [obj1, obj3, obj4, obj6],
      );

      // FIXME: `.isNotNull()` is not generated on type List<String>?
      // await qEqualSet(
      //   isar.stringModels.where().hashesNullableIsNotNull(),
      //   [obj1, obj3, obj4, obj5, obj6],
      // );

      // FIXME: `.isNotNull()` is not generated on type List<String?>?
      // await qEqualSet(
      //   isar.stringModels.where().nullableHashesNullableIsNotNull(),
      //   [obj1, obj3, obj4, obj6],
      // );
    });
  });
}
