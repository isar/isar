import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_string_list_test.g.dart';

@collection
class StringModel {
  StringModel({
    required this.id,
    required this.strings,
    required this.nullableStrings,
    required this.stringsNullable,
    required this.nullableStringsNullable,
  });

  final int id;

  final List<String> strings;
  final List<String?> nullableStrings;
  final List<String>? stringsNullable;
  final List<String?>? nullableStringsNullable;

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
        id: 1,
        strings: ['strings 1', 'strings 2', 'strings 3'],
        nullableStrings: ['nullable strings 1', null, 'nullable strings 3'],
        stringsNullable: ['strings nullable 1'],
        nullableStringsNullable: ['nullable strings nullable 1', null, null],
      );
      obj2 = StringModel(
        id: 2,
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
        id: 3,
        strings: [],
        nullableStrings: [],
        stringsNullable: [],
        nullableStringsNullable: [],
      );
      obj4 = StringModel(
        id: 4,
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
        id: 5,
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
        id: 6,
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

      isar.write(
        (isar) =>
            isar.stringModels.putAll([obj1, obj2, obj3, obj4, obj5, obj6]),
      );
    });

    isarTest('.elementEqualTo()', () {
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 1').findAll(),
        [obj1, obj4],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 2').findAll(),
        [obj1, obj2],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 3').findAll(),
        [obj1, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 4').findAll(),
        [obj2, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 5').findAll(),
        [obj4, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 6').findAll(),
        [obj4, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEqualTo('strings 7').findAll(),
        [obj5],
      );
      expect(
        isar.stringModels
            .where()
            .stringsElementEqualTo('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 1')
            .findAll(),
        [obj1],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 2')
            .findAll(),
        [obj2, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 3')
            .findAll(),
        [obj1, obj2, obj5],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 4')
            .findAll(),
        [obj4, obj5],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 5')
            .findAll(),
        [obj4, obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('nullable strings 6')
            .findAll(),
        [obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEqualTo('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEqualTo('strings nullable 1')
            .findAll(),
        [obj1, obj5],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEqualTo('strings nullable 4')
            .findAll(),
        [obj4, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEqualTo('strings nullable 5')
            .findAll(),
        [obj4, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEqualTo('strings nullable 6')
            .findAll(),
        [obj4],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEqualTo('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementEqualTo(
              'nullable strings nullable 1',
            )
            .findAll(),
        [obj1],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementEqualTo(
              'nullable strings nullable 3',
            )
            .findAll(),
        [obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementEqualTo(
              'nullable strings nullable 5',
            )
            .findAll(),
        [obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementEqualTo('non existing')
            .findAll(),
        isEmpty,
      );
    });

    isarTest('.elementStartWith()', () {
      expect(
        isar.stringModels.where().stringsElementStartsWith('strings').findAll(),
        [obj1, obj2, obj4, obj5],
      );
      expect(
        isar.stringModels
            .where()
            .stringsElementStartsWith('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsElementStartsWith('nullable')
            .findAll(),
        [obj1, obj2, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementStartsWith('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .stringsNullableElementStartsWith('strings')
            .findAll(),
        [obj1, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEqualTo('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementStartsWith('nullable')
            .findAll(),
        [obj1, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementStartsWith('non existing')
            .findAll(),
        isEmpty,
      );
    });

    isarTest('.elementEndsWith()', () {
      expect(
        isar.stringModels.where().stringsElementEndsWith('1').findAll(),
        [obj1, obj4],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('2').findAll(),
        [obj1, obj2],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('3').findAll(),
        [obj1, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('4').findAll(),
        [obj2, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('5').findAll(),
        [obj4, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('6').findAll(),
        [obj4, obj5],
      );
      expect(
        isar.stringModels.where().stringsElementEndsWith('7').findAll(),
        [obj5],
      );
      expect(
        isar.stringModels
            .where()
            .stringsElementEndsWith('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('1').findAll(),
        [obj1],
      );
      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('2').findAll(),
        [obj2, obj6],
      );
      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('3').findAll(),
        [obj1, obj2, obj5],
      );
      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('4').findAll(),
        [obj4, obj5],
      );
      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('5').findAll(),
        [obj4, obj5, obj6],
      );
      expect(
        isar.stringModels.where().nullableStringsElementEndsWith('6').findAll(),
        [obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementEndsWith('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels.where().stringsNullableElementEndsWith('1').findAll(),
        [obj1, obj5],
      );
      expect(
        isar.stringModels.where().stringsNullableElementEndsWith('4').findAll(),
        [obj4, obj6],
      );
      expect(
        isar.stringModels.where().stringsNullableElementEndsWith('5').findAll(),
        [obj4, obj6],
      );
      expect(
        isar.stringModels.where().stringsNullableElementEndsWith('6').findAll(),
        [obj4],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementEndsWith('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementEndsWith('1')
            .findAll(),
        [obj1],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementEndsWith('3')
            .findAll(),
        [obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementEndsWith('5')
            .findAll(),
        [obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementEndsWith('non existing')
            .findAll(),
        isEmpty,
      );
    });

    isarTest('.elementContains()', () {
      expect(
        isar.stringModels.where().stringsElementContains('ings').findAll(),
        [obj1, obj2, obj4, obj5],
      );
      expect(
        isar.stringModels
            .where()
            .stringsElementContains('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsElementContains('ings')
            .findAll(),
        [obj1, obj2, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementContains('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .stringsNullableElementContains('ings')
            .findAll(),
        [obj1, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementContains('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementContains('ings')
            .findAll(),
        [obj1, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementContains('non existing')
            .findAll(),
        isEmpty,
      );
    });

    isarTest('.elementMatches()', () {
      expect(
        isar.stringModels.where().stringsElementMatches('?????????').findAll(),
        [obj1, obj2, obj4, obj5],
      );
      expect(
        isar.stringModels
            .where()
            .stringsElementMatches('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsElementMatches('??????????????????')
            .findAll(),
        [obj1, obj2, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsElementMatches('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .stringsNullableElementMatches('??????????????????')
            .findAll(),
        [obj1, obj4, obj5, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .stringsNullableElementMatches('non existing')
            .findAll(),
        isEmpty,
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementMatches(
              '???????????????????????????',
            )
            .findAll(),
        [obj1, obj6],
      );
      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementMatches('non existing')
            .findAll(),
        isEmpty,
      );
    });

    isarTest('.elementIsNull()', () {
      expect(
        isar.stringModels.where().nullableStringsElementIsNull().findAll(),
        [obj1, obj5],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementIsNull()
            .findAll(),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.elementIsNotNull()', () {
      expect(
        isar.stringModels.where().nullableStringsElementIsNotNull().findAll(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementIsNotNull()
            .findAll(),
        [obj1, obj6],
      );
    });

    isarTest('.elementGreaterThan()', () {
      expect(
        isar.stringModels
            .where()
            .stringsElementGreaterThan('strings 3')
            .findAll(),
        [obj2, obj4, obj5],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsElementGreaterThan('nullable strings 3')
            .findAll(),
        [obj4, obj5, obj6],
      );

      expect(
        isar.stringModels
            .where()
            .stringsNullableElementGreaterThan('strings nullable 3')
            .findAll(),
        [obj4, obj6],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementGreaterThan(
              'nullable strings nullable 3',
            )
            .findAll(),
        [obj6],
      );
    });

    isarTest('.elementLessThan()', () {
      expect(
        isar.stringModels.where().stringsElementLessThan('strings 3').findAll(),
        [obj1, obj2, obj4, obj6],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsElementLessThan('nullable strings 3')
            .findAll(),
        [obj1, obj2, obj5, obj6],
      );

      expect(
        isar.stringModels
            .where()
            .stringsNullableElementLessThan('strings nullable 3')
            .findAll(),
        [obj1, obj5, obj6],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementLessThan(
              'nullable strings nullable 3',
            )
            .findAll(),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.elementBetween()', () {
      expect(
        isar.stringModels
            .where()
            .stringsElementBetween('strings 2', 'strings 4')
            .findAll(),
        [obj1, obj2, obj5],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsElementBetween(
              'nullable strings 2',
              'nullable strings 4',
            )
            .findAll(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels
            .where()
            .stringsNullableElementBetween(
              'strings nullable 2',
              'strings nullable 4',
            )
            .findAll(),
        [obj4, obj6],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementBetween(
              'nullable strings nullable 2',
              'nullable strings nullable 4',
            )
            .findAll(),
        [obj6],
      );
    });

    isarTest('.elementIsEmpty()', () {
      expect(
        isar.stringModels.where().stringsElementIsEmpty().findAll(),
        [obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsElementIsEmpty().findAll(),
        [obj6],
      );

      expect(
        isar.stringModels.where().stringsNullableElementIsEmpty().findAll(),
        [obj6],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementIsEmpty()
            .findAll(),
        [obj6],
      );
    });

    isarTest('.elementIsNotEmpty()', () {
      expect(
        isar.stringModels.where().stringsElementIsNotEmpty().findAll(),
        [obj1, obj2, obj4, obj5],
      );

      expect(
        isar.stringModels.where().nullableStringsElementIsNotEmpty().findAll(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().stringsNullableElementIsNotEmpty().findAll(),
        [obj1, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels
            .where()
            .nullableStringsNullableElementIsNotEmpty()
            .findAll(),
        [obj1, obj6],
      );
    });

    isarTest('.isEmpty()', () {
      expect(
        isar.stringModels.where().stringsIsEmpty().findAll(),
        [obj3],
      );

      expect(
        isar.stringModels.where().nullableStringsIsEmpty().findAll(),
        [obj3],
      );

      expect(
        isar.stringModels.where().stringsNullableIsEmpty().findAll(),
        [obj3],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableIsEmpty().findAll(),
        [obj3],
      );
    });

    isarTest('.isNotEmpty()', () {
      expect(
        isar.stringModels.where().stringsIsNotEmpty().findAll(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsIsNotEmpty().findAll(),
        [obj1, obj2, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().stringsNullableIsNotEmpty().findAll(),
        [obj1, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableIsNotEmpty().findAll(),
        [obj1, obj4, obj6],
      );
    });

    isarTest('.isNull()', () {
      expect(
        isar.stringModels.where().stringsNullableIsNull().findAll(),
        [obj2],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableIsNull().findAll(),
        [obj2, obj5],
      );
    });

    isarTest('.isNotNull()', () {
      expect(
        isar.stringModels.where().stringsNullableIsNotNull().findAll(),
        [obj1, obj3, obj4, obj5, obj6],
      );

      expect(
        isar.stringModels.where().nullableStringsNullableIsNotNull().findAll(),
        [obj1, obj3, obj4, obj6],
      );
    });
  });
}
