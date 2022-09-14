import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_string_test.g.dart';

@collection
class StringModel {
  StringModel(this.field);

  Id id = Isar.autoIncrement;

  String? field;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is StringModel && field == other.field;

  @override
  String toString() {
    return 'StringModel{id: $id, field: $field}';
  }
}

void main() {
  group('String filter', () {
    late Isar isar;

    late StringModel objEmpty;
    late StringModel obj1;
    late StringModel obj2;
    late StringModel obj3;
    late StringModel obj4;
    late StringModel obj5;
    late StringModel obj6;
    late StringModel objNull;

    setUp(() async {
      isar = await openTempIsar([StringModelSchema]);

      objEmpty = StringModel('');
      obj1 = StringModel('string 1');
      obj2 = StringModel('string 2');
      obj3 = StringModel('string 3');
      obj4 = StringModel('string 4');
      obj5 = StringModel('string 5');
      obj6 = StringModel('string 5');
      objNull = StringModel(null);

      await isar.writeTxn(
        () async => isar.stringModels.tPutAll([
          objEmpty,
          obj1,
          obj2,
          obj3,
          obj4,
          obj5,
          obj6,
          objNull,
        ]),
      );
    });

    isarTest('.equalTo()', () async {
      await qEqual(
        isar.stringModels.filter().fieldEqualTo('string 2'),
        [obj2],
      );
      await qEqual(
        isar.stringModels.filter().fieldEqualTo(null),
        [objNull],
      );
      await qEqual(
        isar.stringModels.filter().fieldEqualTo('string 6'),
        [],
      );
      await qEqual(
        isar.stringModels.filter().fieldEqualTo(''),
        [objEmpty],
      );
    });

    isarTest('.isNull()', () async {
      await qEqual(
        isar.stringModels.filter().fieldIsNull(),
        [objNull],
      );
    });

    isarTest('.startsWith()', () async {
      await qEqualSet(
        isar.stringModels.filter().fieldStartsWith('string'),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().fieldStartsWith(''),
        [objEmpty, obj1, obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(isar.stringModels.filter().fieldStartsWith('S'), {});
    });

    isarTest('.endsWith()', () async {
      await qEqualSet(
        isar.stringModels.filter().fieldEndsWith('5'),
        [obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().fieldEndsWith(''),
        [objEmpty, obj1, obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(isar.stringModels.filter().fieldEndsWith('8'), []);
    });

    isarTest('.contains()', () async {
      await qEqualSet(
        isar.stringModels.filter().fieldContains('ing'),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().fieldContains(''),
        [objEmpty, obj1, obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().fieldContains('x'),
        [],
      );
    });

    isarTest('.greaterThan()', () async {
      await qEqualSet(
        isar.stringModels.filter().fieldGreaterThan('string 0'),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldGreaterThan('string 1'),
        [obj2, obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldGreaterThan('string 2'),
        [obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldGreaterThan('string 3'),
        [obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldGreaterThan('string 4'),
        [obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldGreaterThan('string 5'),
        [],
      );
    });

    isarTest('.lessThan()', () async {
      /* FIXME: lessThan not working
      await qEqualSet(
        isar.stringModels.filter().fieldLessThan('string 0'),
        [objEmpty, objNull],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldLessThan('string 1'),
        [objEmpty, objNull],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldLessThan('string 2'),
        [objEmpty, objNull, obj1],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldLessThan('string 3'),
        [objEmpty, objNull, obj1, obj2],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldLessThan('string 4'),
        [objEmpty, objNull, obj1, obj2, obj3],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldLessThan('string 5'),
        [objEmpty, objNull, obj1, obj2, obj3, obj4],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldLessThan('string 6'),
        [objEmpty, objNull, obj1, obj2, obj3, obj4, obj5, obj6],
      );
      */
    });

    isarTest('.between()', () async {
      await qEqualSet(
        isar.stringModels.filter().fieldBetween('string 2', 'string 4'),
        [obj2, obj3, obj4],
      );

      await qEqualSet(
        isar.stringModels.filter().fieldBetween('', 'string 2'),
        [objEmpty, obj1, obj2],
      );

      /* FIXME: Something seems to be wrong when
          between has `includeLower: false`
      await qEqualSet(
        isar.stringModels.filter().fieldBetween(
              '',
              'string 2',
              includeLower: false,
              includeUpper: false,
            ),
        [obj1],
      );
      */
    });

    isarTestVm('.matches() VM', () async {
      await qEqualSet(
        isar.stringModels.filter().fieldMatches('*ng 5'),
        [obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.filter().fieldMatches('????????'),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(isar.stringModels.filter().fieldMatches(''), [objEmpty]);

      await qEqualSet(isar.stringModels.filter().fieldMatches('*4?'), []);
    });

    isarTestWeb('.matches() WEB', () async {
      expect(
        await isar.stringModels.filter().fieldMatches('*ng 5').tFindAll(),
        anyOf(throwsUnimplementedError, throwsUnsupportedError),
      );
    });

    isarTest('.isEmpty()', () async {
      await qEqualSet(
        isar.stringModels.filter().fieldIsEmpty(),
        [objEmpty],
      );
    });

    isarTest('.isNotEmpty()', () async {
      await qEqualSet(
        isar.stringModels.filter().fieldIsNotEmpty(),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );
    });
  });
}
