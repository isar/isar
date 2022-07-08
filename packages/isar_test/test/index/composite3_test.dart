import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';

part 'composite3_test.g.dart';

@Collection()
class Model {
  Model(this.value1, this.value2, this.value3);
  Id? id;

  @Index(
    composite: [
      CompositeIndex('value2'),
      CompositeIndex('value3'),
    ],
    unique: true,
  )
  int? value1;

  int? value2;

  int? value3;

  @override
  String toString() {
    return '{id: $id, value1: $value1, value2: $value2, value3: $value3}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return (other is Model) &&
        other.id == id &&
        other.value1 == value1 &&
        other.value2 == value2 &&
        other.value3 == value3;
  }
}

void main() {
  group('Composite Index3', () {
    late Isar isar;
    late IsarCollection<Model> col;

    late Model objNull1;
    late Model objNull2;
    late Model objNull3;
    late Model obj1;
    late Model obj2;
    late Model obj3;
    late Model obj4;
    late Model obj5;
    late Model obj6;
    late Model obj7;
    late Model obj8;
    late Model obj9;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
      col = isar.models;

      objNull1 = Model(null, 10, 1);
      objNull2 = Model(10, null, 1);
      objNull3 = Model(10, 1, null);
      obj1 = Model(100, 10, 1);
      obj2 = Model(100, 10, 2);
      obj3 = Model(100, 20, 1);
      obj4 = Model(200, 10, 1);
      obj5 = Model(200, 10, 2);
      obj6 = Model(200, 20, 1);
      obj7 = Model(300, 10, 1);
      obj8 = Model(300, 10, 2);
      obj9 = Model(300, 20, 1);

      await isar.writeTxn(() async {
        await col.putAll(
          [
            obj7, objNull3, obj4, obj1, objNull1, obj9, //
            obj3, obj5, objNull2, obj2, obj8, obj6 //
          ],
        );
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.anyValue1Value2Value3', () async {
      await qEqual(
        isar.models.where().anyValue1Value2Value3().findAll(),
        [
          objNull1, objNull2, objNull3, obj1, obj2, //
          obj3, obj4, obj5, obj6, obj7, obj8, obj9 //
        ],
      );
      await qEqual(
        isar.models.where(sort: Sort.desc).anyValue1Value2Value3().findAll(),
        [
          obj9, obj8, obj7, obj6, obj5, obj4, obj3, //
          obj2, obj1, objNull3, objNull2, objNull1 //
        ],
      );
    });

    group('value1', () {
      isarTest('.equalTo()', () async {
        await qEqual(
          isar.models.where().value1EqualToAnyValue2Value3(null).findAll(),
          [objNull1],
        );
        await qEqual(
          isar.models.where().value1EqualToAnyValue2Value3(200).findAll(),
          [obj4, obj5, obj6],
        );
      });

      isarTest('.notEqualTo()', () async {
        await qEqual(
          isar.models.where().value1NotEqualToAnyValue2Value3(null).findAll(),
          [
            objNull2, objNull3, obj1, obj2, //
            obj3, obj4, obj5, obj6, obj7, obj8, obj9 //
          ],
        );
        await qEqual(
          isar.models.where().value1NotEqualToAnyValue2Value3(200).findAll(),
          [
            objNull1, objNull2, objNull3, obj1, //
            obj2, obj3, obj7, obj8, obj9 //
          ],
        );
        await qEqual(
          isar.models
              .where(sort: Sort.desc)
              .value1NotEqualToAnyValue2Value3(200)
              .findAll(),
          [
            obj9, obj8, obj7, obj3, obj2, //
            obj1, objNull3, objNull2, objNull1, //
          ],
        );
      });

      isarTest('.greaterThan()', () async {
        await qEqual(
          isar.models.where().value1GreaterThanAnyValue2Value3(null).findAll(),
          [
            objNull2, objNull3, obj1, obj2, obj3, //
            obj4, obj5, obj6, obj7, obj8, obj9 //
          ],
        );
        await qEqual(
          isar.models.where().value1GreaterThanAnyValue2Value3(200).findAll(),
          [obj7, obj8, obj9],
        );
        await qEqual(
          isar.models
              .where()
              .value1GreaterThanAnyValue2Value3(200, include: true)
              .findAll(),
          [obj4, obj5, obj6, obj7, obj8, obj9],
        );
      });

      isarTest('.lessThan()', () async {
        await qEqual(
          isar.models.where().value1LessThanAnyValue2Value3(null).findAll(),
          [],
        );
        await qEqual(
          isar.models
              .where()
              .value1LessThanAnyValue2Value3(null, include: true)
              .findAll(),
          [objNull1],
        );
        await qEqual(
          isar.models.where().value1LessThanAnyValue2Value3(10).findAll(),
          [objNull1],
        );
        await qEqual(
          isar.models
              .where()
              .value1LessThanAnyValue2Value3(10, include: true)
              .findAll(),
          [objNull1, objNull2, objNull3],
        );
      });

      isarTest('.between()', () async {
        await qEqual(
          isar.models.where().value1BetweenAnyValue2Value3(null, 100).findAll(),
          [objNull1, objNull2, objNull3, obj1, obj2, obj3],
        );
        await qEqual(
          isar.models
              .where()
              .value1BetweenAnyValue2Value3(null, 100, includeLower: false)
              .findAll(),
          [objNull2, objNull3, obj1, obj2, obj3],
        );
        await qEqual(
          isar.models
              .where()
              .value1BetweenAnyValue2Value3(null, 100, includeUpper: false)
              .findAll(),
          [objNull1, objNull2, objNull3],
        );
        await qEqual(
          isar.models
              .where()
              .value1BetweenAnyValue2Value3(
                null,
                100,
                includeLower: false,
                includeUpper: false,
              )
              .findAll(),
          [objNull2, objNull3],
        );
      });

      isarTest('.isNull()', () async {
        await qEqual(
          isar.models.where().value1IsNullAnyValue2Value3().findAll(),
          [objNull1],
        );
      });

      isarTest('.isNotNull()', () async {
        await qEqual(
          isar.models.where().value1IsNotNullAnyValue2Value3().findAll(),
          [
            objNull2, objNull3, obj1, obj2, //
            obj3, obj4, obj5, obj6, obj7, obj8, obj9 //
          ],
        );
      });
    });

    group('value2', () {
      isarTest('.equalTo()', () async {
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToAnyValue3(null, null)
              .findAll(),
          [],
        );
        await qEqual(
          isar.models.where().value1Value2EqualToAnyValue3(100, 10).findAll(),
          [obj1, obj2],
        );
      });

      isarTest('.notEqualTo()', () async {
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2NotEqualToAnyValue3(200, 100)
              .findAll(),
          [obj4, obj5, obj6],
        );
        await qEqual(
          isar.models
              .where(sort: Sort.desc)
              .value1EqualToValue2NotEqualToAnyValue3(200, 100)
              .findAll(),
          [obj6, obj5, obj4],
        );
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2NotEqualToAnyValue3(200, 20)
              .findAll(),
          [obj4, obj5],
        );
      });

      isarTest('.greaterThan()', () async {
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2GreaterThanAnyValue3(100, null)
              .findAll(),
          [obj1, obj2, obj3],
        );
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2GreaterThanAnyValue3(100, 10)
              .findAll(),
          [obj3],
        );
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2GreaterThanAnyValue3(100, 10, include: true)
              .findAll(),
          [obj1, obj2, obj3],
        );
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2GreaterThanAnyValue3(100, 20)
              .findAll(),
          [],
        );
      });

      isarTest('.lessThan()', () async {
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2LessThanAnyValue3(300, 100)
              .findAll(),
          [obj7, obj8, obj9],
        );
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2LessThanAnyValue3(300, 10)
              .findAll(),
          [],
        );
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2LessThanAnyValue3(300, 10, include: true)
              .findAll(),
          [obj7, obj8],
        );
      });

      isarTest('.between()', () async {
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2BetweenAnyValue3(200, null, 100)
              .findAll(),
          [obj4, obj5, obj6],
        );
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2BetweenAnyValue3(200, 10, 20)
              .findAll(),
          [obj4, obj5, obj6],
        );
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2BetweenAnyValue3(
                200,
                10,
                20,
                includeLower: false,
              )
              .findAll(),
          [obj6],
        );
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2BetweenAnyValue3(
                200,
                10,
                20,
                includeUpper: false,
              )
              .findAll(),
          [obj4, obj5],
        );
      });

      isarTest('.isNull()', () async {
        await qEqual(
          isar.models.where().value1EqualToValue2IsNullAnyValue3(10).findAll(),
          [objNull2],
        );
      });

      isarTest('.isNotNull()', () async {
        await qEqual(
          isar.models
              .where()
              .value1EqualToValue2IsNotNullAnyValue3(10)
              .findAll(),
          [objNull3],
        );
      });
    });

    group('value3', () {
      isarTest('.equalTo()', () async {
        await qEqual(
          isar.models
              .where()
              .value1Value2Value3EqualTo(null, null, null)
              .findAll(),
          [],
        );
        await qEqual(
          isar.models.where().value1Value2Value3EqualTo(100, 10, 1).findAll(),
          [obj1],
        );
      });

      isarTest('.notEqualTo()', () async {
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3NotEqualTo(200, 10, 5)
              .findAll(),
          [obj4, obj5],
        );
        await qEqual(
          isar.models
              .where(sort: Sort.desc)
              .value1Value2EqualToValue3NotEqualTo(200, 10, 5)
              .findAll(),
          [obj5, obj4],
        );
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3NotEqualTo(200, 10, 1)
              .findAll(),
          [obj5],
        );
      });

      isarTest('.greaterThan()', () async {
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3GreaterThan(300, 10, null)
              .findAll(),
          [obj7, obj8],
        );
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3GreaterThan(300, 10, 2)
              .findAll(),
          [],
        );
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3GreaterThan(300, 10, 2, include: true)
              .findAll(),
          [obj8],
        );
      });

      isarTest('.lessThan()', () async {
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3LessThan(300, 10, 5)
              .findAll(),
          [obj7, obj8],
        );
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3LessThan(300, 10, 1)
              .findAll(),
          [],
        );
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3LessThan(300, 10, 1, include: true)
              .findAll(),
          [obj7],
        );
      });

      isarTest('.between()', () async {
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3Between(200, 10, null, 5)
              .findAll(),
          [obj4, obj5],
        );
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3Between(
                200,
                10,
                1,
                2,
                includeLower: false,
              )
              .findAll(),
          [obj5],
        );
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3Between(
                200,
                10,
                1,
                2,
                includeUpper: false,
              )
              .findAll(),
          [obj4],
        );
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3Between(
                200,
                10,
                1,
                2,
                includeLower: false,
                includeUpper: false,
              )
              .findAll(),
          [],
        );
      });

      isarTest('.isNull()', () async {
        await qEqual(
          isar.models.where().value1Value2EqualToValue3IsNull(10, 1).findAll(),
          [objNull3],
        );
      });

      isarTest('.isNotNull()', () async {
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3IsNotNull(10, 1)
              .findAll(),
          [],
        );
        await qEqual(
          isar.models
              .where()
              .value1Value2EqualToValue3IsNotNull(100, 10)
              .findAll(),
          [obj1, obj2],
        );
      });
    });
  });
}
