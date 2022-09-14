import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_string_list_test.g.dart';

@collection
class StringModel {
  StringModel({
    required this.strings,
    required this.nullableStrings,
    required this.stringsNullable,
    required this.nullableStringsNullable,
  });

  Id id = Isar.autoIncrement;

  List<String> strings;
  List<String?> nullableStrings;
  List<String>? stringsNullable;
  List<String?>? nullableStringsNullable;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listEquals(strings, other.strings) &&
          listEquals(nullableStrings, other.nullableStrings) &&
          listEquals(stringsNullable, other.stringsNullable) &&
          listEquals(nullableStringsNullable, other.nullableStringsNullable);

  @override
  String toString() {
    return '''StringModel{id: $id, strings: $strings, nullableStrings: $nullableStrings, stringsNullable: $stringsNullable, nullableStringsNullable: $nullableStringsNullable}''';
  }
}

void main() {
  group('String list filter', () {
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
        strings: ['strings 1', 'strings 2', 'strings 3'],
        nullableStrings: ['nullable strings 1', null, 'nullable strings 3'],
        stringsNullable: ['strings nullable 1'],
        nullableStringsNullable: ['nullable strings nullable 1', null, null],
      );
      obj2 = StringModel(
        strings: ['strings 2', 'strings 4'],
        nullableStrings: [
          'nullable strings 2',
          'nullable strings 3',
          'nullable strings 3',
        ],
        stringsNullable: null,
        nullableStringsNullable: null,
      );
      obj3 = StringModel(
        strings: [],
        nullableStrings: [],
        stringsNullable: [],
        nullableStringsNullable: [],
      );
      obj4 = StringModel(
        strings: ['strings 1', 'strings 5', 'strings 6'],
        nullableStrings: ['nullable strings 4', 'nullable strings 5'],
        stringsNullable: [
          'strings nullable 4',
          'strings nullable 5',
          'strings nullable 6',
        ],
        nullableStringsNullable: [null, null, null],
      );
      obj5 = StringModel(
        strings: [
          'strings 3',
          'strings 4',
          'strings 5',
          'strings 6',
          'strings 7',
        ],
        nullableStrings: [
          null,
          'nullable strings 3',
          'nullable strings 4',
          'nullable strings 5',
          'nullable strings 6',
        ],
        stringsNullable: ['strings nullable 1'],
        nullableStringsNullable: null,
      );
      obj6 = StringModel(
        strings: [''],
        nullableStrings: [
          '',
          'nullable strings 2',
          'nullable strings 5',
          'nullable strings 6',
        ],
        stringsNullable: ['strings nullable 4', 'strings nullable 5', ''],
        nullableStringsNullable: [
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
        isar.stringModels.filter().stringsElementEqualTo('strings 1'),
        [obj1, obj4],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEqualTo('strings 2'),
        [obj1, obj2],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEqualTo('strings 3'),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEqualTo('strings 4'),
        [obj2, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEqualTo('strings 5'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEqualTo('strings 6'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEqualTo('strings 7'),
        [obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementEqualTo('nullable strings 1'),
        [obj1],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementEqualTo('nullable strings 2'),
        [obj2, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementEqualTo('nullable strings 3'),
        [obj1, obj2, obj5],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementEqualTo('nullable strings 4'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementEqualTo('nullable strings 5'),
        [obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementEqualTo('nullable strings 6'),
        [obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementEqualTo('strings nullable 1'),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementEqualTo('strings nullable 4'),
        [obj4, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementEqualTo('strings nullable 5'),
        [obj4, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementEqualTo('strings nullable 6'),
        [obj4],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementEqualTo(
              'nullable strings nullable 1',
            ),
        [obj1],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementEqualTo(
              'nullable strings nullable 3',
            ),
        [obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementEqualTo(
              'nullable strings nullable 5',
            ),
        [obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsNullableElementEqualTo('non existing'),
        [],
      );
    });

    isarTest('.elementStartWith()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsElementStartsWith('strings'),
        [obj1, obj2, obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementStartsWith('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementStartsWith('nullable'),
        [obj1, obj2, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementStartsWith('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableElementStartsWith('strings'),
        [obj1, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementEqualTo('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsNullableElementStartsWith('nullable'),
        [obj1, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsNullableElementStartsWith('non existing'),
        [],
      );
    });

    isarTest('.elementEndsWith()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsElementEndsWith('1'),
        [obj1, obj4],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEndsWith('2'),
        [obj1, obj2],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEndsWith('3'),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEndsWith('4'),
        [obj2, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEndsWith('5'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEndsWith('6'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEndsWith('7'),
        [obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementEndsWith('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementEndsWith('1'),
        [obj1],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementEndsWith('2'),
        [obj2, obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementEndsWith('3'),
        [obj1, obj2, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementEndsWith('4'),
        [obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementEndsWith('5'),
        [obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementEndsWith('6'),
        [obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementEndsWith('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableElementEndsWith('1'),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsNullableElementEndsWith('4'),
        [obj4, obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsNullableElementEndsWith('5'),
        [obj4, obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsNullableElementEndsWith('6'),
        [obj4],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementEndsWith('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementEndsWith('1'),
        [obj1],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementEndsWith('3'),
        [obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementEndsWith('5'),
        [obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsNullableElementEndsWith('non existing'),
        [],
      );
    });

    isarTest('.elementContains()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsElementContains('ings'),
        [obj1, obj2, obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementContains('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementContains('ings'),
        [obj1, obj2, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementContains('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableElementContains('ings'),
        [obj1, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementContains('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsNullableElementContains('ings'),
        [obj1, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsNullableElementContains('non existing'),
        [],
      );
    });

    isarTestVm('.elementMatches() VM', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsElementMatches('?????????'),
        [obj1, obj2, obj4, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsElementMatches('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementMatches('??????????????????'),
        [obj1, obj2, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementMatches('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementMatches('??????????????????'),
        [obj1, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementMatches('non existing'),
        [],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementMatches(
              '???????????????????????????',
            ),
        [obj1, obj6],
      );
      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsNullableElementMatches('non existing'),
        [],
      );
    });

    isarTestWeb('.elementMatches() WEB', () async {
      expect(
        await isar.stringModels
            .filter()
            .stringsElementMatches('?????????')
            .tFindAll(),
        anyOf(throwsUnimplementedError, throwsUnsupportedError),
      );

      expect(
        await isar.stringModels
            .filter()
            .nullableStringsElementMatches('??????????????????')
            .tFindAll(),
        anyOf(throwsUnimplementedError, throwsUnsupportedError),
      );

      expect(
        await isar.stringModels
            .filter()
            .stringsNullableElementMatches('??????????????????')
            .tFindAll(),
        anyOf(throwsUnimplementedError, throwsUnsupportedError),
      );

      expect(
        await isar.stringModels
            .filter()
            .nullableStringsNullableElementContains(
              '???????????????????????????',
            )
            .tFindAll(),
        anyOf(throwsUnimplementedError, throwsUnsupportedError),
      );
    });

    isarTest('.elementIsNull()', () async {
      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementIsNull(),
        [obj1, obj5],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementIsNull(),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.elementIsNotNull()', () async {
      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementIsNotNull(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementIsNotNull(),
        [obj1, obj6],
      );
    });

    isarTest('.elementGreaterThan()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsElementGreaterThan('strings 3'),
        [obj2, obj4, obj5],
      );

      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementGreaterThan('nullable strings 3'),
        [obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementGreaterThan('strings nullable 3'),
        [obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementGreaterThan(
              'nullable strings nullable 3',
            ),
        [obj6],
      );
    });

    // FIXME: .elementLessThan() doesn't seem to be working
    // returns either no elements or null elements
    // also works fine in the index test
    isarTest('.elementLessThan()', () async {
      /*await qEqualSet(
        isar.stringModels.filter().stringsElementLessThan('strings 3'),
        [obj1, obj2, obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels
            .filter()
            .nullableStringsElementLessThan('nullable strings 3'),
        [obj1, obj2, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsNullableElementLessThan('strings nullable 3'),
        [obj1, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementLessThan(
              'nullable strings nullable 3',
            ),
        [obj1, obj4, obj6],
      );*/
    });

    isarTest('.elementBetween()', () async {
      await qEqualSet(
        isar.stringModels
            .filter()
            .stringsElementBetween('strings 2', 'strings 4'),
        [obj1, obj2, obj5],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementBetween(
              'nullable strings 2',
              'nullable strings 4',
            ),
        [obj1, obj2, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableElementBetween(
              'strings nullable 2',
              'strings nullable 4',
            ),
        [obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementBetween(
              'nullable strings nullable 2',
              'nullable strings nullable 4',
            ),
        [obj6],
      );
    });

    isarTest('.elementIsEmpty()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsElementIsEmpty(),
        [obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementIsEmpty(),
        [obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableElementIsEmpty(),
        [obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementIsEmpty(),
        [obj6],
      );
    });

    isarTest('.elementIsNotEmpty()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsElementIsNotEmpty(),
        [obj1, obj2, obj4, obj5],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsElementIsNotEmpty(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableElementIsNotEmpty(),
        [obj1, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableElementIsNotEmpty(),
        [obj1, obj6],
      );
    });

    isarTest('.lengthEqualTo()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsLengthEqualTo(0),
        [obj3],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsLengthEqualTo(1),
        [obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsLengthEqualTo(2),
        [obj2],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsLengthEqualTo(3),
        [obj1, obj4],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsLengthEqualTo(5),
        [obj5],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsLengthEqualTo(0),
        [obj3],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsLengthEqualTo(2),
        [obj4],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsLengthEqualTo(3),
        [obj1, obj2],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsLengthEqualTo(4),
        [obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsLengthEqualTo(5),
        [obj5],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableLengthEqualTo(0),
        [obj3],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsNullableLengthEqualTo(1),
        [obj1, obj5],
      );
      await qEqualSet(
        isar.stringModels.filter().stringsNullableLengthEqualTo(3),
        [obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableLengthEqualTo(0),
        [obj3],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableLengthEqualTo(3),
        [obj1, obj4],
      );
      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableLengthEqualTo(4),
        [obj6],
      );
    });

    isarTest('.lengthGreaterThan()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsLengthGreaterThan(2),
        [obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsLengthGreaterThan(2),
        [obj1, obj2, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableLengthGreaterThan(2),
        [obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableLengthGreaterThan(2),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.lengthLessThan()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsLengthLessThan(2),
        [obj3, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsLengthLessThan(2),
        [obj3],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableLengthLessThan(2),
        [obj1, obj3, obj5],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableLengthLessThan(2),
        [obj3],
      );
    });

    isarTest('.lengthBetween()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsLengthBetween(2, 4),
        [obj1, obj2, obj4],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsLengthBetween(2, 4),
        [obj1, obj2, obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableLengthBetween(2, 4),
        [obj4, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableLengthBetween(2, 4),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.isEmpty()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsIsEmpty(),
        [obj3],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsIsEmpty(),
        [obj3],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableIsEmpty(),
        [obj3],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableIsEmpty(),
        [obj3],
      );
    });

    isarTest('.isNotEmpty()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsIsNotEmpty(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsIsNotEmpty(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().stringsNullableIsNotEmpty(),
        [obj1, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableIsNotEmpty(),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.isNull()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsNullableIsNull(),
        [obj2],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableIsNull(),
        [obj2, obj5],
      );
    });

    isarTest('.isNotNull()', () async {
      await qEqualSet(
        isar.stringModels.filter().stringsNullableIsNotNull(),
        [obj1, obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().nullableStringsNullableIsNotNull(),
        [obj1, obj3, obj4, obj6],
      );
    });
  });
}
