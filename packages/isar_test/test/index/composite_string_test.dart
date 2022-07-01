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
  group('Composite String index', () {
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

    isarTest('Query value1 equalTo and value2 equalTo', () async {
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

    isarTest('Query value1 equalTo and value notEqualTo', () async {
      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2NotEqualTo('Foo', 'Not bar')
            .tFindAll(),
        [obj0],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2NotEqualTo('unknown', 'value')
            .tFindAll(),
        [],
      );
    });

    isarTest('Query value1 equalTo and value2 startsWith', () async {
      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2StartsWith('John', 'D')
            .tFindAll(),
        [obj5],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2StartsWith('John', 'd')
            .tFindAll(),
        [],
      );

      await qEqual(
        isar.models.where().value1EqualToValue2StartsWith('Foo', '').tFindAll(),
        [obj0, obj4],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2StartsWith('Foo', 'Bar')
            .tFindAll(),
        [obj0],
      );
    });

    isarTest('Query value1 equalTo and value2 greaterThan', () async {
      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2GreaterThan('Foo', 'Bar')
            .tFindAll(),
        [obj4],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2GreaterThan('Foo', 'B')
            .tFindAll(),
        [obj0, obj4],
      );
    });

    isarTest('Query value1 equalTo and value2 notEqualTo', () async {
      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2NotEqualTo('Bar', 'Bar')
            .tFindAll(),
        [obj1],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2NotEqualTo('Foo', 'Bar')
            .tFindAll(),
        [obj4],
      );
    });

    isarTest('Query value1 equalTo and value2 lessThan', () async {
      await qEqual(
        isar.models.where().value1EqualToValue2LessThan('', 'D').tFindAll(),
        [obj2],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2LessThan('Foo', 'bar')
            .tFindAll(),
        [obj0, obj4],
      );
    });

    isarTest('Query value1 equalTo and value2 between', () async {
      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2Between(
              'Foo',
              'AAAAAAaAAaaAAaAAaAAaaA',
              'zZZzzZZzzZzzZZzzZzzZZzZZzzzz',
            )
            .tFindAll(),
        [obj0, obj4],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2Between('John', 'Z', 'A')
            .tFindAll(),
        [],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2Between('John', 'A', 'Z')
            .tFindAll(),
        [obj5],
      );
    });

    isarTest('anyOf value1 equalTo and any value2', () async {
      await qEqual(
        isar.models.where().anyOf<String, Model>(
          ['Foo', 'John'],
          (q, element) => q.value1EqualToAnyValue2(element),
        ).tFindAll(),
        [obj0, obj4, obj5],
      );
    });

    isarTest('Multiple where queries', () async {
      await qEqual(
        isar.models
            .where()
            .value1EqualToAnyValue2('aoeu')
            .or()
            .value1EqualToAnyValue2('Bar')
            .or()
            .value1EqualToValue2GreaterThan('Foo', 'Isar')
            .tFindAll(),
        [obj3, obj1, obj4],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToAnyValue2('aoeu')
            .or()
            .value1EqualToValue2StartsWith('Foo', 'Not')
            .tFindAll(),
        [obj3, obj4],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2StartsWith('aoeu', 'A')
            .or()
            .value1EqualToValue2StartsWith('Foo', 'Ba')
            .or()
            .value1EqualToValue2StartsWith('Foo', 'Not ')
            .tFindAll(),
        [obj0, obj4],
      );

      await qEqual(
        isar.models
            .where()
            .value1EqualToValue2GreaterThan('Foo', 'A')
            .or()
            .value1EqualToValue2LessThan('Jane', 'dOE')
            .or()
            .value1EqualToValue2NotEqualTo('', '')
            .tFindAll(),
        [obj0, obj4, obj6, obj2],
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
