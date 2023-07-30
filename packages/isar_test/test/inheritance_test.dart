import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'inheritance_test.g.dart';

abstract class BaseModel {
  BaseModel({
    required this.identifier,
    required this.name,
    required this.nickname,
  });

  @id
  int identifier;

  @Index()
  int get nameHash => name.hashCode;

  final String name;

  final String nickname;

  // ignore:unused_field
  final float _privateProperty = 0;

  @Ignore()
  final short ignoredProperty = 42;
}

@collection
class InheritingModel extends BaseModel {
  InheritingModel({
    required super.identifier,
    required super.name,
    required super.nickname,
    required this.age,
  });

  final int age;

  @override
  String toString() {
    return 'InheritingModel{name: $name, nameHash: $nameHash, nickname: '
        '$nickname, age: $age}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InheritingModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          nameHash == other.nameHash &&
          nickname == other.nickname &&
          age == other.age;
}

@Collection(inheritance: false)
class NonInheritingModel extends BaseModel {
  NonInheritingModel({
    required this.id,
    required this.age,
    required this.nickname,
  }) : super(identifier: 0, name: '', nickname: nickname);

  final int id;

  final int age;

  @override
  // ignore:overridden_fields
  final String nickname;

  @override
  String toString() {
    return 'NonInheritingModel{id: $id, age: $age, nickname: $nickname}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NonInheritingModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          age == other.age &&
          nickname == other.nickname;
}

void main() {
  group('Inheritance', () {
    late Isar isar;

    late InheritingModel inheritingObj0;
    late InheritingModel inheritingObj1;
    late InheritingModel inheritingObj2;
    late InheritingModel inheritingObj3;
    late InheritingModel inheritingObj4;
    late InheritingModel inheritingObj5;

    late NonInheritingModel nonInheritingObj0;
    late NonInheritingModel nonInheritingObj1;
    late NonInheritingModel nonInheritingObj2;

    setUp(() async {
      isar = await openTempIsar([
        InheritingModelSchema,
        NonInheritingModelSchema,
      ]);

      inheritingObj0 = InheritingModel(
        identifier: 0,
        name: 'inheriting obj0',
        nickname: 'obj0',
        age: 42,
      );
      inheritingObj1 = InheritingModel(
        identifier: 1,
        name: 'inheriting obj1',
        nickname: 'obj1',
        age: 2,
      );
      inheritingObj2 = InheritingModel(
        identifier: 2,
        name: 'inheriting obj2',
        nickname: 'obj2',
        age: 22,
      );
      inheritingObj3 = InheritingModel(
        identifier: 3,
        name: 'inheriting obj3',
        nickname: 'obj3',
        age: 54,
      );
      inheritingObj4 = InheritingModel(
        identifier: 4,
        name: 'inheriting obj4',
        nickname: 'obj4',
        age: 24,
      );
      inheritingObj5 = InheritingModel(
        identifier: 5,
        name: 'inheriting obj5',
        nickname: 'obj5',
        age: 31,
      );

      nonInheritingObj0 =
          NonInheritingModel(id: 0, age: 22, nickname: 'non-obj0');
      nonInheritingObj1 =
          NonInheritingModel(id: 1, age: 56, nickname: 'non-obj1');
      nonInheritingObj2 =
          NonInheritingModel(id: 2, age: 65, nickname: 'non-obj2');

      isar.write((isar) {
        isar.inheritingModels.putAll([
          inheritingObj0,
          inheritingObj1,
          inheritingObj2,
          inheritingObj3,
          inheritingObj4,
          inheritingObj5,
        ]);
        isar.nonInheritingModels.putAll([
          nonInheritingObj0,
          nonInheritingObj1,
          nonInheritingObj2,
        ]);
      });
    });

    /*test('Validate inheritance model properties', () {
      expect(InheritingModelSchema.idName, 'identifier');
      expect(InheritingModelSchema.propertyIds.containsKey('nameHash'), true);
      expect(InheritingModelSchema.propertyIds.containsKey('name'), true);
      expect(InheritingModelSchema.propertyIds.containsKey('nickname'), true);
      expect(InheritingModelSchema.propertyIds.containsKey('age'), true);
      expect(
        InheritingModelSchema.propertyIds.containsKey('_privateProperty'),
        false,
      );
      expect(
        InheritingModelSchema.propertyIds.containsKey('ignoredProperty'),
        false,
      );
      expect(InheritingModelSchema.linkIds.containsKey('link'), true);
      expect(InheritingModelSchema.indexIds.containsKey('nameHash'), true);
    });

    test('Validation non inheritance model properties', () {
      expect(NonInheritingModelSchema.idName, 'id');
      expect(
        NonInheritingModelSchema.propertyIds.containsKey('nameHash'),
        false,
      );
      expect(NonInheritingModelSchema.propertyIds.containsKey('name'), false);
      expect(
        NonInheritingModelSchema.propertyIds.containsKey('nickname'),
        true,
      );
      expect(NonInheritingModelSchema.propertyIds.containsKey('age'), true);
      expect(
        NonInheritingModelSchema.propertyIds.containsKey('_privateProperty'),
        false,
      );
      expect(
        NonInheritingModelSchema.propertyIds.containsKey('ignoredProperty'),
        false,
      );
      expect(NonInheritingModelSchema.linkIds.containsKey('link'), false);
      expect(NonInheritingModelSchema.indexIds.containsKey('nameHash'), false);
    });*/

    isarTest('Query model with inheritance', () {
      expect(
        isar.inheritingModels
            .where()
            .nameContains('1')
            .or()
            .nameContains('4')
            .findAll(),
        [inheritingObj1, inheritingObj4],
      );

      expect(
        isar.inheritingModels
            .where()
            .nicknameContains('3')
            .or()
            .nicknameContains('0')
            .findAll(),
        [inheritingObj0, inheritingObj3],
      );

      expect(
        isar.inheritingModels.where().ageLessThan(40).findAll(),
        [inheritingObj1, inheritingObj2, inheritingObj4, inheritingObj5],
      );
    });

    /*isarTest('Query model with inherited index', () {
      expect(
        isar.inheritingModels
            .where()
            .nameHashEqualTo(inheritingObj1.name.hashCode)
            .or()
            .nameHashEqualTo(inheritingObj0.name.hashCode)
            .findAll(),
        [inheritingObj0, inheritingObj1],
      );

      expect(
        isar.inheritingModels
            .where()
            .not()
            .nameHashEqualTo(inheritingObj1.nameHash)
            .nameHashProperty()
            .findAll(),
        [
          inheritingObj0.nameHash,
          inheritingObj2.nameHash,
          inheritingObj3.nameHash,
          inheritingObj4.nameHash,
          inheritingObj5.nameHash,
        ],
      );

      expect(
        isar.inheritingModels.where().findAll(),
        [
          inheritingObj0,
          inheritingObj1,
          inheritingObj2,
          inheritingObj3,
          inheritingObj4,
          inheritingObj5,
        ],
      );
    });

    isarTest('Query model without inheritance', () {
      expect(
        isar.nonInheritingModels.where().ageBetween(30, 60).findAll(),
        [nonInheritingObj1],
      );

      expect(
        isar.nonInheritingModels
            .where()
            .nicknameContains('obj1')
            .or()
            .nicknameContains('obj0')
            .findAll(),
        [nonInheritingObj0, nonInheritingObj1],
      );

      expect(
        isar.nonInheritingModels.where().idGreaterThan(1).findAll(),
        [nonInheritingObj1, nonInheritingObj2],
      );
    });*/
  });
}
