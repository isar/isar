// ignore_for_file: require_trailing_commas

import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'composite_string_test.g.dart';

@Collection()
class Model {
  Model(this.value1, this.value2);

  Id? id;

  @Index(
    composite: [
      CompositeIndex(
        'value2',
        type: IndexType.value,
      )
    ],
    unique: true,
  )
  String? value1;

  String? value2;

  @override
  String toString() {
    return '{id: $id, value1: $value1, value2: $value2}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return (other is Model) &&
        other.id == id &&
        other.value1 == value1 &&
        other.value2 == value2;
  }
}

void main() {
  group('Composite String index', () {
    late Isar isar;
    late IsarCollection<Model> col;

    late Model obj0;
    late Model obj1;
    late Model obj2;
    late Model obj3;
    late Model obj4;
    late Model obj5;
    late Model obj6;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
      col = isar.models;

      obj0 = Model(null, null);
      obj1 = Model('', 'a');
      obj2 = Model('a', null);
      obj3 = Model('a', '');
      obj4 = Model('a', 'a');
      obj5 = Model('a', 'b');
      obj6 = Model('b', '');

      await isar.tWriteTxn(
        () => isar.models.tPutAll([obj5, obj3, obj0, obj1, obj4, obj6, obj2]),
      );
    });

    tearDown(() => isar.close(deleteFromDisk: true));

    isarTest('getBy value1 sorted by value2', () async {
      await qEqual(
        col.where().value1EqualToAnyValue2('a').findAll(),
        [obj2, obj3, obj4, obj5],
      );
      await qEqual(
        col.where().value1EqualToAnyValue2(null).findAll(),
        [obj0],
      );
    });

    group('value1', () {
      isarTest('.equalTo()', () async {
        await qEqual(
          col.where().value1EqualToAnyValue2('a').findAll(),
          [obj2, obj3, obj4, obj5],
        );
        await qEqual(
          col.where().value1EqualToAnyValue2(null).findAll(),
          [obj0],
        );
        await qEqual(
          col.where().value1EqualToAnyValue2('c').findAll(),
          [],
        );
      });

      isarTest('.notEqualTo()', () async {
        await qEqualSet(
          col.where().value1NotEqualToAnyValue2('a').findAll(),
          [obj0, obj1, obj6],
        );
        await qEqualSet(
          col.where().value1NotEqualToAnyValue2('').findAll(),
          [obj0, obj2, obj3, obj4, obj5, obj6],
        );
        await qEqualSet(
          col.where().value1NotEqualToAnyValue2('c').findAll(),
          [obj0, obj1, obj2, obj3, obj4, obj5, obj6],
        );
      });

      isarTest('.isNull()', () async {
        await qEqual(
          col.where().value1IsNullAnyValue2().findAll(),
          [obj0],
        );
      });

      isarTest('.isNotNull()', () async {
        await qEqualSet(
          col.where().value1IsNotNullAnyValue2().findAll(),
          [obj1, obj2, obj3, obj4, obj5, obj6],
        );
      });
    });

    group('value2', () {
      isarTest('.equalTo()', () async {
        await qEqual(
          col.where().value1Value2EqualTo(null, null).findAll(),
          [obj0],
        );
        await qEqual(
          col.where().value1Value2EqualTo('a', null).findAll(),
          [obj2],
        );
        await qEqual(
          col.where().value1Value2EqualTo('c', null).findAll(),
          [],
        );
        await qEqual(
          col.where().value1Value2EqualTo('a', 'c').findAll(),
          [],
        );
      });

      isarTest('.notEqualTo()', () async {
        await qEqual(
          col.where().value1EqualToValue2NotEqualTo('a', null).findAll(),
          [obj3, obj4, obj5],
        );
        await qEqual(
          col.where().value1EqualToValue2NotEqualTo('a', 'c').findAll(),
          [obj2, obj3, obj4, obj5],
        );
        await qEqual(
          col.where().value1EqualToValue2NotEqualTo('b', '').findAll(),
          [],
        );
      });

      isarTest('.isNull()', () async {
        await qEqual(
          col.where().value1EqualToValue2IsNull('a').findAll(),
          [obj2],
        );
        await qEqual(
          col.where().value1EqualToValue2IsNull(null).findAll(),
          [obj0],
        );
        await qEqual(
          col.where().value1EqualToValue2IsNull('').findAll(),
          [],
        );
      });

      isarTest('.isNotNull()', () async {
        await qEqual(
          col.where().value1EqualToValue2IsNotNull('a').findAll(),
          [obj3, obj4, obj5],
        );
        await qEqual(
          col.where().value1EqualToValue2IsNotNull(null).findAll(),
          [],
        );
      });

      isarTest('.greaterThan()', () async {
        await qEqual(
          col.where().value1EqualToValue2GreaterThan('a', '').findAll(),
          [obj4, obj5],
        );
        await qEqual(
          col
              .where()
              .value1EqualToValue2GreaterThan('a', '', include: true)
              .findAll(),
          [obj3, obj4, obj5],
        );
        await qEqual(
          col.where().value1EqualToValue2GreaterThan('a', 'b').findAll(),
          [],
        );
      });

      isarTest('.lessThan()', () async {
        await qEqual(
          col.where().value1EqualToValue2LessThan('a', 'b').findAll(),
          [obj2, obj3, obj4],
        );
        await qEqual(
          col
              .where()
              .value1EqualToValue2LessThan('a', 'b', include: true)
              .findAll(),
          [obj2, obj3, obj4, obj5],
        );
        await qEqual(
          col.where().value1EqualToValue2LessThan('a', null).findAll(),
          [],
        );
      });

      isarTest('.between()', () async {
        await qEqual(
          col.where().value1EqualToValue2Between('a', null, 'b').findAll(),
          [obj2, obj3, obj4, obj5],
        );
        await qEqual(
          col
              .where()
              .value1EqualToValue2Between('a', null, 'b', includeUpper: false)
              .findAll(),
          [obj2, obj3, obj4],
        );
        await qEqual(
          col
              .where()
              .value1EqualToValue2Between('a', null, 'b', includeLower: false)
              .findAll(),
          [obj3, obj4, obj5],
        );
        await qEqual(
          col
              .where()
              .value1EqualToValue2Between('a', null, 'b',
                  includeLower: false, includeUpper: false)
              .findAll(),
          [obj3, obj4],
        );
        await qEqual(
          col
              .where()
              .value1EqualToValue2Between('a', 'a', 'b',
                  includeLower: false, includeUpper: false)
              .findAll(),
          [],
        );
      });

      isarTest('.startsWith()', () async {
        await qEqual(
          col.where().value1EqualToValue2StartsWith('a', '').findAll(),
          [obj3, obj4, obj5],
        );
        await qEqual(
          col.where().value1EqualToValue2StartsWith('a', 'a').findAll(),
          [obj4],
        );
        await qEqual(
          col.where().value1EqualToValue2StartsWith('a', 'c').findAll(),
          [],
        );
      });
    });
  });
}
