/*import 'dart:math';

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

  int id = Random().nextInt(99999);

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

    setUp(() {
      isar = openTempIsar([StringModelSchema]);

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

      isar.tWriteTxn(
        () => isar.stringModels.tPutAll([obj1, obj2, obj3, obj4, obj5, obj6]),
      );
    });

    isarTest('.elementEqualTo()', () {
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 1'),
        [obj1, obj4],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 2'),
        [obj1, obj2],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 3'),
        [obj1, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 4'),
        [obj2, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 5'),
        [obj4, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 6'),
        [obj4, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 7'),
        [obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('non existing'),
        [],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 1'),
        [obj1],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 2'),
        [obj2, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 3'),
        [obj1, obj2, obj5],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 4'),
        [obj4, obj5],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 5'),
        [obj4, obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 6'),
        [obj5, obj6],
      );
      expect(
        isar.stringModels.where().nullableStringsElementEqualTo('non existing'),
        [],
      );

      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEqualTo('strings nullable 1'),
        [obj1, obj5],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEqualTo('strings nullable 4'),
        [obj4, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEqualTo('strings nullable 5'),
        [obj4, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEqualTo('strings nullable 6'),
        [obj4],
      );
      expect(
        isar.stringModels.where().stringsNullableElementEqualTo('non existing'),
        [],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableElementEqualTo(
              'nullable strings nullable 1',
            ),
        [obj1],
      );
      expect(
        isar.stringModels.where().nullableStringsNullableElementEqualTo(
              'nullable strings nullable 3',
            ),
        [obj6],
      );
      expect(
        isar.stringModels.where().nullableStringsNullableElementEqualTo(
              'nullable strings nullable 5',
            ),
        [obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementEqualTo('non existing'),
        [],
      );
    });

    isarTest('.elementStartWith()', () {
      expect(
        isar.stringModels.where().stringsElementStartsWith('strings'),
        [obj1, obj2, obj4, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementStartsWith('non existing'),
        [],
      );

      expect(
        isar.stringModels.where().nullableStringsElementStartsWith('nullable'),
        [obj1, obj2, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementStartsWith('non existing'),
        [],
      );

      expect(
        isar.stringModels.where().stringsNullableElementStartsWith('strings'),
        [obj1, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels.where().stringsNullableElementEqualTo('non existing'),
        [],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementStartsWith('nullable'),
        [obj1, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementStartsWith('non existing'),
        [],
      );
    });

    isarTest('.elementEndsWith()', () {
      expect(
        isar.stringModels.where().stringsElementEndsWith('1'),
        [obj1, obj4],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('2'),
        [obj1, obj2],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('3'),
        [obj1, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('4'),
        [obj2, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('5'),
        [obj4, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('6'),
        [obj4, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('7'),
        [obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('non existing'),
        [],
      );

      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('1'),
        [obj1],
      );
      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('2'),
        [obj2, obj6],
      );
      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('3'),
        [obj1, obj2, obj5],
      );
      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('4'),
        [obj4, obj5],
      );
      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('5'),
        [obj4, obj5, obj6],
      );
      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('6'),
        [obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEndsWith('non existing'),
        [],
      );

      expect(
        isar.stringModels.where().stringsNullableElementEndsWith('1'),
        [obj1, obj5],
      );
      expect(
        isar.stringModels.where().stringsNullableElementEndsWith('4'),
        [obj4, obj6],
      );
      expect(
        isar.stringModels.where().stringsNullableElementEndsWith('5'),
        [obj4, obj6],
      );
      expect(
        isar.stringModels.where().stringsNullableElementEndsWith('6'),
        [obj4],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEndsWith('non existing'),
        [],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableElementEndsWith('1'),
        [obj1],
      );
      expect(
        isar.stringModels.where().nullableStringsNullableElementEndsWith('3'),
        [obj6],
      );
      expect(
        isar.stringModels.where().nullableStringsNullableElementEndsWith('5'),
        [obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementEndsWith('non existing'),
        [],
      );
    });

    isarTest('.elementContains()', () {
      expect(
        isar.stringModels.where().stringsElementContains('ings'),
        [obj1, obj2, obj4, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementContains('non existing'),
        [],
      );

      expect(
        isar.stringModels.where().nullableStringsElementContains('ings'),
        [obj1, obj2, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementContains('non existing'),
        [],
      );

      expect(
        isar.stringModels.where().stringsNullableElementContains('ings'),
        [obj1, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementContains('non existing'),
        [],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementContains('ings'),
        [obj1, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementContains('non existing'),
        [],
      );
    });

    isarTestVm('.elementMatches() VM', () {
      expect(
        isar.stringModels.where().stringsElementMatches('?????????'),
        [obj1, obj2, obj4, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementMatches('non existing'),
        [],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsElementMatches('??????????????????'),
        [obj1, obj2, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels.where().nullableStringsElementMatches('non existing'),
        [],
      );

      expect(
        isar.stringModels
            .where()
            .stringsNullableElementMatches('??????????????????'),
        [obj1, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels.where().stringsNullableElementMatches('non existing'),
        [],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableElementMatches(
              '???????????????????????????',
            ),
        [obj1, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementMatches('non existing'),
        [],
      );
    });

    isarTestWeb('.elementMatches() WEB', () {
      expect(
        isar.stringModels.where().stringsElementMatches('?????????').tFindAll(),
        anyOf(throwsUnimplementedError, throwsUnsupportedError),
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsElementMatches('??????????????????')
            .tFindAll(),
        anyOf(throwsUnimplementedError, throwsUnsupportedError),
      );

      expect(
        isar.stringModels
            .where()
            .stringsNullableElementMatches('??????????????????')
            .tFindAll(),
        anyOf(throwsUnimplementedError, throwsUnsupportedError),
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementContains(
              '???????????????????????????',
            )
            .tFindAll(),
        anyOf(throwsUnimplementedError, throwsUnsupportedError),
      );
    });

    isarTest('.elementIsNull()', () {
      expect(
        isar.stringModels.where().nullableStringsElementIsNull(),
        [obj1, obj5],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableElementIsNull(),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.elementIsNotNull()', () {
      expect(
        isar.stringModels.where().nullableStringsElementIsNotNull(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableElementIsNotNull(),
        [obj1, obj6],
      );
    });

    isarTest('.elementGreaterThan()', () {
      expect(
        isar.stringModels.where().stringsElementGreaterThan('strings 3'),
        [obj2, obj4, obj5],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsElementGreaterThan('nullable strings 3'),
        [obj4, obj5, obj6],
      );

      expect(
        isar.stringModels
            .where()
            .stringsNullableElementGreaterThan('strings nullable 3'),
        [obj4, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableElementGreaterThan(
              'nullable strings nullable 3',
            ),
        [obj6],
      );
    });

    // FIXME: .elementLessThan() doesn't seem to be working
    // returns either no elements or null elements
    // also works fine in the index test
    isarTest('.elementLessThan()', () {
      /* expect(
        isar.stringModels.where().stringsElementLessThan('strings 3'),
        [obj1, obj2, obj4, obj6],
      );

       expect(
        isar.stringModels
            .where()
            .nullableStringsElementLessThan('nullable strings 3'),
        [obj1, obj2, obj5, obj6],
      );

       expect(
        isar.stringModels
            .where()
            .stringsNullableElementLessThan('strings nullable 3'),
        [obj1, obj5, obj6],
      );

       expect(
        isar.stringModels.where().nullableStringsNullableElementLessThan(
              'nullable strings nullable 3',
            ),
        [obj1, obj4, obj6],
      );*/
    });

    isarTest('.elementBetween()', () {
      expect(
        isar.stringModels
            .where()
            .stringsElementBetween('strings 2', 'strings 4'),
        [obj1, obj2, obj5],
      );

      expect(
        isar.stringModels.where().nullableStringsElementBetween(
              'nullable strings 2',
              'nullable strings 4',
            ),
        [obj1, obj2, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().stringsNullableElementBetween(
              'strings nullable 2',
              'strings nullable 4',
            ),
        [obj4, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableElementBetween(
              'nullable strings nullable 2',
              'nullable strings nullable 4',
            ),
        [obj6],
      );
    });

    isarTest('.elementIsEmpty()', () {
      expect(
        isar.stringModels.where().stringsElementIsEmpty(),
        [obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsElementIsEmpty(),
        [obj6],
      );

      expect(
        isar.stringModels.where().stringsNullableElementIsEmpty(),
        [obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableElementIsEmpty(),
        [obj6],
      );
    });

    isarTest('.elementIsNotEmpty()', () {
      expect(
        isar.stringModels.where().stringsElementIsNotEmpty(),
        [obj1, obj2, obj4, obj5],
      );

      expect(
        isar.stringModels.where().nullableStringsElementIsNotEmpty(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().stringsNullableElementIsNotEmpty(),
        [obj1, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableElementIsNotEmpty(),
        [obj1, obj6],
      );
    });

    isarTest('.lengthEqualTo()', () {
      expect(
        isar.stringModels.where().stringsLengthEqualTo(0),
        [obj3],
      );
      expect(
        isar.stringModels.where().stringsLengthEqualTo(1),
        [obj6],
      );
      expect(
        isar.stringModels.where().stringsLengthEqualTo(2),
        [obj2],
      );
      expect(
        isar.stringModels.where().stringsLengthEqualTo(3),
        [obj1, obj4],
      );
      expect(
        isar.stringModels.where().stringsLengthEqualTo(5),
        [obj5],
      );

      expect(
        isar.stringModels.where().nullableStringsLengthEqualTo(0),
        [obj3],
      );
      expect(
        isar.stringModels.where().nullableStringsLengthEqualTo(2),
        [obj4],
      );
      expect(
        isar.stringModels.where().nullableStringsLengthEqualTo(3),
        [obj1, obj2],
      );
      expect(
        isar.stringModels.where().nullableStringsLengthEqualTo(4),
        [obj6],
      );
      expect(
        isar.stringModels.where().nullableStringsLengthEqualTo(5),
        [obj5],
      );

      expect(
        isar.stringModels.where().stringsNullableLengthEqualTo(0),
        [obj3],
      );
      expect(
        isar.stringModels.where().stringsNullableLengthEqualTo(1),
        [obj1, obj5],
      );
      expect(
        isar.stringModels.where().stringsNullableLengthEqualTo(3),
        [obj4, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableLengthEqualTo(0),
        [obj3],
      );
      expect(
        isar.stringModels.where().nullableStringsNullableLengthEqualTo(3),
        [obj1, obj4],
      );
      expect(
        isar.stringModels.where().nullableStringsNullableLengthEqualTo(4),
        [obj6],
      );
    });

    isarTest('.lengthGreaterThan()', () {
      expect(
        isar.stringModels.where().stringsLengthGreaterThan(2),
        [obj1, obj4, obj5],
      );

      expect(
        isar.stringModels.where().nullableStringsLengthGreaterThan(2),
        [obj1, obj2, obj5, obj6],
      );

      expect(
        isar.stringModels.where().stringsNullableLengthGreaterThan(2),
        [obj4, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableLengthGreaterThan(2),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.lengthLessThan()', () {
      expect(
        isar.stringModels.where().stringsLengthLessThan(2),
        [obj3, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsLengthLessThan(2),
        [obj3],
      );

      expect(
        isar.stringModels.where().stringsNullableLengthLessThan(2),
        [obj1, obj3, obj5],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableLengthLessThan(2),
        [obj3],
      );
    });

    isarTest('.lengthBetween()', () {
      expect(
        isar.stringModels.where().stringsLengthBetween(2, 4),
        [obj1, obj2, obj4],
      );

      expect(
        isar.stringModels.where().nullableStringsLengthBetween(2, 4),
        [obj1, obj2, obj4, obj6],
      );

      expect(
        isar.stringModels.where().stringsNullableLengthBetween(2, 4),
        [obj4, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableLengthBetween(2, 4),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.isEmpty()', () {
      expect(
        isar.stringModels.where().stringsIsEmpty(),
        [obj3],
      );

      expect(
        isar.stringModels.where().nullableStringsIsEmpty(),
        [obj3],
      );

      expect(
        isar.stringModels.where().stringsNullableIsEmpty(),
        [obj3],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableIsEmpty(),
        [obj3],
      );
    });

    isarTest('.isNotEmpty()', () {
      expect(
        isar.stringModels.where().stringsIsNotEmpty(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsIsNotEmpty(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().stringsNullableIsNotEmpty(),
        [obj1, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableIsNotEmpty(),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.isNull()', () {
      expect(
        isar.stringModels.where().stringsNullableIsNull(),
        [obj2],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableIsNull(),
        [obj2, obj5],
      );
    });

    isarTest('.isNotNull()', () {
      expect(
        isar.stringModels.where().stringsNullableIsNotNull(),
        [obj1, obj3, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableIsNotNull(),
        [obj1, obj3, obj4, obj6],
      );
    });
  });
}
*/