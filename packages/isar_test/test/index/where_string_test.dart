import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'where_string_test.g.dart';

@collection
class StringModel {
  StringModel(this.value) : hash = value;

  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  String? value;

  @Index(type: IndexType.hash)
  String? hash;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is StringModel && value == other.value;

  @override
  String toString() {
    return 'StringModel{id: $id, value: $value}';
  }
}

void main() {
  group('Where String', () {
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
        isar.stringModels.where().valueEqualTo('string 2'),
        [obj2],
      );
      await qEqual(
        isar.stringModels.where().valueEqualTo(null),
        [objNull],
      );
      await qEqual(
        isar.stringModels.where().valueEqualTo('string 6'),
        [],
      );
      await qEqual(
        isar.stringModels.where().valueEqualTo(''),
        [objEmpty],
      );
      await qEqual(
        isar.stringModels.where().valueEqualTo('non existing'),
        [],
      );

      await qEqual(
        isar.stringModels.where().hashEqualTo('string 2'),
        [obj2],
      );
      await qEqual(
        isar.stringModels.where().hashEqualTo(null),
        [objNull],
      );
      await qEqual(
        isar.stringModels.where().hashEqualTo('string 6'),
        [],
      );
      await qEqual(
        isar.stringModels.where().hashEqualTo(''),
        [objEmpty],
      );
      await qEqual(
        isar.stringModels.where().hashEqualTo('non existing'),
        [],
      );
    });

    isarTest('.notEqualTo()', () async {
      await qEqualSet(
        isar.stringModels.where().valueNotEqualTo('string 2'),
        [objEmpty, obj1, obj3, obj4, obj5, obj6, objNull],
      );
      await qEqualSet(
        isar.stringModels.where().valueNotEqualTo(null),
        [objEmpty, obj1, obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.where().valueNotEqualTo('string 6'),
        [objEmpty, obj1, obj2, obj3, obj4, obj5, obj6, objNull],
      );
      await qEqualSet(
        isar.stringModels.where().valueNotEqualTo(''),
        [obj1, obj2, obj3, obj4, obj5, obj6, objNull],
      );
      await qEqualSet(
        isar.stringModels.where().valueNotEqualTo('non existing'),
        [objEmpty, obj1, obj2, obj3, obj4, obj5, obj6, objNull],
      );

      await qEqualSet(
        isar.stringModels.where().hashNotEqualTo('string 2'),
        [objEmpty, obj1, obj3, obj4, obj5, obj6, objNull],
      );
      await qEqualSet(
        isar.stringModels.where().hashNotEqualTo(null),
        [objEmpty, obj1, obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.where().hashNotEqualTo('string 6'),
        [objEmpty, obj1, obj2, obj3, obj4, obj5, obj6, objNull],
      );
      await qEqualSet(
        isar.stringModels.where().hashNotEqualTo(''),
        [obj1, obj2, obj3, obj4, obj5, obj6, objNull],
      );
      await qEqualSet(
        isar.stringModels.where().hashNotEqualTo('non existing'),
        [objEmpty, obj1, obj2, obj3, obj4, obj5, obj6, objNull],
      );
    });

    isarTest('.isNull()', () async {
      await qEqual(
        isar.stringModels.where().valueIsNull(),
        [objNull],
      );

      await qEqual(
        isar.stringModels.where().hashIsNull(),
        [objNull],
      );
    });

    isarTest('.startsWith()', () async {
      await qEqualSet(
        isar.stringModels.where().valueStartsWith('string'),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.stringModels.where().valueStartsWith(''),
        [objEmpty, obj1, obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(isar.stringModels.where().valueStartsWith('S'), {});
    });

    isarTest('.greaterThan()', () async {
      await qEqualSet(
        isar.stringModels.where().valueGreaterThan('string 0'),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().valueGreaterThan('string 1'),
        [obj2, obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().valueGreaterThan('string 2'),
        [obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().valueGreaterThan('string 3'),
        [obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().valueGreaterThan('string 4'),
        [obj5, obj6],
      );

      await qEqualSet(
        isar.stringModels.where().valueGreaterThan('string 5'),
        [],
      );
    });

    isarTest('.lessThan()', () async {
      await qEqualSet(
        isar.stringModels.where().valueLessThan('string 0'),
        [objEmpty, objNull],
      );

      await qEqualSet(
        isar.stringModels.where().valueLessThan('string 1'),
        [objEmpty, objNull],
      );

      await qEqualSet(
        isar.stringModels.where().valueLessThan('string 2'),
        [objEmpty, objNull, obj1],
      );

      await qEqualSet(
        isar.stringModels.where().valueLessThan('string 3'),
        [objEmpty, objNull, obj1, obj2],
      );

      await qEqualSet(
        isar.stringModels.where().valueLessThan('string 4'),
        [objEmpty, objNull, obj1, obj2, obj3],
      );

      await qEqualSet(
        isar.stringModels.where().valueLessThan('string 5'),
        [objEmpty, objNull, obj1, obj2, obj3, obj4],
      );

      await qEqualSet(
        isar.stringModels.where().valueLessThan('string 6'),
        [objEmpty, objNull, obj1, obj2, obj3, obj4, obj5, obj6],
      );
    });

    isarTest('.between()', () async {
      await qEqualSet(
        isar.stringModels.where().valueBetween('string 2', 'string 4'),
        [obj2, obj3, obj4],
      );

      await qEqualSet(
        isar.stringModels.where().valueBetween('', 'string 2'),
        [objEmpty, obj1, obj2],
      );

      await qEqualSet(
        isar.stringModels.where().valueBetween(
              '',
              'string 2',
              includeLower: false,
              includeUpper: false,
            ),
        [obj1],
      );
    });

    isarTest('.isEmpty()', () async {
      await qEqualSet(
        isar.stringModels.where().valueIsEmpty(),
        [objEmpty],
      );
    });

    isarTest('.isNotEmpty()', () async {
      // FIXME: returns every values + 2 times the empty value
      // returns [objNull, objEmpty, objEmpty, obj1, obj2, obj3, obj4, obj5]
      // await qEqualSet(
      //   isar.stringModels.where().valueIsNotEmpty(),
      //   [obj1, obj2, obj3, obj4, obj5, obj6],
      // );
    });
  });
}
