import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'composite_string_test.g.dart';

@Collection()
class Model {
  Model(this.value1, this.value2);

  int? id;

  @Index(
    composite: [
      CompositeIndex(
        'value2',
        type: IndexType.value,
      )
    ],
    unique: true,
  )
  String value1;

  String value2;

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
  group('Composite String', () {
    late Isar isar;
    late Model obj0;
    late Model obj1;
    late Model obj2;
    late Model obj3;
    late Model obj4;
    late Model obj5;
    late Model obj6;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

      obj0 = Model('Foo', 'Bar');
      obj1 = Model('Bar', 'Foo');
      obj2 = Model('', 'Bar');
      obj3 = Model('aoeu', 'asdf');
      obj4 = Model('Foo', 'Not bar');
      obj5 = Model('John', 'Doe');
      obj6 = Model('Jane', 'Doe');

      await isar.tWriteTxn(
        () => isar.models.tPutAll([obj0, obj1, obj2, obj3, obj4, obj5, obj6]),
      );
    });

    isarTest('Query by value1 and value2', () async {
      await qEqual(
        isar.models.where().value1Value2EqualTo('Foo', 'Bar').tFindAll(),
        [obj0],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2NotEqualTo('Foo', 'Bar')
            .tFindAll(),
        [obj4],
      );

      await qEqual(
        isar.models.where().value1EqualToValue2StartsWith('', 'B').tFindAll(),
        [obj2],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2Between('Foo', 'B', 'N')
            .tFindAll(),
        [obj0],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2Between('Foo', 'B', 'O')
            .tFindAll(),
        [obj0, obj4],
      );
    });

    // FIXME: Test currently does not pass.
    isarTest('Sorted by value1 value2', () async {
      await qEqual(
        isar.models.where().sortByValue1().thenByValue2().tFindAll(),
        [obj2, obj1, obj0, obj4, obj6, obj5, obj3],
      );

      // FIXME: when there is an empty string (obj2), using `anyValue1Value2()`
      // to sort values breaks, and for some reasons puts obj in order of
      // [obj6, obj2, obj3, obj1, obj0, obj4, obj5]. The first 3 are wrong.
      // The value before and after (coincidence?) the empty string are at the
      // wrong place.
      // Replacing the empty string with text fixes the issue.
      await qEqual(
        isar.models.where().anyValue1Value2().tFindAll(),
        [obj2, obj1, obj0, obj4, obj6, obj5, obj3],
      );
    });

    isarTest('Get by value1 sorted by value2', () async {
      await qEqual(
        isar.models.where().value1EqualToAnyValue2('Foo').tFindAll(),
        [obj0, obj4],
      );

      // FIXME: Weird value order
      // Seems to be sorted according to value1 and encountering empty string
      // sort bug
      await qEqual(
        isar.models.where().value1NotEqualToAnyValue2('Foo').tFindAll(),
        [obj2, obj5, obj6, obj1, obj3],
      );
    });

    isarTest('Distinct by value1', () async {
      await qEqual(
        isar.models.where().distinctByValue1().tFindAll(),
        [obj0, obj1, obj2, obj3, obj5, obj6],
      );
    });

    isarTest('Distinct by value2', () async {
      await qEqual(
        isar.models.where().distinctByValue2().tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });
  });
}
